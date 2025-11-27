// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Campus Bounty Platform - BountyToken Contract
 * @author Ankur Lohachab
 * @notice ERC-20 token used for bounty rewards in the Campus Bounty Platform
 * @dev Standard ERC-20 implementation with mint and airdrop functionality
 *
 * Project: Lab assignment for Introduction to Blockchains, DACS
 * Institution: Maastricht University
 */

/**
 * @title BountyToken
 * @dev Campus Bounty Token (CBT) - ERC-20 token for bounty payments
 */
contract BountyToken {
    string public name = "Campus Bounty Token";
    string public symbol = "CBT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10**decimals;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    /**
     * @dev Transfer tokens
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Approve spender
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfer from allowance
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Mint new tokens (owner only)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
    
    /**
     * @dev Airdrop tokens to new students
     */
    function airdrop(address[] memory students, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < students.length; i++) {
            require(students[i] != address(0), "Invalid student address");
            mint(students[i], amount);
        }
    }
    
    /**
     * @dev Burn tokens
     */
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }
}
