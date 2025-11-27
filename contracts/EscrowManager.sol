// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title EscrowManager
 * @dev Advanced escrow with dispute resolution
 */
contract EscrowManager {
    IERC20 public token;
    address public owner;
    address public arbiter;
    bool public paused;
    
    enum EscrowStatus { Active, Released, Refunded, Disputed }
    
    struct Escrow {
        uint256 id;
        address depositor;
        address beneficiary;
        uint256 amount;
        uint256 createdAt;
        uint256 timeoutDuration;
        EscrowStatus status;
        string purpose;
    }
    
    uint256 public nextEscrowId = 1;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public depositorEscrows;
    mapping(address => uint256[]) public beneficiaryEscrows;
    
    event EscrowCreated(uint256 indexed escrowId, address indexed depositor, address indexed beneficiary, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId, address indexed beneficiary, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed depositor, uint256 amount);
    event EscrowDisputed(uint256 indexed escrowId);
    event DisputeResolved(uint256 indexed escrowId, address winner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not the arbiter");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        owner = msg.sender;
        arbiter = msg.sender;
    }
    
    /**
     * @dev Create new escrow
     */
    function createEscrow(
        address beneficiary,
        uint256 amount,
        uint256 timeoutDuration,
        string memory purpose
    ) public whenNotPaused returns (uint256) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount > 0, "Amount must be greater than 0");
        require(timeoutDuration >= 1 days, "Timeout must be at least 1 day");
        
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        
        uint256 escrowId = nextEscrowId++;
        
        escrows[escrowId] = Escrow({
            id: escrowId,
            depositor: msg.sender,
            beneficiary: beneficiary,
            amount: amount,
            createdAt: block.timestamp,
            timeoutDuration: timeoutDuration,
            status: EscrowStatus.Active,
            purpose: purpose
        });
        
        depositorEscrows[msg.sender].push(escrowId);
        beneficiaryEscrows[beneficiary].push(escrowId);
        
        emit EscrowCreated(escrowId, msg.sender, beneficiary, amount);
        
        return escrowId;
    }
    
    /**
     * @dev Release escrow to beneficiary
     */
    function releaseEscrow(uint256 escrowId) public whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.depositor == msg.sender, "Not the depositor");
        require(escrow.status == EscrowStatus.Active, "Escrow not active");
        
        escrow.status = EscrowStatus.Released;
        
        require(
            token.transfer(escrow.beneficiary, escrow.amount),
            "Token transfer failed"
        );
        
        emit EscrowReleased(escrowId, escrow.beneficiary, escrow.amount);
    }
    
    /**
     * @dev Refund escrow to depositor
     */
    function refundEscrow(uint256 escrowId) public whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(
            escrow.depositor == msg.sender || escrow.beneficiary == msg.sender,
            "Not authorized"
        );
        require(escrow.status == EscrowStatus.Active, "Escrow not active");
        
        escrow.status = EscrowStatus.Refunded;
        
        require(
            token.transfer(escrow.depositor, escrow.amount),
            "Token transfer failed"
        );
        
        emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount);
    }
    
    /**
     * @dev Claim refund after timeout
     */
    function claimTimeout(uint256 escrowId) public whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.depositor == msg.sender, "Not the depositor");
        require(escrow.status == EscrowStatus.Active, "Escrow not active");
        require(
            block.timestamp >= escrow.createdAt + escrow.timeoutDuration,
            "Timeout not reached"
        );
        
        escrow.status = EscrowStatus.Refunded;
        
        require(
            token.transfer(escrow.depositor, escrow.amount),
            "Token transfer failed"
        );
        
        emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount);
    }
    
    /**
     * @dev Raise dispute
     */
    function raiseDispute(uint256 escrowId) public {
        Escrow storage escrow = escrows[escrowId];
        require(
            escrow.depositor == msg.sender || escrow.beneficiary == msg.sender,
            "Not a party to this escrow"
        );
        require(escrow.status == EscrowStatus.Active, "Escrow not active");
        
        escrow.status = EscrowStatus.Disputed;
        
        emit EscrowDisputed(escrowId);
    }
    
    /**
     * @dev Resolve dispute (arbiter only)
     */
    function resolveDispute(uint256 escrowId, bool releaseToBeneficiary) public onlyArbiter {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == EscrowStatus.Disputed, "Not disputed");
        
        address winner;
        
        if (releaseToBeneficiary) {
            escrow.status = EscrowStatus.Released;
            winner = escrow.beneficiary;
            require(
                token.transfer(escrow.beneficiary, escrow.amount),
                "Token transfer failed"
            );
            emit EscrowReleased(escrowId, escrow.beneficiary, escrow.amount);
        } else {
            escrow.status = EscrowStatus.Refunded;
            winner = escrow.depositor;
            require(
                token.transfer(escrow.depositor, escrow.amount),
                "Token transfer failed"
            );
            emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount);
        }
        
        emit DisputeResolved(escrowId, winner);
    }
    
    /**
     * @dev Get escrow details
     */
    function getEscrow(uint256 escrowId) public view returns (
        address depositor,
        address beneficiary,
        uint256 amount,
        EscrowStatus status,
        uint256 createdAt,
        uint256 timeoutDuration,
        string memory purpose
    ) {
        Escrow memory escrow = escrows[escrowId];
        return (
            escrow.depositor,
            escrow.beneficiary,
            escrow.amount,
            escrow.status,
            escrow.createdAt,
            escrow.timeoutDuration,
            escrow.purpose
        );
    }
    
    /**
     * @dev Get escrows by depositor
     */
    function getDepositorEscrows(address depositor) public view returns (uint256[] memory) {
        return depositorEscrows[depositor];
    }
    
    /**
     * @dev Get escrows by beneficiary
     */
    function getBeneficiaryEscrows(address beneficiary) public view returns (uint256[] memory) {
        return beneficiaryEscrows[beneficiary];
    }
    
    /**
     * @dev Set arbiter
     */
    function setArbiter(address newArbiter) public onlyOwner {
        require(newArbiter != address(0), "Invalid arbiter address");
        arbiter = newArbiter;
    }
    
    /**
     * @dev Pause contract
     */
    function pause() public onlyOwner {
        paused = true;
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() public onlyOwner {
        paused = false;
    }
}
