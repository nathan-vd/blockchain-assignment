// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IIdentityRegistry {
    function isRegistered(address user) external view returns (bool);
}

/// @title ConsentManager
/// @notice Tracks consent agreements, authorized attributes, and expiration windows
contract ConsentManager {
    enum DataType {
        UUID,
        Name,
        Email,
        CreditScore
    }

    struct Consent {
        address owner;
        address requester;
        uint256 grantedAt;
        uint256 expiresAt;
        bool revoked;
        DataType[] attributes;
    }

    uint256 public nextConsentId;

    mapping(uint256 => Consent) private consents;
    mapping(address => mapping(address => uint256[])) private consentsForPair;

    address public admin;
    IIdentityRegistry public identityRegistry;

    event ConsentGranted(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester,
        uint256 expiresAt
    );
    event ConsentRevoked(uint256 indexed consentId, address indexed owner, address indexed requester);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not consent admin");
        _;
    }

    constructor(address identityAddress, address adminAddress) {
        require(identityAddress != address(0), "Identity required");
        require(adminAddress != address(0), "Admin required");
        identityRegistry = IIdentityRegistry(identityAddress);
        admin = adminAddress;
    }

    /// @notice Grant consent directly as the data owner
    function grantConsent(
        address requester,
        DataType[] calldata attributes,
        uint256 durationDays
    ) external returns (uint256) {
        return _createConsent(msg.sender, requester, attributes, durationDays);
    }

    /// @notice Grant consent on behalf of a user (platform-controlled)
    function grantConsentFor(
        address owner,
        address requester,
        DataType[] calldata attributes,
        uint256 durationDays
    ) external onlyAdmin returns (uint256) {
        return _createConsent(owner, requester, attributes, durationDays);
    }

    /// @notice Revoke an active consent (owner or platform)
    function revokeConsent(uint256 consentId) external {
        Consent storage consent = consents[consentId];
        require(consent.owner != address(0), "Consent missing");
        require(!consent.revoked, "Already revoked");
        require(msg.sender == consent.owner || msg.sender == admin, "Not authorized");

        consent.revoked = true;

        emit ConsentRevoked(consentId, consent.owner, consent.requester);
    }

    /// @notice Check if a consent is active and unexpired
    function isConsentValid(uint256 consentId) public view returns (bool) {
        Consent storage consent = consents[consentId];
        if (consent.owner == address(0)) {
            return false;
        }
        if (consent.revoked) {
            return false;
        }
        if (block.timestamp > consent.expiresAt) {
            return false;
        }
        return true;
    }

    /// @notice Check if a consent covers a specific attribute
    function coversAttribute(uint256 consentId, DataType attribute) public view returns (bool) {
        if (!isConsentValid(consentId)) {
            return false;
        }

        Consent storage consent = consents[consentId];
        for (uint256 i = 0; i < consent.attributes.length; i++) {
            if (consent.attributes[i] == attribute) {
                return true;
            }
        }

        return false;
    }

    /// @notice Determine if requester currently has access to a specific attribute
    function hasValidConsent(address owner, address requester, DataType attribute) external view returns (bool) {
        uint256[] memory ids = consentsForPair[owner][requester];
        for (uint256 i = ids.length; i > 0; i--) {
            uint256 consentId = ids[i - 1];
            if (coversAttribute(consentId, attribute)) {
                return true;
            }
        }
        return false;
    }

    /// @notice Fetch consent details
    function getConsent(uint256 consentId) external view returns (Consent memory) {
        return consents[consentId];
    }

    function _createConsent(
        address owner,
        address requester,
        DataType[] calldata attributes,
        uint256 durationDays
    ) internal returns (uint256) {
        require(owner != address(0) && requester != address(0), "Invalid parties");
        require(identityRegistry.isRegistered(owner), "Owner not registered");
        require(identityRegistry.isRegistered(requester), "Requester not registered");
        require(attributes.length > 0, "Attributes required");
        require(durationDays >= 1 && durationDays <= 365, "Invalid duration");

        uint256 consentId = nextConsentId++;
        Consent storage consent = consents[consentId];
        consent.owner = owner;
        consent.requester = requester;
        consent.grantedAt = block.timestamp;
        consent.expiresAt = block.timestamp + (durationDays * 1 days);
        consent.revoked = false;

        for (uint256 i = 0; i < attributes.length; i++) {
            consent.attributes.push(attributes[i]);
        }

        consentsForPair[owner][requester].push(consentId);

        emit ConsentGranted(consentId, owner, requester, consent.expiresAt);
        return consentId;
    }
}
