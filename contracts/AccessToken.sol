// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title AccessToken
/// @notice Abstract incentive token surface
abstract contract AccessToken {
    string public constant name = "Access Credit";
    string public constant symbol = "ACC";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);

    function transfer(address to, uint256 amount) external virtual returns (bool);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transferFrom(address from, address to, uint256 amount) external virtual returns (bool);

    function mint(address to, uint256 amount) external virtual;
}
