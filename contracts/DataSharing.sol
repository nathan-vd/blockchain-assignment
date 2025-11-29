// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./IdentityManager.sol";
import "./ConsentManager.sol";
import "./AuditLog.sol";
import "./AccessToken.sol";

/// @title DataSharing
/// @notice Coordinates identity registration, consent lifecycle, and audit logging
contract DataSharing {
    struct AccessRequest {
        address requester;
        address user;
        ConsentManager.DataType[] attributes;
        uint256 createdAt;
        bool active;
    }

    IdentityManager public identityManager;
    ConsentManager public consentManager;
    AuditLog public auditLog;
    AccessToken public accessToken;

    address public owner;
    uint256 public nextRequestId;
    uint256 public constant CONSENT_REWARD = 10 * 10**18;

    mapping(uint256 => AccessRequest) private accessRequests;

    event AccessRequested(
        uint256 indexed requestId,
        address indexed requester,
        address indexed user,
        ConsentManager.DataType[] attributes
    );
    event ConsentIssued(
        uint256 indexed requestId,
        uint256 indexed consentId,
        address indexed user,
        address requester
    );
    event ConsentRevoked(uint256 indexed consentId, address indexed user, address indexed requester);
    event AccessAttempt(
        uint256 indexed consentId,
        address indexed requester,
        address indexed user,
        ConsentManager.DataType attribute,
        bool success
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not platform owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        identityManager = new IdentityManager(address(this));
        consentManager = new ConsentManager(address(identityManager), address(this));
        auditLog = new AuditLog(address(this));
        accessToken = new AccessToken(address(this));
    }

    /// @notice Register a new identity on-chain
    function registerUser(bytes32 hashedUUID) external {
        identityManager.register(msg.sender, hashedUUID);
        auditLog.logUserRegistered(msg.sender, hashedUUID);
    }

    /// @notice Authorize or revoke a trusted data submitter
    function setDataSubmitter(address submitter, bool authorized) external onlyOwner {
        identityManager.setDataSubmitter(submitter, authorized);
    }

    /// @notice Submit verified credit data (data submitter only)
    function submitCreditVerification(
        address user,
        uint256 creditScore,
        bytes calldata signature
    ) external {
        require(identityManager.authorizedSubmitters(msg.sender), "Not data submitter");
        identityManager.updateCreditData(user, creditScore, signature, msg.sender);
        auditLog.logCreditVerified(user, msg.sender, creditScore);
    }

    /// @notice Create an access request for user attributes
    function requestAccess(
        address user,
        ConsentManager.DataType[] calldata attributes
    ) external returns (uint256) {
        require(identityManager.isRegistered(msg.sender), "Requester not registered");
        require(identityManager.isRegistered(user), "User not registered");
        require(attributes.length > 0, "Attributes required");

        uint256 requestId = nextRequestId++;
        AccessRequest storage request = accessRequests[requestId];
        request.requester = msg.sender;
        request.user = user;
        request.createdAt = block.timestamp;
        request.active = true;

        for (uint256 i = 0; i < attributes.length; i++) {
            request.attributes.push(attributes[i]);
        }

        emit AccessRequested(requestId, msg.sender, user, attributes);
        return requestId;
    }

    /// @notice Grant consent for a pending access request
    function grantConsent(uint256 requestId, uint256 durationDays) external returns (uint256) {
        AccessRequest storage request = accessRequests[requestId];
        require(request.active, "Request inactive");
        require(request.user == msg.sender, "Not request owner");

        ConsentManager.DataType[] memory attrs = _copyAttributes(request.attributes);
        uint256 consentId = consentManager.grantConsentFor(msg.sender, request.requester, attrs, durationDays);
        request.active = false;

        auditLog.logConsent(consentId, msg.sender, request.requester, attrs, "GRANTED");

        accessToken.mint(msg.sender, CONSENT_REWARD);
        auditLog.logTokenReward(msg.sender, CONSENT_REWARD);

        emit ConsentIssued(requestId, consentId, msg.sender, request.requester);
        return consentId;
    }

    /// @notice Revoke an existing consent
    function revokeConsent(uint256 consentId) external {
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        require(consent.owner == msg.sender, "Not consent owner");

        consentManager.revokeConsent(consentId);

        auditLog.logConsent(consentId, consent.owner, consent.requester, consent.attributes, "REVOKED");

        emit ConsentRevoked(consentId, consent.owner, consent.requester);
    }

    /// @notice Check if requester currently has permission to view an attribute
    function hasConsent(
        address user,
        address requester,
        ConsentManager.DataType attribute
    ) external view returns (bool) {
        return consentManager.hasValidConsent(user, requester, attribute);
    }

    /// @notice Validate consent and emit audit events around a data access attempt
    function accessData(uint256 consentId, ConsentManager.DataType attribute) external returns (bool) {
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        if (consent.requester != msg.sender) {
            _logAccess(consentId, consent.owner, attribute, false, "REQUESTER_MISMATCH");
            return false;
        }

        if (!consentManager.isConsentValid(consentId)) {
            _logAccess(consentId, consent.owner, attribute, false, "CONSENT_INACTIVE");
            return false;
        }

        if (!consentManager.coversAttribute(consentId, attribute)) {
            _logAccess(consentId, consent.owner, attribute, false, "ATTRIBUTE_NOT_ALLOWED");
            return false;
        }

        _logAccess(consentId, consent.owner, attribute, true, "ACCESS_GRANTED");
        return true;
    }

    /// @notice View minimal request information
    function getRequest(uint256 requestId)
        external
        view
        returns (
            address requester,
            address user,
            ConsentManager.DataType[] memory attributes,
            uint256 createdAt,
            bool active
        )
    {
        AccessRequest storage request = accessRequests[requestId];
        return (
            request.requester,
            request.user,
            _copyAttributes(request.attributes),
            request.createdAt,
            request.active
        );
    }

    /// @notice Transfer platform ownership
    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner required");
        owner = newOwner;
    }

    function _logAccess(
        uint256 consentId,
        address user,
        ConsentManager.DataType attribute,
        bool success,
        string memory detail
    ) internal {
        auditLog.logAccess(
            consentId,
            msg.sender,
            user,
            attribute,
            success,
            detail
        );
        emit AccessAttempt(consentId, msg.sender, user, attribute, success);
    }

    function _copyAttributes(ConsentManager.DataType[] storage attrs)
        internal
        view
        returns (ConsentManager.DataType[] memory)
    {
        ConsentManager.DataType[] memory copy = new ConsentManager.DataType[](attrs.length);
        for (uint256 i = 0; i < attrs.length; i++) {
            copy[i] = attrs[i];
        }
        return copy;
    }
}
