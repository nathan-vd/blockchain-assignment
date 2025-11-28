// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title ConsentManager
/// @notice Stores: Consent agreements, Expiration times, Authorized attributes
contract ConsentManager {
    enum Status {
        None,
        Active,
        Revoked,
        Expired
    }

    // Data types that can be shared
    enum DataType {
        UUID,
        Name,
        Email,
        CreditScore
    }

    struct Consent {
        address owner;
        address requester;
        DataType[] attributes;
        uint256 issuedAt;
        uint256 expiresAt;
        Status status;
    }

    // Consent ID counter
    uint256 public consentCounter;
    
    // Mapping from consent ID to consent details
    mapping(uint256 => Consent) public consents;
    
    // Mapping from user => requester => consent IDs
    mapping(address => mapping(address => uint256[])) public userRequesterConsents;
    
    // Mapping from user => all consent IDs granted by user
    mapping(address => uint256[]) public userConsents;
    
    // Mapping from requester => all consent IDs granted to requester
    mapping(address => uint256[]) public requesterConsents;

    // Reference to IdentityManager contract
    address public identityContract;

    event ConsentGranted(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester,
        DataType[] attributes,
        uint256 expiresAt
    );
    
    event ConsentRevoked(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester
    );
    
    event ConsentExpired(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester
    );
    
    event AccessRequested(
        address indexed requester,
        address indexed user,
        DataType[] attributes,
        uint256 timestamp
    );

    error InvalidDuration();
    error NotOwner();
    error ConsentNotActive();
    error ConsentNotFound();
    error InvalidAttributes();
    error UserNotRegistered();
    error RequesterNotRegistered();

    modifier onlyConsentOwner(uint256 consentId) {
        if (consents[consentId].owner != msg.sender) revert NotOwner();
        _;
    }

    constructor(address _identityContract) {
        identityContract = _identityContract;
    }

    /// @notice Request access to user data
    /// @param user User whose data is being requested
    /// @param attributes Array of data types being requested
    function requestAccess(
        address user,
        DataType[] calldata attributes
    ) external {
        // Validate attributes
        if (attributes.length == 0) revert InvalidAttributes();
        
        // Check both parties are registered
        (bool success, bytes memory data) = identityContract.staticcall(
            abi.encodeWithSignature("isRegistered(address)", msg.sender)
        );
        if (!success || !abi.decode(data, (bool))) revert RequesterNotRegistered();
        
        (success, data) = identityContract.staticcall(
            abi.encodeWithSignature("isRegistered(address)", user)
        );
        if (!success || !abi.decode(data, (bool))) revert UserNotRegistered();

        emit AccessRequested(msg.sender, user, attributes, block.timestamp);
    }

    /// @notice Grant consent to a requester for specific attributes
    /// @param requester Address requesting access
    /// @param attributes Array of data types being granted access to
    /// @param durationDays Duration in days (1-365)
    /// @return consentId The ID of the created consent
    function grantConsent(
        address requester,
        DataType[] calldata attributes,
        uint256 durationDays
    ) external returns (uint256) {
        // Validate duration (1-365 days)
        if (durationDays < 1 || durationDays > 365) revert InvalidDuration();
        
        // Validate attributes
        if (attributes.length == 0) revert InvalidAttributes();
        
        // Check both parties are registered
        (bool success, bytes memory data) = identityContract.staticcall(
            abi.encodeWithSignature("isRegistered(address)", msg.sender)
        );
        if (!success || !abi.decode(data, (bool))) revert UserNotRegistered();
        
        (success, data) = identityContract.staticcall(
            abi.encodeWithSignature("isRegistered(address)", requester)
        );
        if (!success || !abi.decode(data, (bool))) revert RequesterNotRegistered();

        // Create new consent
        uint256 consentId = consentCounter++;
        uint256 expiresAt = block.timestamp + (durationDays * 1 days);

        consents[consentId] = Consent({
            owner: msg.sender,
            requester: requester,
            attributes: attributes,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            status: Status.Active
        });

        // Track consent relationships
        userRequesterConsents[msg.sender][requester].push(consentId);
        userConsents[msg.sender].push(consentId);
        requesterConsents[requester].push(consentId);

        emit ConsentGranted(consentId, msg.sender, requester, attributes, expiresAt);

        return consentId;
    }

    /// @notice Revoke a previously granted consent
    /// @param consentId ID of the consent to revoke
    function revokeConsent(uint256 consentId) external onlyConsentOwner(consentId) {
        Consent storage consent = consents[consentId];
        
        if (consent.status != Status.Active) revert ConsentNotActive();

        consent.status = Status.Revoked;

        emit ConsentRevoked(consentId, consent.owner, consent.requester);
    }

    /// @notice Check if a consent is currently valid (has valid consent)
    /// @param owner Data owner address
    /// @param requester Requester address
    /// @param attribute Specific attribute to check
    /// @return valid True if there is an active consent for this attribute
    function hasValidConsent(
        address owner,
        address requester,
        DataType attribute
    ) public view returns (bool) {
        uint256[] memory consentIds = userRequesterConsents[owner][requester];
        
        for (uint256 i = consentIds.length; i > 0; i--) {
            uint256 consentId = consentIds[i - 1];
            if (isConsentValidForAttribute(consentId, attribute)) {
                return true;
            }
        }
        
        return false;
    }

    /// @notice Check if a consent is currently valid
    /// @param consentId ID of the consent to check
    /// @return valid True if consent is active and not expired
    function isConsentValid(uint256 consentId) public view returns (bool) {
        Consent storage consent = consents[consentId];
        
        if (consent.owner == address(0)) return false;
        if (consent.status != Status.Active) return false;
        if (block.timestamp > consent.expiresAt) return false;

        return true;
    }

    /// @notice Check if consent is valid for a specific attribute
    /// @param consentId ID of the consent to check
    /// @param attribute Specific attribute to check access for
    /// @return valid True if consent covers this attribute and is valid
    function isConsentValidForAttribute(uint256 consentId, DataType attribute) 
        public 
        view 
        returns (bool) 
    {
        if (!isConsentValid(consentId)) return false;

        Consent storage consent = consents[consentId];
        
        // Check if attribute is in the consent's attribute list
        for (uint256 i = 0; i < consent.attributes.length; i++) {
            if (consent.attributes[i] == attribute) {
                return true;
            }
        }

        return false;
    }

    /// @notice Mark a consent as expired (can be called by anyone)
    /// @param consentId ID of the consent to mark as expired
    function markExpired(uint256 consentId) external {
        Consent storage consent = consents[consentId];
        
        if (consent.owner == address(0)) revert ConsentNotFound();
        if (consent.status != Status.Active) revert ConsentNotActive();
        if (block.timestamp <= consent.expiresAt) revert ConsentNotActive();

        consent.status = Status.Expired;

        emit ConsentExpired(consentId, consent.owner, consent.requester);
    }

    /// @notice Get consent details
    /// @param consentId ID of the consent
    /// @return consent The consent struct
    function getConsent(uint256 consentId) external view returns (Consent memory) {
        return consents[consentId];
    }

    /// @notice Get all consent IDs between a user and requester
    /// @param user User address
    /// @param requester Requester address
    /// @return consentIds Array of consent IDs
    function getConsentsForUserAndRequester(address user, address requester) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userRequesterConsents[user][requester];
    }

    /// @notice Get all consent IDs granted by a user
    /// @param user User address
    /// @return consentIds Array of consent IDs
    function getUserConsents(address user) external view returns (uint256[] memory) {
        return userConsents[user];
    }

    /// @notice Get all consent IDs granted to a requester
    /// @param requester Requester address
    /// @return consentIds Array of consent IDs
    function getRequesterConsents(address requester) external view returns (uint256[] memory) {
        return requesterConsents[requester];
    }

    /// @notice Get active consent ID for a user-requester pair
    /// @param user User address
    /// @param requester Requester address
    /// @return consentId The active consent ID (0 if none active)
    function getActiveConsent(address user, address requester) 
        external 
        view 
        returns (uint256) 
    {
        uint256[] memory consentIds = userRequesterConsents[user][requester];
        
        for (uint256 i = consentIds.length; i > 0; i--) {
            uint256 consentId = consentIds[i - 1];
            if (isConsentValid(consentId)) {
                return consentId;
            }
        }
        
        return 0;
    }
}
