// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AuditLog} from "./AuditLog.sol";
import {Test} from "forge-std/Test.sol";

contract AuditLogTest is Test {
    AuditLog public auditLog;
    
    address public platform;
    address public user1;
    address public user2;
    address public requester1;
    
    function setUp() public {
        platform = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        requester1 = address(0x3);
        
        auditLog = new AuditLog();
    }
    
    function test_LogAccess() public {
        auditLog.logAccess(
            1,
            requester1,
            user1,
            0, // UUID
            AuditLog.AccessResult.Success,
            "Access granted"
        );
        
        assertEq(auditLog.totalLogs(), 1);
    }
    
    function test_LogConsent() public {
        uint8[] memory attrs = new uint8[](2);
        attrs[0] = 0; // UUID
        attrs[1] = 1; // Name
        
        auditLog.logConsent(1, user1, requester1, attrs, "GRANTED");
        
        AuditLog.ConsentEvent[] memory logs = auditLog.getUserConsentLogs(user1);
        assertEq(logs.length, 1);
        assertEq(logs[0].consentId, 1);
    }
    
    function test_GetLog() public {
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        
        AuditLog.AccessEvent memory log = auditLog.getLog(0);
        
        assertEq(log.requester, requester1);
        assertEq(log.owner, user1);
        assertEq(uint8(log.result), uint8(AuditLog.AccessResult.Success));
    }
    
    function test_GetUserLogs() public {
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        auditLog.logAccess(2, requester1, user1, 1, AuditLog.AccessResult.Success, "Success");
        
        uint256[] memory logs = auditLog.getUserLogs(user1);
        assertEq(logs.length, 2);
    }
    
    function test_GetUserAccessLogs() public {
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        
        AuditLog.AccessEvent[] memory logs = auditLog.getUserAccessLogs(user1);
        assertEq(logs.length, 1);
        assertEq(logs[0].owner, user1);
    }
    
    function test_GetConsentAccessLogs() public {
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        auditLog.logAccess(1, requester1, user1, 1, AuditLog.AccessResult.Success, "Success");
        
        uint256[] memory logs = auditLog.getConsentAccessLogs(1);
        assertEq(logs.length, 2);
    }
    
    function test_GetRecentLogs() public {
        for (uint i = 0; i < 5; i++) {
            auditLog.logAccess(i, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        }
        
        AuditLog.AccessEvent[] memory logs = auditLog.getRecentLogs(3);
        assertEq(logs.length, 3);
    }
    
    function test_GetLogsByTimeRange() public {
        uint256 startTime = block.timestamp;
        
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        
        vm.warp(block.timestamp + 1 hours);
        auditLog.logAccess(2, requester1, user1, 1, AuditLog.AccessResult.Success, "Success");
        
        uint256 endTime = block.timestamp;
        
        AuditLog.AccessEvent[] memory logs = auditLog.getLogsByTimeRange(user1, startTime, endTime);
        assertEq(logs.length, 2);
    }
    
    function test_UnauthorizedLog() public {
        vm.prank(user1);
        vm.expectRevert(AuditLog.Unauthorized.selector);
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
    }
    
    function test_UpdatePlatform() public {
        address newPlatform = address(0x999);
        auditLog.updatePlatform(newPlatform);
        
        assertEq(auditLog.platform(), newPlatform);
    }
    
    function test_UnauthorizedPlatformUpdate() public {
        vm.prank(user1);
        vm.expectRevert(AuditLog.Unauthorized.selector);
        auditLog.updatePlatform(user1);
    }
    
    function test_MultipleAccessResults() public {
        auditLog.logAccess(1, requester1, user1, 0, AuditLog.AccessResult.Success, "Success");
        auditLog.logAccess(2, requester1, user1, 1, AuditLog.AccessResult.Denied, "Denied");
        auditLog.logAccess(3, requester1, user1, 2, AuditLog.AccessResult.Expired, "Expired");
        
        AuditLog.AccessEvent memory log0 = auditLog.getLog(0);
        AuditLog.AccessEvent memory log1 = auditLog.getLog(1);
        AuditLog.AccessEvent memory log2 = auditLog.getLog(2);
        
        assertEq(uint8(log0.result), uint8(AuditLog.AccessResult.Success));
        assertEq(uint8(log1.result), uint8(AuditLog.AccessResult.Denied));
        assertEq(uint8(log2.result), uint8(AuditLog.AccessResult.Expired));
    }
    
    function testFuzz_LogAccess(uint256 consentId, uint8 dataType) public {
        auditLog.logAccess(
            consentId,
            requester1,
            user1,
            dataType,
            AuditLog.AccessResult.Success,
            "Fuzz test"
        );
        
        assertTrue(auditLog.totalLogs() > 0);
    }
}
