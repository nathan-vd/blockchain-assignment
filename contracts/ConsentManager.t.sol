// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ConsentManager} from "./ConsentManager.sol";
import {IdentityManager} from "./IdentityManager.sol";
import {Test} from "forge-std/Test.sol";

contract ConsentManagerTest is Test {
    ConsentManager public consentManager;
    IdentityManager public identityManager;
    
    address public user1;
    address public user2;
    address public requester;
    
    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        requester = address(0x3);
        
        identityManager = new IdentityManager();
        consentManager = new ConsentManager(address(identityManager));
        
        // Register users
        vm.prank(user1);
        identityManager.registerUser(keccak256("user1"));
        
        vm.prank(user2);
        identityManager.registerUser(keccak256("user2"));
        
        vm.prank(requester);
        identityManager.registerUser(keccak256("requester"));
    }
    
    function test_RequestAccess() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.Email;
        
        vm.prank(requester);
        vm.expectEmit(true, true, false, true);
        emit ConsentManager.AccessRequested(requester, user1, attrs, block.timestamp);
        consentManager.requestAccess(user1, attrs);
    }
    
    function test_GrantConsent() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.CreditScore;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        assertEq(consentId, 0);
        assertEq(consentManager.consentCounter(), 1);
        assertTrue(consentManager.isConsentValid(consentId));
    }
    
    function test_InvalidDuration() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.startPrank(user1);
        vm.expectRevert(ConsentManager.InvalidDuration.selector);
        consentManager.grantConsent(requester, attrs, 0);
        
        vm.expectRevert(ConsentManager.InvalidDuration.selector);
        consentManager.grantConsent(requester, attrs, 366);
        vm.stopPrank();
    }
    
    function test_RevokeConsent() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Email;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        vm.prank(user1);
        consentManager.revokeConsent(consentId);
        
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        assertEq(uint8(consent.status), uint8(ConsentManager.Status.Revoked));
        assertFalse(consentManager.isConsentValid(consentId));
    }
    
    function test_UnauthorizedRevoke() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Email;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        vm.prank(user2);
        vm.expectRevert(ConsentManager.NotOwner.selector);
        consentManager.revokeConsent(consentId);
    }
    
    function test_IsConsentValidForAttribute() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.Email;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        assertTrue(consentManager.isConsentValidForAttribute(consentId, ConsentManager.DataType.Name));
        assertTrue(consentManager.isConsentValidForAttribute(consentId, ConsentManager.DataType.Email));
        assertFalse(consentManager.isConsentValidForAttribute(consentId, ConsentManager.DataType.CreditScore));
    }
    
    function test_HasValidConsent() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.UUID;
        
        vm.prank(user1);
        consentManager.grantConsent(requester, attrs, 30);
        
        assertTrue(consentManager.hasValidConsent(user1, requester, ConsentManager.DataType.UUID));
        assertFalse(consentManager.hasValidConsent(user1, requester, ConsentManager.DataType.Name));
    }
    
    function test_GetActiveConsent() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Email;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        uint256 activeId = consentManager.getActiveConsent(user1, requester);
        assertEq(activeId, consentId);
    }
    
    function test_GetConsent() public {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, 30);
        
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        assertEq(consent.owner, user1);
        assertEq(consent.requester, requester);
        assertEq(consent.attributes.length, 1);
    }
    
    function test_MultipleConsents() public {
        ConsentManager.DataType[] memory attrs1 = new ConsentManager.DataType[](1);
        attrs1[0] = ConsentManager.DataType.Name;
        
        ConsentManager.DataType[] memory attrs2 = new ConsentManager.DataType[](1);
        attrs2[0] = ConsentManager.DataType.Email;
        
        vm.startPrank(user1);
        uint256 id1 = consentManager.grantConsent(requester, attrs1, 30);
        uint256 id2 = consentManager.grantConsent(user2, attrs2, 60);
        vm.stopPrank();
        
        assertEq(id1, 0);
        assertEq(id2, 1);
        
        uint256[] memory userConsents = consentManager.getUserConsents(user1);
        assertEq(userConsents.length, 2);
    }
    
    function testFuzz_GrantConsent(uint256 durationDays) public {
        vm.assume(durationDays >= 1 && durationDays <= 365);
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = consentManager.grantConsent(requester, attrs, durationDays);
        
        assertTrue(consentManager.isConsentValid(consentId));
    }
}
