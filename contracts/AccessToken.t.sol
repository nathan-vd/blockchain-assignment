// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessToken} from "./AccessToken.sol";
import {Test} from "forge-std/Test.sol";

contract AccessTokenTest is Test {
    AccessToken public token;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        token = new AccessToken();
    }
    
    function test_Mint() public {
        uint256 amount = 100 * 10**18;
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function test_Transfer() public {
        uint256 amount = 50 * 10**18;
        token.mint(address(this), amount);
        
        bool success = token.transfer(user1, 20 * 10**18);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), 20 * 10**18);
        assertEq(token.balanceOf(address(this)), 30 * 10**18);
    }
    
    function test_Approve() public {
        uint256 amount = 30 * 10**18;
        bool success = token.approve(user2, amount);
        
        assertTrue(success);
        assertEq(token.allowance(address(this), user2), amount);
    }
    
    function test_TransferFrom() public {
        uint256 mintAmount = 100 * 10**18;
        uint256 approveAmount = 50 * 10**18;
        uint256 transferAmount = 30 * 10**18;
        
        token.mint(user1, mintAmount);
        
        vm.prank(user1);
        token.approve(user2, approveAmount);
        
        vm.prank(user2);
        token.transferFrom(user1, address(this), transferAmount);
        
        assertEq(token.balanceOf(address(this)), transferAmount);
        assertEq(token.balanceOf(user1), mintAmount - transferAmount);
        assertEq(token.allowance(user1, user2), approveAmount - transferAmount);
    }
    
    function test_RewardConsent() public {
        uint256 initialAmount = 100 * 10**18;
        uint256 reward = 10 * 10**18;
        
        token.mint(user1, initialAmount);
        token.rewardConsent(user1, reward);
        
        assertEq(token.balanceOf(user1), initialAmount + reward);
    }
    
    function test_UnauthorizedMint() public {
        vm.prank(user1);
        vm.expectRevert(AccessToken.Unauthorized.selector);
        token.mint(user2, 100);
    }
    
    function test_InvalidTransferToZeroAddress() public {
        token.mint(address(this), 100);
        
        vm.expectRevert(AccessToken.InvalidAddress.selector);
        token.transfer(address(0), 1);
    }
    
    function test_InsufficientBalance() public {
        vm.expectRevert(AccessToken.InsufficientBalance.selector);
        token.transfer(user1, 100);
    }
    
    function test_TransferOwnership() public {
        address newOwner = address(0x999);
        token.transferOwnership(newOwner);
        
        assertEq(token.owner(), newOwner);
    }
    
    function test_UnauthorizedOwnershipTransfer() public {
        vm.prank(user1);
        vm.expectRevert(AccessToken.Unauthorized.selector);
        token.transferOwnership(user2);
    }
    
    function testFuzz_Mint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0);
        vm.assume(amount < type(uint256).max / 2);
        
        token.mint(to, amount);
        assertEq(token.balanceOf(to), amount);
    }
}
