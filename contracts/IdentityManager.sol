// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IdentityManager
/// @notice Stores: User address, UUID hash, Credit score, Data submitter signature
contract IdentityManager {
    struct Identity {
        bytes32 hashedUUID;
        uint256 creditScore;
        uint256 verificationTimestamp;
        address dataSubmitter;
        bytes dataSubmitterSignature;
        bool exists;
    }

    // Mapping from user address to their identity
    mapping(address => Identity) private identities;
    
    // Mapping to track registered users
    mapping(address => bool) public isRegistered;
    
    // Mapping to track authorized data submitters (trusted oracles)
    mapping(address => bool) public authorizedDataSubmitters;
    
    address public admin;
    uint256 public totalUsers;

    event UserRegistered(
        address indexed user,
        bytes32 hashedUUID,
        uint256 timestamp
    );
    
    event CreditVerified(
        address indexed user,
        address indexed dataSubmitter,
        uint256 creditScore,
        uint256 timestamp,
        bytes signature
    );
    
    event DataSubmitterAuthorized(address indexed submitter, bool authorized);

    error AlreadyRegistered();
    error NotRegistered();
    error UnauthorizedDataSubmitter();
    error InvalidCreditScore();
    error InvalidSignature();
    error Unauthorized();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    modifier onlyRegistered() {
        if (!isRegistered[msg.sender]) revert NotRegistered();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Register a new user with hashed UUID
    /// @param hashedUUID Hash of user's unique identifier
    function registerUser(bytes32 hashedUUID) external {
        if (isRegistered[msg.sender]) revert AlreadyRegistered();

        identities[msg.sender] = Identity({
            hashedUUID: hashedUUID,
            creditScore: 0,
            verificationTimestamp: 0,
            dataSubmitter: address(0),
            dataSubmitterSignature: "",
            exists: true
        });

        isRegistered[msg.sender] = true;
        totalUsers++;

        emit UserRegistered(msg.sender, hashedUUID, block.timestamp);
    }

    /// @notice Update credit data for a user (Data Submitter only)
    /// @param user User address whose credit is being verified
    /// @param creditScore Credit score (300-850 typical range)
    /// @param signature Cryptographic signature attesting to verification
    function updateCreditData(
        address user,
        uint256 creditScore,
        bytes calldata signature
    ) external {
        if (!authorizedDataSubmitters[msg.sender]) revert UnauthorizedDataSubmitter();
        if (!isRegistered[user]) revert NotRegistered();
        if (creditScore < 300 || creditScore > 850) revert InvalidCreditScore();
        if (signature.length == 0) revert InvalidSignature();

        Identity storage identity = identities[user];
        identity.creditScore = creditScore;
        identity.verificationTimestamp = block.timestamp;
        identity.dataSubmitter = msg.sender;
        identity.dataSubmitterSignature = signature;

        emit CreditVerified(
            user,
            msg.sender,
            creditScore,
            block.timestamp,
            signature
        );
    }

    /// @notice Get user information
    /// @param user User address to query
    /// @return hashedUUID The hashed UUID
    /// @return creditScore The credit score
    /// @return verificationTimestamp When verification occurred
    /// @return dataSubmitter Address of the data submitter
    function getUserInfo(address user) 
        external 
        view 
        returns (
            bytes32 hashedUUID,
            uint256 creditScore,
            uint256 verificationTimestamp,
            address dataSubmitter
        ) 
    {
        if (!isRegistered[user]) revert NotRegistered();
        Identity memory identity = identities[user];
        return (
            identity.hashedUUID,
            identity.creditScore,
            identity.verificationTimestamp,
            identity.dataSubmitter
        );
    }

    /// @notice Get identity information for a user
    /// @param user User address to query
    /// @return identity The user's identity struct
    function getIdentity(address user) external view returns (Identity memory) {
        if (!isRegistered[user]) revert NotRegistered();
        return identities[user];
    }

    /// @notice Get credit score for a user
    /// @param user User address to query
    /// @return creditScore The user's credit score
    function getCreditScore(address user) external view returns (uint256) {
        if (!isRegistered[user]) revert NotRegistered();
        return identities[user].creditScore;
    }

    /// @notice Get verification details for a user
    /// @param user User address to query
    /// @return timestamp When verification occurred
    /// @return submitter Address of the data submitter
    function getVerificationDetails(address user) 
        external 
        view 
        returns (uint256 timestamp, address submitter) 
    {
        if (!isRegistered[user]) revert NotRegistered();
        Identity memory identity = identities[user];
        return (identity.verificationTimestamp, identity.dataSubmitter);
    }

    /// @notice Verify if UUID hash matches registered hash
    /// @param user User address to verify
    /// @param hashedUUID Hash to check against
    /// @return matches True if hashes match
    function verifyUserData(address user, bytes32 hashedUUID) external view returns (bool) {
        if (!isRegistered[user]) return false;
        return identities[user].hashedUUID == hashedUUID;
    }

    /// @notice Verify if UUID hash matches registered hash (alias for compatibility)
    /// @param user User address to verify
    /// @param hashedUUID Hash to check against
    /// @return matches True if hashes match
    function verifyUUID(address user, bytes32 hashedUUID) external view returns (bool) {
        if (!isRegistered[user]) return false;
        return identities[user].hashedUUID == hashedUUID;
    }

    /// @notice Authorize or deauthorize a data submitter
    /// @param submitter Address to authorize/deauthorize
    /// @param authorized True to authorize, false to revoke
    function setDataSubmitterAuthorization(address submitter, bool authorized) 
        external 
        onlyAdmin 
    {
        authorizedDataSubmitters[submitter] = authorized;
        emit DataSubmitterAuthorized(submitter, authorized);
    }

    /// @notice Transfer admin rights
    /// @param newAdmin New admin address
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert Unauthorized();
        admin = newAdmin;
    }
}
