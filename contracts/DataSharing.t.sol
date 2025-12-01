// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/src/Test.sol";
import {DataSharing} from "./DataSharing.sol";
import {ConsentManager} from "./ConsentManager.sol";
import {AccessToken} from "./AccessToken.sol";
import {IdentityManager} from "./IdentityManager.sol";

contract DataSharingTest is Test {
    DataSharing private platform;
    address private alice = address(0x1);
    address private requester = address(0x2);
    bytes32 private aliceUUID = keccak256("alice-uuid");
    bytes32 private requesterUUID = keccak256("requester-uuid");

    function setUp() public {
        platform = new DataSharing();
    }

    function _registerUsers() internal {
        vm.prank(alice);
        platform.registerUser(aliceUUID);

        vm.prank(requester);
        platform.registerUser(requesterUUID);
    }

    function testConsentLifecycleAndAccess() public {
        _registerUsers();

        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](2);
        attrs[0] = ConsentManager.DataType.Name;
        attrs[1] = ConsentManager.DataType.CreditScore;

        vm.prank(requester);
        uint256 requestId = platform.requestAccess(alice, attrs);

        vm.prank(alice);
        uint256 consentId = platform.grantConsent(requestId, 30);
        assertTrue(consentId >= 0, "Consent should be created");

        AccessToken token = platform.accessToken();
        assertEq(token.balanceOf(alice), platform.CONSENT_REWARD(), "Reward not minted");

        vm.prank(requester);
        bool success = platform.accessData(consentId, ConsentManager.DataType.Name);
        assertTrue(success, "Access should succeed");

        (,, ConsentManager.DataType[] memory finalAttrs,, bool active) = platform.getRequest(requestId);
        assertEq(finalAttrs.length, 2, "Attributes mismatch");
        assertFalse(active, "Request should be inactive after consent");
    }

    function testRevocationPreventsAccess() public {
        _registerUsers();

        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = ConsentManager.DataType.Name;

        vm.prank(requester);
        uint256 requestId = platform.requestAccess(alice, attrs);

        vm.prank(alice);
        uint256 consentId = platform.grantConsent(requestId, 15);

        vm.prank(alice);
        platform.revokeConsent(consentId);

        vm.prank(requester);
        bool success = platform.accessData(consentId, ConsentManager.DataType.Name);
        assertFalse(success, "Access should fail after revoke");
    }

    function testSubmitCreditVerification() public {
        _registerUsers();

        platform.setDataSubmitter(address(this), true);

        bytes memory signature = abi.encodePacked("signed");
        platform.submitCreditVerification(alice, 710, signature);

        IdentityManager identity = platform.identityManager();
        IdentityManager.Identity memory record = identity.getIdentity(alice);
        assertEq(record.creditScore, 710, "Credit score mismatch");
        assertEq(record.dataSubmitter, address(this), "Submitter mismatch");
    }
}
