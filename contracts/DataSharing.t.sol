// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DataSharing} from "./DataSharing.sol";
import {IdentityManager} from "./IdentityManager.sol";
import {ConsentManager} from "./ConsentManager.sol";
import {AuditLog} from "./AuditLog.sol";
import {AccessToken} from "./AccessToken.sol";
import {Test} from "forge-std/Test.sol";

contract DataSharingTest is Test {
    DataSharing public dataSharing;
    
    address public user1;
    address public user2;
    address public requester;
    address public dataSubmitter;
    
    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        requester = address(0x3);
        dataSubmitter = address(0x4);
        
        dataSharing = new DataSharing();
    }
    
    function test_RegisterUser() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        
        vm.prank(user1);
        dataSharing.registerUser(hashedUUID);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getIdentityContract());
        assertTrue(identityManager.isRegistered(user1));
    }
    
    function test_RequestAccess() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.Email;
        
        vm.prank(requester);
        uint256 requestId = dataSharing.requestAccess(user1, attrs);
        
        assertEq(requestId, 0);
        assertEq(dataSharing.requestCounter(), 1);
    }
    
    function test_GrantConsent() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.CreditScore;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        ConsentManager consentManager = ConsentManager(dataSharing.getConsentManager());
        assertTrue(consentManager.isConsentValid(consentId));
        
        // Check token reward
        AccessToken token = AccessToken(dataSharing.getAccessToken());
        assertEq(token.balanceOf(user1), dataSharing.CONSENT_REWARD());
    }
    
    function test_GrantConsentForRequest() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Email;
        
        vm.prank(requester);
        uint256 requestId = dataSharing.requestAccess(user1, attrs);
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsentForRequest(requestId, 30);
        
        assertTrue(consentId >= 0);
        
        // Check request is fulfilled
        (,,, bool active) = dataSharing.accessRequests(requestId);
        assertFalse(active);
    }
    
    function test_VerifyAttribute() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        dataSharing.grantConsent(requester, attrs, 30);
        
        assertTrue(dataSharing.verifyAttribute(user1, requester, ConsentManager.DataType.Name));
        assertFalse(dataSharing.verifyAttribute(user1, requester, ConsentManager.DataType.Email));
    }
    
    function test_CheckAccessPermission() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        assertTrue(dataSharing.checkAccessPermission(user1, requester, consentId, ConsentManager.DataType.Name));
        assertFalse(dataSharing.checkAccessPermission(user1, requester, consentId, ConsentManager.DataType.Email));
    }
    
    function test_AccessData() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        vm.prank(requester);
        bool success = dataSharing.accessData(user1, consentId, ConsentManager.DataType.Name);
        
        assertTrue(success);
        
        // Check audit log
        AuditLog auditLog = AuditLog(dataSharing.getAuditLog());
        assertEq(auditLog.totalLogs(), 1);
    }
    
    function test_AccessDataDenied() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        vm.prank(requester);
        bool success = dataSharing.accessData(user1, consentId, ConsentManager.DataType.Email);
        
        assertFalse(success);
    }
    
    function test_RevokeConsent() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.UUID;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        vm.prank(user1);
        dataSharing.revokeConsent(consentId);
        
        ConsentManager consentManager = ConsentManager(dataSharing.getConsentManager());
        assertFalse(consentManager.isConsentValid(consentId));
    }
    
    function test_AccessAfterRevoke() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        uint256 consentId = dataSharing.grantConsent(requester, attrs, 30);
        
        vm.prank(user1);
        dataSharing.revokeConsent(consentId);
        
        vm.prank(requester);
        bool success = dataSharing.accessData(user1, consentId, ConsentManager.DataType.Name);
        
        assertFalse(success);
    }
    
    function test_CancelAccessRequest() public {
        _registerUser(user1, "user1");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(requester);
        uint256 requestId = dataSharing.requestAccess(user1, attrs);
        
        vm.prank(requester);
        dataSharing.cancelAccessRequest(requestId);
        
        (,,, bool active) = dataSharing.accessRequests(requestId);
        assertFalse(active);
    }
    
    function test_SubmitCreditVerification() public {
        _registerUser(user1, "user1");
        
        // Use the DataSharing contract to authorize (since it's the admin of IdentityManager)
        dataSharing.authorizeDataSubmitter(dataSubmitter, true);
        
        uint256 creditScore = 720;
        bytes memory signature = abi.encodePacked("credit-verification-sig");
        
        vm.prank(dataSubmitter);
        dataSharing.submitCreditVerification(user1, creditScore, signature);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getIdentityContract());
        assertEq(identityManager.getCreditScore(user1), creditScore);
    }
    
    function test_AuthorizeDataSubmitter() public {
        dataSharing.authorizeDataSubmitter(dataSubmitter, true);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getIdentityContract());
        assertTrue(identityManager.authorizedDataSubmitters(dataSubmitter));
    }
    
    function test_GetContractAddresses() public {
        address identityAddr = dataSharing.getIdentityContract();
        address consentAddr = dataSharing.getConsentManager();
        address auditAddr = dataSharing.getAuditLog();
        address tokenAddr = dataSharing.getAccessToken();
        
        assertTrue(identityAddr != address(0));
        assertTrue(consentAddr != address(0));
        assertTrue(auditAddr != address(0));
        assertTrue(tokenAddr != address(0));
    }
    
    function test_MultipleConsentsMultipleUsers() public {
        _registerUser(user1, "user1");
        _registerUser(user2, "user2");
        _registerUser(requester, "requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user1);
        dataSharing.grantConsent(requester, attrs, 30);
        
        vm.prank(user2);
        dataSharing.grantConsent(requester, attrs, 60);
        
        AccessToken token = AccessToken(dataSharing.getAccessToken());
        assertEq(token.balanceOf(user1), dataSharing.CONSENT_REWARD());
        assertEq(token.balanceOf(user2), dataSharing.CONSENT_REWARD());
    }
    
    // Helper function
    function _registerUser(address user, string memory uid) internal {
        bytes32 hashedUUID = keccak256(abi.encodePacked(uid));
        vm.prank(user);
        dataSharing.registerUser(hashedUUID);
    }
}
