// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IdentityManager} from "./IdentityManager.sol";

contract IdentityManagerTest is Test {
    IdentityManager private manager;
    address private admin = address(this);
    address private alice = address(0x1);
    address private bob = address(0x2);
    address private submitter = address(0x3);

    function setUp() public {
        manager = new IdentityManager(admin);
    }

    function testRegisterStoresIdentity() public {
        bytes32 uuid = keccak256(abi.encodePacked("alice"));
        manager.register(alice, uuid);

        IdentityManager.Identity memory identity = manager.getIdentity(alice);
        assertEq(identity.hashedUUID, uuid, "UUID mismatch");
        assertTrue(identity.exists, "Identity missing");
        assertEq(manager.totalUsers(), 1, "Total users incorrect");
    }

    function testDuplicateRegistrationReverts() public {
        bytes32 uuid = keccak256("dup");
        manager.register(alice, uuid);

        vm.expectRevert("Already registered");
        manager.register(alice, uuid);
    }

    function testOnlyAdminRegisters() public {
        vm.prank(bob);
        vm.expectRevert("Not identity admin");
        manager.register(bob, keccak256("bob"));
    }

    function testAuthorizeSubmitterAndUpdateCredit() public {
        bytes32 uuid = keccak256("alice");
        manager.register(alice, uuid);

        manager.setDataSubmitter(submitter, true);
        assertTrue(manager.authorizedSubmitters(submitter), "Submitter authorization missing");

        bytes memory signature = abi.encodePacked("sig");
        manager.updateCreditData(alice, 720, signature, submitter);

        IdentityManager.Identity memory identity = manager.getIdentity(alice);
        assertEq(identity.creditScore, 720, "Credit score mismatch");
        assertEq(identity.dataSubmitter, submitter, "Submitter mismatch");
        assertTrue(identity.verificationTimestamp > 0, "Timestamp missing");
    }

    function testUnauthorizedCreditUpdateReverts() public {
        bytes32 uuid = keccak256("alice");
        manager.register(alice, uuid);

        bytes memory signature = abi.encodePacked("sig");
        vm.expectRevert("Not data submitter");
        manager.updateCreditData(alice, 650, signature, submitter);
    }

    function testVerifyUUID() public {
        bytes32 uuid = keccak256("alice");
        manager.register(alice, uuid);

        assertTrue(manager.verifyUUID(alice, uuid), "Hash should match");
        assertFalse(manager.verifyUUID(alice, keccak256("other")), "Wrong hash should fail");
    }
}
