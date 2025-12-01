// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/src/Test.sol";
import {ConsentManager} from "./ConsentManager.sol";
import {IIdentityRegistry} from "./ConsentManager.sol";

contract MockRegistry is IIdentityRegistry {
    mapping(address => bool) public registered;

    function setRegistered(address user, bool value) external {
        registered[user] = value;
    }

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
    }
}

contract ConsentManagerTest is Test {
    ConsentManager private manager;
    MockRegistry private registry;
    address private admin = address(this);
    address private owner = address(0x1);
    address private requester = address(0x2);

    function setUp() public {
        registry = new MockRegistry();
        registry.setRegistered(owner, true);
        registry.setRegistered(requester, true);
        manager = new ConsentManager(address(registry), admin);
    }

    function _attributes(ConsentManager.DataType dt) private pure returns (ConsentManager.DataType[] memory) {
        ConsentManager.DataType[] memory attrs = new ConsentManager.DataType[](1);
        attrs[0] = dt;
        return attrs;
    }

    function testGrantConsentStoresDetails() public {
        uint256 consentId = manager.grantConsentFor(owner, requester, _attributes(ConsentManager.DataType.Email), 30);
        ConsentManager.Consent memory consent = manager.getConsent(consentId);

        assertEq(consent.owner, owner, "Owner mismatch");
        assertEq(consent.requester, requester, "Requester mismatch");
        assertFalse(consent.revoked, "Consent should be active");
        assertTrue(consent.expiresAt > block.timestamp, "Expiration missing");
    }

    function testOwnerCanGrantDirectly() public {
        vm.prank(owner);
        uint256 consentId = manager.grantConsent(requester, _attributes(ConsentManager.DataType.Name), 20);

        ConsentManager.Consent memory consent = manager.getConsent(consentId);
        assertEq(consent.owner, owner, "Owner mismatch");
        assertEq(consent.requester, requester, "Requester mismatch");
    }

    function testRevokeConsentMarksRevoked() public {
        uint256 consentId = manager.grantConsentFor(owner, requester, _attributes(ConsentManager.DataType.UUID), 10);
        vm.prank(owner);
        manager.revokeConsent(consentId);

        assertFalse(manager.isConsentValid(consentId), "Consent should be invalid");
        assertFalse(manager.coversAttribute(consentId, ConsentManager.DataType.UUID), "Attribute should not be allowed");
    }

    function testInvalidDurationReverts() public {
        vm.expectRevert("Invalid duration");
        manager.grantConsentFor(owner, requester, _attributes(ConsentManager.DataType.Name), 0);

        vm.startPrank(owner);
        vm.expectRevert("Invalid duration");
        manager.grantConsent(requester, _attributes(ConsentManager.DataType.Name), 0);
        vm.stopPrank();
    }

    function testHasValidConsentChecksAttribute() public {
        uint256 consentId = manager.grantConsentFor(owner, requester, _attributes(ConsentManager.DataType.CreditScore), 5);

        assertTrue(manager.hasValidConsent(owner, requester, ConsentManager.DataType.CreditScore), "Attribute should be allowed");
        assertFalse(manager.hasValidConsent(owner, requester, ConsentManager.DataType.Email), "Attribute should be denied");

        vm.warp(block.timestamp + 6 days);
        assertFalse(manager.isConsentValid(consentId), "Consent should expire");
    }

    function testUnauthorizedRevokeReverts() public {
        uint256 consentId = manager.grantConsentFor(owner, requester, _attributes(ConsentManager.DataType.Email), 30);
        vm.prank(address(0x5));
        vm.expectRevert("Not authorized");
        manager.revokeConsent(consentId);
    }
}
