// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title ConsentManager
/// @notice Abstract surface for time-limited consent tracking
abstract contract ConsentManager {
    enum Status {
        None,
        Active,
        Revoked,
        Expired
    }

    struct Consent {
        address owner;
        address requester;
        uint256 dataType;
        uint256 issuedAt;
        uint256 expiresAt;
        Status status;
    }

    event ConsentGranted(uint256 indexed consentId, address indexed owner, address indexed requester, uint256 dataType, uint256 expiresAt);
    event ConsentRevoked(uint256 indexed consentId);

    error InvalidDuration();
    error NotOwner();
    error ConsentNotActive();

    function grantConsent(address requester, uint256 dataType, uint256 durationDays) external virtual returns (uint256);

    function revokeConsent(uint256 consentId) external virtual;

    function isConsentValid(uint256 consentId) public view virtual returns (bool);

    function getConsent(uint256 consentId) external view virtual returns (Consent memory);

    function markExpired(uint256 consentId) external virtual;
}
