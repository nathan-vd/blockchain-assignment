// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IdentityManager
/// @notice Stores hashed identities and verified credit information
contract IdentityManager {
    struct Identity {
        bytes32 hashedUUID;
        uint256 creditScore;
        uint256 verificationTimestamp;
        address dataSubmitter;
        bytes submitterSignature;
        bool exists;
    }

    mapping(address => Identity) private identities;
    mapping(address => bool) public authorizedSubmitters;

    address public admin;
    uint256 public totalUsers;

    event UserRegistered(address indexed user, bytes32 hashedUUID, uint256 timestamp);
    event CreditVerified(address indexed user, address indexed submitter, uint256 creditScore, uint256 timestamp);
    event SubmitterUpdated(address indexed submitter, bool authorized);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not identity admin");
        _;
    }

    constructor(address adminAddress) {
        require(adminAddress != address(0), "Admin required");
        admin = adminAddress;
    }

    /// @notice Register a new user
    function register(address user, bytes32 hashedUUID) external onlyAdmin {
        require(user != address(0), "Invalid user");
        require(!identities[user].exists, "Already registered");

        identities[user] = Identity({
            hashedUUID: hashedUUID,
            creditScore: 0,
            verificationTimestamp: 0,
            dataSubmitter: address(0),
            submitterSignature: "",
            exists: true
        });

        totalUsers += 1;

        emit UserRegistered(user, hashedUUID, block.timestamp);
    }

    /// @notice Authorize a trusted financial data submitter
    function setDataSubmitter(address submitter, bool authorized) external onlyAdmin {
        require(submitter != address(0), "Invalid submitter");
        authorizedSubmitters[submitter] = authorized;
        emit SubmitterUpdated(submitter, authorized);
    }

    /// @notice Platform records credit data after verifying submitter authorization
    function updateCreditData(
        address user,
        uint256 creditScore,
        bytes calldata signature,
        address submitter
    ) external onlyAdmin {
        require(submitter != address(0), "Invalid submitter");
        require(authorizedSubmitters[submitter], "Not data submitter");
        require(identities[user].exists, "User not registered");
        require(creditScore >= 300 && creditScore <= 850, "Invalid credit score");
        require(signature.length > 0, "Signature required");

        Identity storage identity = identities[user];
        identity.creditScore = creditScore;
        identity.verificationTimestamp = block.timestamp;
        identity.dataSubmitter = submitter;
        identity.submitterSignature = signature;

        emit CreditVerified(user, submitter, creditScore, block.timestamp);
    }

    /// @notice Fetch stored identity information
    function getIdentity(address user) external view returns (Identity memory) {
        require(identities[user].exists, "User not registered");
        return identities[user];
    }

    /// @notice Check if an address is registered
    function isRegistered(address user) external view returns (bool) {
        return identities[user].exists;
    }

    /// @notice Verify hashed UUID matches stored value
    function verifyUUID(address user, bytes32 hashedUUID) external view returns (bool) {
        if (!identities[user].exists) {
            return false;
        }
        return identities[user].hashedUUID == hashedUUID;
    }
}
