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
    
    function setUp() public {
        dataSharing = new DataSharing();
    }
    
    // Helper function to register a user with a unique identifier
    function _registerUser(address user, string memory uid) internal {
        bytes32 hashedUUID = keccak256(abi.encodePacked(uid));
        vm.prank(user);
        dataSharing.registerUser(hashedUUID);
    }
    
    function test_RegisterUser() public {
        // Use a unique address for this test
        address testUser = makeAddr("test-register-user");
        bytes32 hashedUUID = keccak256(abi.encodePacked("test-register-user-uuid"));
        
        vm.prank(testUser);
        dataSharing.registerUser(hashedUUID);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getidentityManager());
        assertTrue(identityManager.isRegistered(testUser));
    }
    
    function test_RequestAccess() public {
        // Use completely unique addresses for this test
        address user2 = makeAddr("test-request-user");
        address requester2 = makeAddr("test-request-requester");
        
        _registerUser(user2, "test-request-user");
        _registerUser(requester2, "test-request-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.Email;
        
        vm.prank(requester2);
        uint256 requestId = dataSharing.requestAccess(user2, attrs);
        
        assertEq(requestId, 0);
        assertEq(dataSharing.requestCounter(), 1);
    }
    
    function test_GrantConsent() public {
        // Use completely unique addresses for this test
        address user3 = makeAddr("test-grant-user");
        address requester3 = makeAddr("test-grant-requester");
        
        _registerUser(user3, "test-grant-user");
        _registerUser(requester3, "test-grant-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.CreditScore;
        
        vm.prank(user3);
        uint256 consentId = dataSharing.grantConsent(requester3, attrs, 30);
        
        ConsentManager consentManager = ConsentManager(dataSharing.getConsentManager());
        assertTrue(consentManager.isConsentValid(consentId));
        
        // Check token reward
        AccessToken token = AccessToken(dataSharing.getAccessToken());
        assertEq(token.balanceOf(user3), dataSharing.CONSENT_REWARD());
    }
    
    function test_GrantConsentForRequest() public {
        // Use completely unique addresses for this test
        address user4 = makeAddr("test-grant-req-user");
        address requester4 = makeAddr("test-grant-req-requester");
        
        _registerUser(user4, "test-grant-req-user");
        _registerUser(requester4, "test-grant-req-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Email;
        
        vm.prank(requester4);
        uint256 requestId = dataSharing.requestAccess(user4, attrs);
        
        vm.prank(user4);
        uint256 consentId = dataSharing.grantConsentForRequest(requestId, 30);
        
        assertTrue(consentId >= 0);
        
        // Check request is fulfilled
        DataSharing.AccessRequest memory request = dataSharing.getAccessRequest(requestId);
        assertFalse(request.active);
    }
    
    function test_VerifyAttribute() public {
        // Use completely unique addresses for this test
        address user5 = makeAddr("test-verify-user");
        address requester5 = makeAddr("test-verify-requester");
        
        _registerUser(user5, "test-verify-user");
        _registerUser(requester5, "test-verify-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user5);
        dataSharing.grantConsent(requester5, attrs, 30);
        
        assertTrue(dataSharing.verifyAttribute(user5, requester5, ConsentManager.DataType.Name));
        assertFalse(dataSharing.verifyAttribute(user5, requester5, ConsentManager.DataType.Email));
    }
    
    function test_CheckAccessPermission() public {
        // Use completely unique addresses for this test
        address user6 = makeAddr("test-check-user");
        address requester6 = makeAddr("test-check-requester");
        
        _registerUser(user6, "test-check-user");
        _registerUser(requester6, "test-check-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user6);
        uint256 consentId = dataSharing.grantConsent(requester6, attrs, 30);
        
        assertTrue(dataSharing.checkAccessPermission(user6, requester6, consentId, ConsentManager.DataType.Name));
        assertFalse(dataSharing.checkAccessPermission(user6, requester6, consentId, ConsentManager.DataType.Email));
    }
    
    function test_AccessData() public {
        // Use completely unique addresses for this test
        address user7 = makeAddr("test-access-user");
        address requester7 = makeAddr("test-access-requester");
        
        _registerUser(user7, "test-access-user");
        _registerUser(requester7, "test-access-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user7);
        uint256 consentId = dataSharing.grantConsent(requester7, attrs, 30);
        
        vm.prank(requester7);
        bool success = dataSharing.accessData(user7, consentId, ConsentManager.DataType.Name);
        
        assertTrue(success);
        
        // Check audit log
        AuditLog auditLog = AuditLog(dataSharing.getAuditLog());
        assertEq(auditLog.totalLogs(), 1);
    }
    
    function test_AccessDataDenied() public {
        // Use completely unique addresses for this test
        address user8 = makeAddr("test-denied-user");
        address requester8 = makeAddr("test-denied-requester");
        
        _registerUser(user8, "test-denied-user");
        _registerUser(requester8, "test-denied-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user8);
        uint256 consentId = dataSharing.grantConsent(requester8, attrs, 30);
        
        vm.prank(requester8);
        bool success = dataSharing.accessData(user8, consentId, ConsentManager.DataType.Email);
        
        assertFalse(success);
    }
    
    function test_RevokeConsent() public {
        // Use completely unique addresses for this test
        address user9 = makeAddr("test-revoke-user");
        address requester9 = makeAddr("test-revoke-requester");
        
        _registerUser(user9, "test-revoke-user");
        _registerUser(requester9, "test-revoke-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.UUID;
        
        vm.prank(user9);
        uint256 consentId = dataSharing.grantConsent(requester9, attrs, 30);
        
        vm.prank(user9);
        dataSharing.revokeConsent(consentId);
        
        ConsentManager consentManager = ConsentManager(dataSharing.getConsentManager());
        assertFalse(consentManager.isConsentValid(consentId));
    }
    
    function test_AccessAfterRevoke() public {
        // Use completely unique addresses for this test
        address user10 = makeAddr("test-after-revoke-user");
        address requester10 = makeAddr("test-after-revoke-requester");
        
        _registerUser(user10, "test-after-revoke-user");
        _registerUser(requester10, "test-after-revoke-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user10);
        uint256 consentId = dataSharing.grantConsent(requester10, attrs, 30);
        
        vm.prank(user10);
        dataSharing.revokeConsent(consentId);
        
        vm.prank(requester10);
        bool success = dataSharing.accessData(user10, consentId, ConsentManager.DataType.Name);
        
        assertFalse(success);
    }
    
    function test_CancelAccessRequest() public {
        // Use completely unique addresses for this test
        address user11 = makeAddr("test-cancel-user");
        address requester11 = makeAddr("test-cancel-requester");
        
        _registerUser(user11, "test-cancel-user");
        _registerUser(requester11, "test-cancel-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(requester11);
        uint256 requestId = dataSharing.requestAccess(user11, attrs);
        
        vm.prank(requester11);
        dataSharing.cancelAccessRequest(requestId);
        
        DataSharing.AccessRequest memory request = dataSharing.getAccessRequest(requestId);
        assertFalse(request.active);
    }
    
    function test_SubmitCreditVerification() public {
        // Use completely unique addresses for this test
        address user12 = makeAddr("test-credit-user");
        address dataSubmitter = makeAddr("test-credit-submitter");
        
        _registerUser(user12, "test-credit-user");
        
        // Authorize the data submitter (called by the deployer of DataSharing which is this test contract)
        dataSharing.authorizeDataSubmitter(dataSubmitter, true);
        
        uint256 creditScore = 720;
        bytes memory signature = abi.encodePacked("credit-verification-sig");
        
        vm.prank(dataSubmitter);
        dataSharing.submitCreditVerification(user12, creditScore, signature);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getidentityManager());
        assertEq(identityManager.getCreditScore(user12), creditScore);
    }
    
    function test_AuthorizeDataSubmitter() public {
        address dataSubmitter = makeAddr("test-authorize-submitter");
        
        dataSharing.authorizeDataSubmitter(dataSubmitter, true);
        
        IdentityManager identityManager = IdentityManager(dataSharing.getidentityManager());
        assertTrue(identityManager.authorizedDataSubmitters(dataSubmitter));
    }
    
    function test_GetContractAddresses() public {
        address identityAddr = dataSharing.getidentityManager();
        address consentAddr = dataSharing.getConsentManager();
        address auditAddr = dataSharing.getAuditLog();
        address tokenAddr = dataSharing.getAccessToken();
        
        assertTrue(identityAddr != address(0));
        assertTrue(consentAddr != address(0));
        assertTrue(auditAddr != address(0));
        assertTrue(tokenAddr != address(0));
    }
    
    function test_MultipleConsentsMultipleUsers() public {
        // Use completely unique addresses for this test
        address user13 = makeAddr("test-multi-user1");
        address user14 = makeAddr("test-multi-user2");
        address requester13 = makeAddr("test-multi-requester");
        
        _registerUser(user13, "test-multi-user1");
        _registerUser(user14, "test-multi-user2");
        _registerUser(requester13, "test-multi-requester");
        
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;
        
        vm.prank(user13);
        dataSharing.grantConsent(requester13, attrs, 30);
        
        vm.prank(user14);
        dataSharing.grantConsent(requester13, attrs, 60);
        
        AccessToken token = AccessToken(dataSharing.getAccessToken());
        assertEq(token.balanceOf(user13), dataSharing.CONSENT_REWARD());
        assertEq(token.balanceOf(user14), dataSharing.CONSENT_REWARD());
    }
}
