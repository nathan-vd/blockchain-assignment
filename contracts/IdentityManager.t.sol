// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IdentityManager} from "./IdentityManager.sol";
import {Test} from "forge-std/Test.sol";

contract IdentityManagerTest is Test {
    IdentityManager public identityManager;
    address public admin;
    address public user1;
    address public user2;
    address public dataSubmitter;
    
    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        dataSubmitter = address(0x3);
        identityManager = new IdentityManager();
    }
    
    function test_RegisterUser() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        assertTrue(identityManager.isRegistered(user1));
        assertEq(identityManager.totalUsers(), 1);
    }
    
    function test_DuplicateRegistration() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        
        vm.startPrank(user1);
        identityManager.registerUser(hashedUUID);
        
        vm.expectRevert(IdentityManager.AlreadyRegistered.selector);
        identityManager.registerUser(hashedUUID);
        vm.stopPrank();
    }
    
    function test_AuthorizeDataSubmitter() public {
        identityManager.setDataSubmitterAuthorization(dataSubmitter, true);
        
        assertTrue(identityManager.authorizedDataSubmitters(dataSubmitter));
    }
    
    function test_UpdateCreditData() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        uint256 creditScore = 750;
        bytes memory signature = abi.encodePacked("signature-data");
        
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        identityManager.setDataSubmitterAuthorization(dataSubmitter, true);
        
        vm.prank(dataSubmitter);
        identityManager.updateCreditData(user1, creditScore, signature);
        
        assertEq(identityManager.getCreditScore(user1), creditScore);
    }
    
    function test_UnauthorizedCreditUpdate() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        vm.prank(dataSubmitter);
        vm.expectRevert(IdentityManager.UnauthorizedDataSubmitter.selector);
        identityManager.updateCreditData(user1, 700, "sig");
    }
    
    function test_GetUserInfo() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        uint256 creditScore = 800;
        bytes memory signature = abi.encodePacked("sig");
        
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        identityManager.setDataSubmitterAuthorization(dataSubmitter, true);
        
        vm.prank(dataSubmitter);
        identityManager.updateCreditData(user1, creditScore, signature);
        
        (bytes32 uuid, uint256 score, uint256 timestamp, address submitter) = 
            identityManager.getUserInfo(user1);
        
        assertEq(uuid, hashedUUID);
        assertEq(score, creditScore);
        assertEq(submitter, dataSubmitter);
        assertTrue(timestamp > 0);
    }
    
    function test_VerifyUserData() public {
        bytes32 correctHash = keccak256(abi.encodePacked("user1-uuid"));
        bytes32 wrongHash = keccak256(abi.encodePacked("wrong-uuid"));
        
        vm.prank(user1);
        identityManager.registerUser(correctHash);
        
        assertTrue(identityManager.verifyUserData(user1, correctHash));
        assertFalse(identityManager.verifyUserData(user1, wrongHash));
    }
    
    function test_InvalidCreditScore() public {
        bytes32 hashedUUID = keccak256(abi.encodePacked("user1-uuid"));
        
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        identityManager.setDataSubmitterAuthorization(dataSubmitter, true);
        
        vm.startPrank(dataSubmitter);
        vm.expectRevert(IdentityManager.InvalidCreditScore.selector);
        identityManager.updateCreditData(user1, 200, "sig");
        
        vm.expectRevert(IdentityManager.InvalidCreditScore.selector);
        identityManager.updateCreditData(user1, 900, "sig");
        vm.stopPrank();
    }
    
    function test_TransferAdmin() public {
        address newAdmin = address(0x999);
        identityManager.transferAdmin(newAdmin);
        
        assertEq(identityManager.admin(), newAdmin);
    }
    
    function test_UnauthorizedAdminTransfer() public {
        vm.prank(user1);
        vm.expectRevert(IdentityManager.Unauthorized.selector);
        identityManager.transferAdmin(user2);
    }
    
    function test_NotRegisteredQueries() public {
        vm.expectRevert(IdentityManager.NotRegistered.selector);
        identityManager.getCreditScore(user1);
        
        vm.expectRevert(IdentityManager.NotRegistered.selector);
        identityManager.getUserInfo(user1);
    }
    
    function testFuzz_RegisterUser(bytes32 hashedUUID) public {
        vm.prank(user1);
        identityManager.registerUser(hashedUUID);
        
        assertTrue(identityManager.isRegistered(user1));
    }
}
