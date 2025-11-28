// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title AccessToken
/// @notice ERC-20 Token: N tokens per consent
contract AccessToken {
    string public constant name = "Access Credit";
    string public constant symbol = "ACC";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount);

    error Unauthorized();
    error InsufficientBalance();
    error InsufficientAllowance();
    error InvalidAddress();
    error InvalidAmount();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Transfer tokens to another address
    /// @param to Recipient address
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transfer(address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert InvalidAddress();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approve spender to transfer tokens on behalf of holder
    /// @param spender Address authorized to spend
    /// @param amount Maximum amount authorized
    /// @return success True if approval succeeded
    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert InvalidAddress();

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another using allowance
    /// @param from Source address
    /// @param to Destination address
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert InvalidAddress();
        if (balanceOf[from] < amount) revert InsufficientBalance();
        if (allowance[from][msg.sender] < amount) revert InsufficientAllowance();

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Mint new tokens (only callable by owner/platform)
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Minted(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /// @notice Reward user with tokens for granting consent
    /// @param to User receiving reward
    /// @param amount Amount to reward
    function rewardConsent(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Minted(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /// @notice Transfer ownership to a new address
    /// @param newOwner New owner address
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        owner = newOwner;
    }
}
