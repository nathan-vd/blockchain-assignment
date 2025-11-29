// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./ConsentManager.sol";

/// @title AuditLog
/// @notice Emits immutable events for every critical platform action
contract AuditLog {
    address public platform;

    event UserRegistered(address indexed user, bytes32 hashedUUID, uint256 timestamp);
    event CreditVerified(address indexed user, address indexed submitter, uint256 creditScore, uint256 timestamp);
    event ConsentEvent(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester,
        ConsentManager.DataType[] attributes,
        string action,
        uint256 timestamp
    );
    event AccessEvent(
        uint256 indexed consentId,
        address indexed requester,
        address indexed owner,
        ConsentManager.DataType attribute,
        bool success,
        string detail,
        uint256 timestamp
    );
    event TokenRewarded(address indexed user, uint256 amount, uint256 timestamp);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not audit platform");
        _;
    }

    constructor(address platformAddress) {
        require(platformAddress != address(0), "Platform required");
        platform = platformAddress;
    }

    function logUserRegistered(address user, bytes32 hashedUUID) external onlyPlatform {
        emit UserRegistered(user, hashedUUID, block.timestamp);
    }

    function logCreditVerified(address user, address submitter, uint256 creditScore) external onlyPlatform {
        emit CreditVerified(user, submitter, creditScore, block.timestamp);
    }

    function logConsent(
        uint256 consentId,
        address owner,
        address requester,
        ConsentManager.DataType[] calldata attributes,
        string calldata action
    ) external onlyPlatform {
        emit ConsentEvent(consentId, owner, requester, attributes, action, block.timestamp);
    }

    function logAccess(
        uint256 consentId,
        address requester,
        address owner,
        ConsentManager.DataType attribute,
        bool success,
        string calldata detail
    ) external onlyPlatform {
        emit AccessEvent(consentId, requester, owner, attribute, success, detail, block.timestamp);
    }

    function logTokenReward(address user, uint256 amount) external onlyPlatform {
        emit TokenRewarded(user, amount, block.timestamp);
    }

    function updatePlatform(address newPlatform) external onlyPlatform {
        require(newPlatform != address(0), "Platform required");
        platform = newPlatform;
    }
}
