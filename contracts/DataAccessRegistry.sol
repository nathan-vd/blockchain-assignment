// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title DataAccessRegistry
/// @notice Abstract logging surface for data access attempts
abstract contract DataAccessRegistry {
    struct AccessEvent {
        uint256 consentId;
        address requester;
        address owner;
        uint256 dataType;
        uint256 timestamp;
        bool granted;
        string reason;
    }

    event AccessLogged(uint256 indexed consentId, address indexed requester, bool granted, string reason);

    function logAccess(uint256 consentId, string calldata reasonIfDenied) external virtual;

    function getLog(uint256 index) external view virtual returns (AccessEvent memory);

    function totalLogs() external view virtual returns (uint256);
}
