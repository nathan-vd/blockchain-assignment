// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title AccessToken
/// @notice Simple ERC-20 token used to reward consent grants
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
    event Mint(address indexed to, uint256 amount);
    event OwnerUpdated(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not token owner");
        _;
    }

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner required");
        owner = initialOwner;
    }

    /// @notice Transfer tokens to another address
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero");
        require(balanceOf[msg.sender] >= amount, "Balance too low");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approve a spender to transfer tokens
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Approve to zero");

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfer tokens using an allowance
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero");
        require(balanceOf[from] >= amount, "Balance too low");
        require(allowance[from][msg.sender] >= amount, "Allowance too low");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Mint new tokens (platform controlled)
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Mint to zero");
        require(amount > 0, "Mint zero");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /// @notice Update token owner (e.g. during contract upgrades)
    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner required");
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }
}
