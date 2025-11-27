// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title DigitalIdentity
/// @notice Abstract interface describing the identity registry surface
abstract contract DigitalIdentity {
    struct Identity {
        uint256 hashedUserId;
        uint256 hashedEmail;
        string metadataURI;
        uint256 creditTier;
        bool exists;
    }

    event UserRegistered(address indexed user, uint256 hashedUserId, uint256 hashedEmail, string metadataURI, uint256 creditTier);
    event MetadataUpdated(address indexed user, string metadataURI, uint256 creditTier);

    error AlreadyRegistered();
    error NotRegistered();

    /// @notice Registers a new user identity (one-time)
    function register(uint256 hashedUserId, uint256 hashedEmail, string calldata metadataURI, uint256 creditTier) external virtual;

    /// @notice Updates metadata references and optionally credit tier after re-verification
    function updateMetadata(string calldata metadataURI, uint256 creditTier) external virtual;

    /// @notice Returns stored identity record
    function getIdentity(address user) external view virtual returns (Identity memory);

    /// @notice Helper used by other contracts to verify registration
    function isRegistered(address user) external view virtual returns (bool);
}
