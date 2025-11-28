// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title AuditLog
/// @notice Records: All access attempts, Consent events, Timestamps
contract AuditLog {
    enum AccessResult {
        Success,
        Denied,
        Expired,
        Revoked,
        InvalidConsent
    }

    struct AccessEvent {
        uint256 consentId;
        address requester;
        address owner;
        uint8 dataType;
        uint256 timestamp;
        AccessResult result;
        string reason;
    }

    struct ConsentEvent {
        uint256 consentId;
        address owner;
        address requester;
        uint8[] attributes;
        uint256 timestamp;
        string eventType; // "GRANTED", "REVOKED", "EXPIRED"
    }

    // Array of all access events (immutable log)
    AccessEvent[] private accessLogs;
    
    // Array of all consent events
    ConsentEvent[] private consentLogs;
    
    // Mapping from user => their access log indices
    mapping(address => uint256[]) private userAccessLogs;
    
    // Mapping from requester => their access log indices
    mapping(address => uint256[]) private requesterAccessLogs;
    
    // Mapping from consent ID => access log indices
    mapping(uint256 => uint256[]) private consentAccessLogs;
    
    // Mapping from user => their consent log indices
    mapping(address => uint256[]) private userConsentLogs;

    address public platform;

    event AccessLogged(
        uint256 indexed logIndex,
        uint256 indexed consentId,
        address indexed requester,
        address owner,
        AccessResult result
    );
    
    event ConsentLogged(
        uint256 indexed logIndex,
        uint256 indexed consentId,
        address indexed owner,
        address requester,
        string eventType
    );

    error Unauthorized();

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    constructor() {
        platform = msg.sender;
    }

    /// @notice Log a data access attempt
    /// @param consentId The consent being used for access
    /// @param requester Address attempting access
    /// @param owner Data owner address
    /// @param dataType Type of data being accessed
    /// @param result Result of the access attempt
    /// @param reason Additional context (especially for denials)
    function logAccess(
        uint256 consentId,
        address requester,
        address owner,
        uint8 dataType,
        AccessResult result,
        string calldata reason
    ) external onlyPlatform {
        uint256 logIndex = accessLogs.length;

        AccessEvent memory accessEvent = AccessEvent({
            consentId: consentId,
            requester: requester,
            owner: owner,
            dataType: dataType,
            timestamp: block.timestamp,
            result: result,
            reason: reason
        });

        accessLogs.push(accessEvent);
        userAccessLogs[owner].push(logIndex);
        requesterAccessLogs[requester].push(logIndex);
        consentAccessLogs[consentId].push(logIndex);

        emit AccessLogged(logIndex, consentId, requester, owner, result);
    }

    /// @notice Log a consent event (grant, revoke, expire)
    /// @param consentId The consent ID
    /// @param owner Data owner address
    /// @param requester Requester address
    /// @param attributes Array of attribute types
    /// @param eventType Type of event ("GRANTED", "REVOKED", "EXPIRED")
    function logConsent(
        uint256 consentId,
        address owner,
        address requester,
        uint8[] calldata attributes,
        string calldata eventType
    ) external onlyPlatform {
        uint256 logIndex = consentLogs.length;

        ConsentEvent memory consentEvent = ConsentEvent({
            consentId: consentId,
            owner: owner,
            requester: requester,
            attributes: attributes,
            timestamp: block.timestamp,
            eventType: eventType
        });

        consentLogs.push(consentEvent);
        userConsentLogs[owner].push(logIndex);

        emit ConsentLogged(logIndex, consentId, owner, requester, eventType);
    }

    /// @notice Get a specific access log entry
    /// @param index Index of the log entry
    /// @return log The access event details
    function getLog(uint256 index) external view returns (AccessEvent memory) {
        require(index < accessLogs.length, "Invalid log index");
        return accessLogs[index];
    }

    /// @notice Get total number of access logs
    /// @return count Total log count
    function totalLogs() external view returns (uint256) {
        return accessLogs.length;
    }

    /// @notice Get all access log indices for a specific user
    /// @param user User address
    /// @return indices Array of log indices
    function getUserLogs(address user) external view returns (uint256[] memory) {
        return userAccessLogs[user];
    }

    /// @notice Get all access logs for a specific user
    /// @param user User address
    /// @return logs Array of access events
    function getUserAccessLogs(address user) external view returns (AccessEvent[] memory) {
        uint256[] memory indices = userAccessLogs[user];
        AccessEvent[] memory logs = new AccessEvent[](indices.length);
        
        for (uint256 i = 0; i < indices.length; i++) {
            logs[i] = accessLogs[indices[i]];
        }
        
        return logs;
    }

    /// @notice Get all access log indices for a specific requester
    /// @param requester Requester address
    /// @return indices Array of log indices
    function getRequesterAccessLogs(address requester) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return requesterAccessLogs[requester];
    }

    /// @notice Get all access log indices for a specific consent
    /// @param consentId Consent ID
    /// @return indices Array of log indices
    function getConsentAccessLogs(uint256 consentId) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return consentAccessLogs[consentId];
    }

    /// @notice Get all consent logs for a specific user
    /// @param user User address
    /// @return logs Array of consent events
    function getUserConsentLogs(address user) external view returns (ConsentEvent[] memory) {
        uint256[] memory indices = userConsentLogs[user];
        ConsentEvent[] memory logs = new ConsentEvent[](indices.length);
        
        for (uint256 i = 0; i < indices.length; i++) {
            logs[i] = consentLogs[indices[i]];
        }
        
        return logs;
    }

    /// @notice Get recent access logs (last N entries)
    /// @param count Number of recent logs to retrieve
    /// @return logs Array of recent access events
    function getRecentLogs(uint256 count) external view returns (AccessEvent[] memory) {
        uint256 total = accessLogs.length;
        uint256 returnCount = count > total ? total : count;
        
        AccessEvent[] memory recentLogs = new AccessEvent[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            recentLogs[i] = accessLogs[total - returnCount + i];
        }
        
        return recentLogs;
    }

    /// @notice Get access logs within a time range
    /// @param user User address (address(0) for all users)
    /// @param startTime Start timestamp
    /// @param endTime End timestamp
    /// @return logs Array of access events in time range
    function getLogsByTimeRange(
        address user,
        uint256 startTime,
        uint256 endTime
    ) external view returns (AccessEvent[] memory) {
        uint256[] memory indices;
        
        if (user == address(0)) {
            // Return all logs
            indices = new uint256[](accessLogs.length);
            for (uint256 i = 0; i < accessLogs.length; i++) {
                indices[i] = i;
            }
        } else {
            indices = userAccessLogs[user];
        }

        // Count matching logs
        uint256 matchCount = 0;
        for (uint256 i = 0; i < indices.length; i++) {
            AccessEvent memory log = accessLogs[indices[i]];
            if (log.timestamp >= startTime && log.timestamp <= endTime) {
                matchCount++;
            }
        }

        // Collect matching logs
        AccessEvent[] memory matchingLogs = new AccessEvent[](matchCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < indices.length; i++) {
            AccessEvent memory log = accessLogs[indices[i]];
            if (log.timestamp >= startTime && log.timestamp <= endTime) {
                matchingLogs[currentIndex] = log;
                currentIndex++;
            }
        }

        return matchingLogs;
    }

    /// @notice Update platform address (for migration or upgrades)
    /// @param newPlatform New platform address
    function updatePlatform(address newPlatform) external onlyPlatform {
        require(newPlatform != address(0), "Invalid platform address");
        platform = newPlatform;
    }
}
