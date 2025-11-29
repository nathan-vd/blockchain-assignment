// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {AuditLog} from "./AuditLog.sol";

contract AuditLogTest is Test {
    AuditLog private auditLog;
    address private platform = address(this);
    address private requester = address(0x2);
    address private user = address(0x3);

    event UserRegistered(address indexed user, bytes32 hashedUUID, uint256 timestamp);
    event CreditVerified(address indexed user, address indexed submitter, uint256 creditScore, uint256 timestamp);
    event ConsentEvent(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester,
        uint8[] attributes,
        string action,
        uint256 timestamp
    );
    event AccessEvent(
        uint256 indexed consentId,
        address indexed requester,
        address indexed owner,
        uint8 attribute,
        bool success,
        string detail,
        uint256 timestamp
    );
    event TokenRewarded(address indexed user, uint256 amount, uint256 timestamp);

    function setUp() public {
        auditLog = new AuditLog(platform);
    }

    function testOnlyPlatformMayLog() public {
        vm.prank(address(0xdead));
        vm.expectRevert("Not audit platform");
        auditLog.logTokenReward(user, 1 ether);
    }

    function testLogUserRegisteredEmitsEvent() public {
        bytes32 uuid = keccak256("user-uuid");
        vm.expectEmit(true, true, false, true);
        emit UserRegistered(user, uuid, block.timestamp);
        auditLog.logUserRegistered(user, uuid);
    }

    function testLogCreditVerifiedEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit CreditVerified(user, requester, 720, block.timestamp);
        auditLog.logCreditVerified(user, requester, 720);
    }

    function testLogConsentEvent() public {
        uint8[] memory attrs = new uint8[](2);
        attrs[0] = 1;
        attrs[1] = 3;

        vm.expectEmit(true, true, true, true);
        emit ConsentEvent(1, user, requester, attrs, "GRANTED", block.timestamp);
        auditLog.logConsent(1, user, requester, attrs, "GRANTED");
    }

    function testLogAccessEvent() public {
        vm.expectEmit(true, true, true, true);
        emit AccessEvent(2, requester, user, 0, true, "OK", block.timestamp);
        auditLog.logAccess(2, requester, user, 0, true, "OK");
    }

    function testLogTokenRewardEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit TokenRewarded(user, 5 ether, block.timestamp);
        auditLog.logTokenReward(user, 5 ether);
    }

    function testUpdatePlatformChangesAuthority() public {
        address newPlatform = address(0x99);
        auditLog.updatePlatform(newPlatform);
        assertEq(auditLog.platform(), newPlatform, "Platform not updated");

        vm.prank(newPlatform);
        auditLog.logTokenReward(user, 1);
    }
}
