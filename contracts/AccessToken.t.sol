// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {AccessToken} from "./AccessToken.sol";

contract AccessTokenTest is Test {
    AccessToken private token;
    address private owner = address(this);
    address private alice = address(0x1);
    address private bob = address(0x2);

    function setUp() public {
        token = new AccessToken(owner);
    }

    function testMintIncreasesSupply() public {
        uint256 amount = 100 * 1e18;
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount, "Alice balance incorrect");
        assertEq(token.totalSupply(), amount, "Total supply mismatch");
    }

    function testTransferMovesTokens() public {
        uint256 mintAmount = 50 * 1e18;
        token.mint(address(this), mintAmount);

        token.transfer(alice, 20 * 1e18);

        assertEq(token.balanceOf(alice), 20 * 1e18, "Alice should receive tokens");
        assertEq(token.balanceOf(address(this)), 30 * 1e18, "Sender balance wrong");
    }

    function testApproveAndTransferFrom() public {
        uint256 mintAmount = 80 * 1e18;
        token.mint(alice, mintAmount);

        vm.prank(alice);
        token.approve(bob, 40 * 1e18);

        vm.prank(bob);
        token.transferFrom(alice, address(this), 30 * 1e18);

        assertEq(token.balanceOf(address(this)), 30 * 1e18, "Receiver should get tokens");
        assertEq(token.balanceOf(alice), 50 * 1e18, "Alice balance mismatch");
        assertEq(token.allowance(alice, bob), 10 * 1e18, "Allowance mismatch");
    }

    function testUnauthorizedMintReverts() public {
        vm.prank(alice);
        vm.expectRevert("Not token owner");
        token.mint(bob, 1e18);
    }

    function testUpdateOwnerChangesAuthority() public {
        token.updateOwner(alice);
        assertEq(token.owner(), alice, "Owner should update");

        vm.prank(alice);
        token.mint(bob, 5 * 1e18);

        assertEq(token.balanceOf(bob), 5 * 1e18, "Mint after transferownership failed");
    }
}
