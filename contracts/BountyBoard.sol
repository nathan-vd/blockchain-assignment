// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Campus Bounty Platform - BountyBoard Contract
 * @author Ankur Lohachab
 * @notice Main contract for managing academic bounties with token escrow and reputation badges
 * @dev Integrates with BountyToken (ERC-20) for payments and ReputationNFT (ERC-721) for skill badges
 *
 * Project: Lab assignment for Introduction to Blockchains, DACS
 * Institution: Maastricht University
 */

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function issueBadge(address student, uint8 category, string memory achievement) external returns (uint256);
    function getCategoryCount(address student, uint8 category) external view returns (uint256);
}

/**
 * @title BountyBoard
 * @dev Manages the complete lifecycle of academic bounties from creation to completion
 * Implements escrow mechanism for trustless transactions and automatic badge issuance
 */
contract BountyBoard {
    IERC20 public bountyToken;
    IERC721 public reputationNFT;
    address public owner;
    
    enum Category { Math, Programming, Writing, Science, Language }
    enum Status { Open, Claimed, Submitted, Completed, Cancelled }
    
    struct Bounty {
        uint256 id;
        address requester;
        address helper;
        string description;
        uint256 reward;
        Category category;
        Status status;
        uint256 createdAt;
        string submissionUrl;
    }
    
    uint256 public nextBountyId = 1;
    mapping(uint256 => Bounty) public bounties;
    mapping(address => uint256[]) public userBounties;
    mapping(address => uint256[]) public helperBounties;
    
    event BountyCreated(uint256 indexed bountyId, address indexed requester, uint256 reward, Category category);
    event BountyClaimed(uint256 indexed bountyId, address indexed helper);
    event BountySubmitted(uint256 indexed bountyId, string submissionUrl);
    event BountyCompleted(uint256 indexed bountyId, address indexed helper, uint256 reward);
    event BountyCancelled(uint256 indexed bountyId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor(address _tokenAddress, address _nftAddress) {
        bountyToken = IERC20(_tokenAddress);
        reputationNFT = IERC721(_nftAddress);
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new bounty
     */
    function createBounty(
        string memory description,
        uint256 reward,
        Category category
    ) public returns (uint256) {
        require(bytes(description).length > 0, "Description required");
        require(reward > 0, "Reward must be greater than 0");
        
        // Transfer tokens from requester to this contract (escrow)
        require(
            bountyToken.transferFrom(msg.sender, address(this), reward),
            "Token transfer failed"
        );
        
        uint256 bountyId = nextBountyId++;
        
        bounties[bountyId] = Bounty({
            id: bountyId,
            requester: msg.sender,
            helper: address(0),
            description: description,
            reward: reward,
            category: category,
            status: Status.Open,
            createdAt: block.timestamp,
            submissionUrl: ""
        });
        
        userBounties[msg.sender].push(bountyId);
        
        emit BountyCreated(bountyId, msg.sender, reward, category);
        
        return bountyId;
    }
    
    /**
     * @dev Claim an open bounty
     */
    function claimBounty(uint256 bountyId) public {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == Status.Open, "Bounty not open");
        require(bounty.requester != msg.sender, "Cannot claim own bounty");
        
        bounty.helper = msg.sender;
        bounty.status = Status.Claimed;
        
        helperBounties[msg.sender].push(bountyId);
        
        emit BountyClaimed(bountyId, msg.sender);
    }
    
    /**
     * @dev Submit solution for a claimed bounty
     */
    function submitSolution(uint256 bountyId, string memory submissionUrl) public {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.helper == msg.sender, "Not the assigned helper");
        require(bounty.status == Status.Claimed, "Bounty not in claimed state");
        require(bytes(submissionUrl).length > 0, "Submission URL required");
        
        bounty.submissionUrl = submissionUrl;
        bounty.status = Status.Submitted;
        
        emit BountySubmitted(bountyId, submissionUrl);
    }
    
    /**
     * @dev Approve solution and release payment
     */
    function approveSolution(uint256 bountyId) public {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.requester == msg.sender, "Not the requester");
        require(bounty.status == Status.Submitted, "No solution submitted");
        
        bounty.status = Status.Completed;
        
        // Release payment to helper
        require(
            bountyToken.transfer(bounty.helper, bounty.reward),
            "Payment transfer failed"
        );
        
        // Issue reputation badge
        string memory achievement = string(abi.encodePacked(
            "Completed bounty: ",
            bounty.description
        ));
        
        reputationNFT.issueBadge(
            bounty.helper,
            uint8(bounty.category),
            achievement
        );
        
        emit BountyCompleted(bountyId, bounty.helper, bounty.reward);
    }
    
    /**
     * @dev Reject solution and return to claimed state
     */
    function rejectSolution(uint256 bountyId, string memory reason) public {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.requester == msg.sender, "Not the requester");
        require(bounty.status == Status.Submitted, "No solution submitted");
        require(bytes(reason).length > 0, "Rejection reason required");
        
        bounty.status = Status.Claimed;
        bounty.submissionUrl = "";
    }
    
    /**
     * @dev Cancel bounty and refund requester
     */
    function cancelBounty(uint256 bountyId) public {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.requester == msg.sender, "Not the requester");
        require(bounty.status == Status.Open, "Can only cancel open bounties");
        
        bounty.status = Status.Cancelled;
        
        // Refund tokens to requester
        require(
            bountyToken.transfer(bounty.requester, bounty.reward),
            "Refund transfer failed"
        );
        
        emit BountyCancelled(bountyId);
    }
    
    /**
     * @dev Get bounty details
     */
    function getBounty(uint256 bountyId) public view returns (
        address requester,
        address helper,
        string memory description,
        uint256 reward,
        Category category,
        Status status,
        string memory submissionUrl
    ) {
        Bounty memory bounty = bounties[bountyId];
        return (
            bounty.requester,
            bounty.helper,
            bounty.description,
            bounty.reward,
            bounty.category,
            bounty.status,
            bounty.submissionUrl
        );
    }
    
    /**
     * @dev Get all bounties created by a user
     */
    function getUserBounties(address user) public view returns (uint256[] memory) {
        return userBounties[user];
    }
    
    /**
     * @dev Get all bounties claimed by a helper
     */
    function getHelperBounties(address helper) public view returns (uint256[] memory) {
        return helperBounties[helper];
    }
    
    /**
     * @dev Get all open bounties
     */
    function getOpenBounties() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextBountyId; i++) {
            if (bounties[i].status == Status.Open) {
                count++;
            }
        }
        
        uint256[] memory openBounties = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextBountyId; i++) {
            if (bounties[i].status == Status.Open) {
                openBounties[index] = i;
                index++;
            }
        }
        
        return openBounties;
    }
    
    /**
     * @dev Get contract token balance (total escrow)
     */
    function getEscrowBalance() public view returns (uint256) {
        return bountyToken.balanceOf(address(this));
    }
}
