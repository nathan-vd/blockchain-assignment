// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Campus Bounty Platform - ReputationNFT Contract
 * @author Ankur Lohachab
 * @notice Soul-bound NFT badges representing student skills and achievements
 * @dev ERC-721 implementation with non-transferable tokens (soul-bound)
 * Badges are automatically issued when bounties are completed
 *
 * Project: Lab assignment for Introduction to Blockchains, DACS
 * Institution: Maastricht University
 */

/**
 * @title ReputationNFT
 * @dev Campus Reputation Badge - Soul-bound ERC-721 NFTs for student skill verification
 */
contract ReputationNFT {
    string public name = "Campus Reputation Badge";
    string public symbol = "BADGE";
    
    address public owner;
    mapping(address => bool) public isIssuer;
    
    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    
    // Badge categories
    enum Category { Math, Programming, Writing, Science, Language }
    
    struct Badge {
        uint256 id;
        address student;
        Category category;
        uint256 issuedDate;
        string achievement;
    }
    
    mapping(uint256 => Badge) public badges;
    mapping(address => uint256[]) public studentBadges;
    mapping(address => mapping(Category => uint256)) public categoryCount;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event BadgeIssued(uint256 indexed tokenId, address indexed student, Category category);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier onlyIssuer() {
        require(isIssuer[msg.sender], "Not authorized issuer");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isIssuer[msg.sender] = true;
    }
    
    /**
     * @dev Issue a badge to a student
     */
    function issueBadge(
        address student,
        Category category,
        string memory achievement
    ) public onlyIssuer returns (uint256) {
        require(student != address(0), "Invalid student address");
        
        uint256 tokenId = nextTokenId++;
        
        ownerOf[tokenId] = student;
        balanceOf[student]++;
        
        badges[tokenId] = Badge({
            id: tokenId,
            student: student,
            category: category,
            issuedDate: block.timestamp,
            achievement: achievement
        });
        
        studentBadges[student].push(tokenId);
        categoryCount[student][category]++;
        
        emit Transfer(address(0), student, tokenId);
        emit BadgeIssued(tokenId, student, category);
        
        return tokenId;
    }
    
    /**
     * @dev Get badge details
     */
    function getBadge(uint256 tokenId) public view returns (
        address student,
        Category category,
        uint256 issuedDate,
        string memory achievement
    ) {
        require(ownerOf[tokenId] != address(0), "Badge does not exist");
        Badge memory badge = badges[tokenId];
        return (badge.student, badge.category, badge.issuedDate, badge.achievement);
    }
    
    /**
     * @dev Get all badges for a student
     */
    function getStudentBadges(address student) public view returns (uint256[] memory) {
        return studentBadges[student];
    }
    
    /**
     * @dev Get number of badges in a category for a student
     */
    function getCategoryCount(address student, Category category) public view returns (uint256) {
        return categoryCount[student][category];
    }
    
    /**
     * @dev Check if student has badge in category
     */
    function hasCategoryBadge(address student, Category category) public view returns (bool) {
        return categoryCount[student][category] > 0;
    }
    
    /**
     * @dev Add authorized issuer
     */
    function addIssuer(address issuer) public onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        isIssuer[issuer] = true;
    }
    
    /**
     * @dev Remove authorized issuer
     */
    function removeIssuer(address issuer) public onlyOwner {
        isIssuer[issuer] = false;
    }
    
    /**
     * @dev Total supply of badges
     */
    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }
    
    /**
     * @dev Transfer badge (disabled - badges are soul-bound)
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure {
        revert("Badges are non-transferable");
    }
    
    /**
     * @dev Safe transfer (also disabled)
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure {
        revert("Badges are non-transferable");
    }
}
