// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./IdentityManager.sol";
import "./ConsentManager.sol";
import "./AuditLog.sol";
import "./AccessToken.sol";

/// @title DataSharing
/// @notice Manages: Permission validation, Data access coordination
contract DataSharing {
    IdentityManager public identityContract;
    ConsentManager public consentManager;
    AuditLog public auditLog;
    AccessToken public accessToken;

    // Token reward per consent grant (18 decimals)
    uint256 public constant CONSENT_REWARD = 10 * 10**18; // 10 tokens

    // Pending access requests
    struct AccessRequest {
        address requester;
        address user;
        ConsentManager.DataType[] attributes;
        uint256 timestamp;
        bool active;
    }

    // Request ID counter
    uint256 public requestCounter;
    
    // Mapping from request ID to access request
    mapping(uint256 => AccessRequest) public accessRequests;
    
    // Mapping from user => requester => request IDs
    mapping(address => mapping(address => uint256[])) public userRequesterRequests;
    
    // Mapping from user => pending request IDs
    mapping(address => uint256[]) public userPendingRequests;

    event AccessRequested(
        uint256 indexed requestId,
        address indexed requester,
        address indexed user,
        ConsentManager.DataType[] attributes
    );
    
    event AccessRequestFulfilled(
        uint256 indexed requestId,
        uint256 indexed consentId
    );
    
    event AccessRequestCancelled(uint256 indexed requestId);
    
    event DataAccessAttempted(
        address indexed requester,
        address indexed user,
        uint256 indexed consentId,
        ConsentManager.DataType attribute,
        bool success
    );

    error NotRegistered();
    error InvalidRequest();
    error ConsentNotValid();
    error Unauthorized();
    error RequestNotActive();
    error AttributeNotAuthorized();

    constructor() {
        // Deploy all contracts
        identityContract = new IdentityManager();
        accessToken = new AccessToken();
        consentManager = new ConsentManager(address(identityContract));
        auditLog = new AuditLog();
    }

    /// @notice Register as a new user
    /// @param hashedUUID Hash of user's unique identifier
    function registerUser(bytes32 hashedUUID) external {
        identityContract.registerUser(hashedUUID);
    }

    /// @notice Request access to a user's data
    /// @param user User whose data is being requested
    /// @param attributes Array of attributes being requested
    /// @return requestId The ID of the access request
    function requestAccess(
        address user,
        ConsentManager.DataType[] calldata attributes
    ) external returns (uint256) {
        // Verify both parties are registered
        if (!identityContract.isRegistered(msg.sender)) revert NotRegistered();
        if (!identityContract.isRegistered(user)) revert NotRegistered();
        if (attributes.length == 0) revert InvalidRequest();

        uint256 requestId = requestCounter++;

        accessRequests[requestId] = AccessRequest({
            requester: msg.sender,
            user: user,
            attributes: attributes,
            timestamp: block.timestamp,
            active: true
        });

        userRequesterRequests[user][msg.sender].push(requestId);
        userPendingRequests[user].push(requestId);

        emit AccessRequested(requestId, msg.sender, user, attributes);

        return requestId;
    }

    /// @notice Grant consent in response to an access request
    /// @param requestId The access request ID
    /// @param durationDays Duration of consent in days
    /// @return consentId The ID of the granted consent
    function grantConsentForRequest(
        uint256 requestId,
        uint256 durationDays
    ) external returns (uint256) {
        AccessRequest storage request = accessRequests[requestId];
        
        if (!request.active) revert RequestNotActive();
        if (request.user != msg.sender) revert Unauthorized();

        // Grant consent via ConsentManager
        uint256 consentId = consentManager.grantConsent(
            request.requester,
            request.attributes,
            durationDays
        );

        // Mark request as fulfilled
        request.active = false;

        // Reward user with tokens
        accessToken.rewardConsent(msg.sender, CONSENT_REWARD);
        
        // Log consent grant
        uint8[] memory attrArray = new uint8[](request.attributes.length);
        for (uint256 i = 0; i < request.attributes.length; i++) {
            attrArray[i] = uint8(request.attributes[i]);
        }
        auditLog.logConsent(consentId, msg.sender, request.requester, attrArray, "GRANTED");

        emit AccessRequestFulfilled(requestId, consentId);

        return consentId;
    }

    /// @notice Grant consent directly (without prior request)
    /// @param requester Address to grant consent to
    /// @param attributes Array of attributes to grant access to
    /// @param durationDays Duration of consent in days
    /// @return consentId The ID of the granted consent
    function grantConsent(
        address requester,
        ConsentManager.DataType[] calldata attributes,
        uint256 durationDays
    ) external returns (uint256) {
        if (!identityContract.isRegistered(msg.sender)) revert NotRegistered();
        if (!identityContract.isRegistered(requester)) revert NotRegistered();

        // Grant consent via ConsentManager
        uint256 consentId = consentManager.grantConsent(
            requester,
            attributes,
            durationDays
        );

        // Reward user with tokens
        accessToken.rewardConsent(msg.sender, CONSENT_REWARD);
        
        // Log consent grant
        uint8[] memory attrArray = new uint8[](attributes.length);
        for (uint256 i = 0; i < attributes.length; i++) {
            attrArray[i] = uint8(attributes[i]);
        }
        auditLog.logConsent(consentId, msg.sender, requester, attrArray, "GRANTED");

        return consentId;
    }

    /// @notice Revoke a consent
    /// @param consentId The consent ID to revoke
    function revokeConsent(uint256 consentId) external {
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        
        consentManager.revokeConsent(consentId);
        
        // Log consent revocation
        uint8[] memory attrArray = new uint8[](consent.attributes.length);
        for (uint256 i = 0; i < consent.attributes.length; i++) {
            attrArray[i] = uint8(consent.attributes[i]);
        }
        auditLog.logConsent(consentId, consent.owner, consent.requester, attrArray, "REVOKED");
    }

    /// @notice Verify if a specific attribute is authorized for access
    /// @param user User address
    /// @param requester Requester address
    /// @param attribute Attribute to verify
    /// @return authorized True if attribute access is authorized
    function verifyAttribute(
        address user,
        address requester,
        ConsentManager.DataType attribute
    ) public view returns (bool) {
        return consentManager.hasValidConsent(user, requester, attribute);
    }

    /// @notice Check if access permission exists for given parameters
    /// @param user User address
    /// @param requester Requester address
    /// @param consentId Consent ID
    /// @param attribute Attribute to check
    /// @return hasPermission True if permission exists
    function checkAccessPermission(
        address user,
        address requester,
        uint256 consentId,
        ConsentManager.DataType attribute
    ) public view returns (bool) {
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        
        // Verify basic consent validity
        if (consent.owner != user) return false;
        if (consent.requester != requester) return false;
        if (!consentManager.isConsentValid(consentId)) return false;
        if (!consentManager.isConsentValidForAttribute(consentId, attribute)) return false;
        
        return true;
    }

    /// @notice Access user data with valid consent
    /// @param user User whose data is being accessed
    /// @param consentId Consent ID to use for access
    /// @param attribute Specific attribute being accessed
    /// @return success True if access was granted
    function accessData(
        address user,
        uint256 consentId,
        ConsentManager.DataType attribute
    ) external returns (bool) {
        ConsentManager.Consent memory consent = consentManager.getConsent(consentId);
        
        // Verify requester matches consent
        if (consent.requester != msg.sender) {
            auditLog.logAccess(
                consentId,
                msg.sender,
                user,
                uint8(attribute),
                AuditLog.AccessResult.Denied,
                "Requester mismatch"
            );
            
            emit DataAccessAttempted(msg.sender, user, consentId, attribute, false);
            return false;
        }

        // Verify consent is valid
        if (!consentManager.isConsentValid(consentId)) {
            AuditLog.AccessResult result;
            string memory reason;
            
            if (consent.status == ConsentManager.Status.Revoked) {
                result = AuditLog.AccessResult.Revoked;
                reason = "Consent revoked";
            } else if (consent.status == ConsentManager.Status.Expired) {
                result = AuditLog.AccessResult.Expired;
                reason = "Consent expired";
            } else {
                result = AuditLog.AccessResult.InvalidConsent;
                reason = "Invalid consent";
            }
            
            auditLog.logAccess(
                consentId,
                msg.sender,
                user,
                uint8(attribute),
                result,
                reason
            );
            
            emit DataAccessAttempted(msg.sender, user, consentId, attribute, false);
            return false;
        }

        // Verify attribute is covered by consent
        if (!consentManager.isConsentValidForAttribute(consentId, attribute)) {
            auditLog.logAccess(
                consentId,
                msg.sender,
                user,
                uint8(attribute),
                AuditLog.AccessResult.Denied,
                "Attribute not in consent"
            );
            
            emit DataAccessAttempted(msg.sender, user, consentId, attribute, false);
            return false;
        }

        // Log successful access
        auditLog.logAccess(
            consentId,
            msg.sender,
            user,
            uint8(attribute),
            AuditLog.AccessResult.Success,
            "Access granted"
        );
        
        emit DataAccessAttempted(msg.sender, user, consentId, attribute, true);
        
        // In a real implementation, this would trigger off-chain data delivery
        return true;
    }

    /// @notice Cancel an active access request
    /// @param requestId The request ID to cancel
    function cancelAccessRequest(uint256 requestId) external {
        AccessRequest storage request = accessRequests[requestId];
        
        if (!request.active) revert RequestNotActive();
        if (request.requester != msg.sender && request.user != msg.sender) {
            revert Unauthorized();
        }

        request.active = false;
        
        emit AccessRequestCancelled(requestId);
    }

    /// @notice Get pending access requests for a user
    /// @param user User address
    /// @return requestIds Array of pending request IDs
    function getPendingRequests(address user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory allRequests = userPendingRequests[user];
        uint256 activeCount = 0;
        
        // Count active requests
        for (uint256 i = 0; i < allRequests.length; i++) {
            if (accessRequests[allRequests[i]].active) {
                activeCount++;
            }
        }
        
        // Collect active requests
        uint256[] memory activeRequests = new uint256[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < allRequests.length; i++) {
            if (accessRequests[allRequests[i]].active) {
                activeRequests[currentIndex] = allRequests[i];
                currentIndex++;
            }
        }
        
        return activeRequests;
    }

    /// @notice Get access request details
    /// @param requestId Request ID
    /// @return request The access request details
    function getAccessRequest(uint256 requestId) 
        external 
        view 
        returns (AccessRequest memory) 
    {
        return accessRequests[requestId];
    }

    /// @notice Get user's audit logs
    /// @param user User address
    /// @return logs Array of access events
    function getUserAuditLogs(address user) 
        external 
        view 
        returns (AuditLog.AccessEvent[] memory) 
    {
        return auditLog.getUserAccessLogs(user);
    }

    /// @notice Verify credit score and submit to blockchain (Data Submitter only)
    /// @param user User whose credit is being verified
    /// @param creditScore Credit score to submit
    /// @param signature Signature attesting to verification
    function submitCreditVerification(
        address user,
        uint256 creditScore,
        bytes calldata signature
    ) external {
        identityContract.updateCreditData(user, creditScore, signature);
    }

    /// @notice Authorize a data submitter (Admin only)
    /// @param submitter Address to authorize
    /// @param authorized True to authorize, false to revoke
    function authorizeDataSubmitter(address submitter, bool authorized) external {
        // Only identity contract admin can call this
        identityContract.setDataSubmitterAuthorization(submitter, authorized);
    }

    /// @notice Get identity contract address
    function getIdentityContract() external view returns (address) {
        return address(identityContract);
    }

    /// @notice Get consent manager contract address
    function getConsentManager() external view returns (address) {
        return address(consentManager);
    }

    /// @notice Get audit log contract address
    function getAuditLog() external view returns (address) {
        return address(auditLog);
    }

    /// @notice Get access token contract address
    function getAccessToken() external view returns (address) {
        return address(accessToken);
    }
}
