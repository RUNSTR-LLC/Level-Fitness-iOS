# Issue #4: Nostr Service Layer Implementation

## Overview
Implement the core Nostr service infrastructure by porting and adapting key services from RUNSTR-IOS submodule, including connection management, event publishing, profile services, and local caching for reliable Nostr integration.

## User Story
As a developer working on RunstrRewards, I need a robust Nostr service layer that handles relay connections, event publishing/fetching, and data caching so that all Nostr features work reliably across the app.

## Technical Requirements

### 1. NostrConnectionManager
- **File**: `RunstrRewards/Services/NostrConnectionManager.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrConnectionManager.swift`
- Manage connections to multiple relays simultaneously
- Handle relay failures and automatic reconnection
- Connection pooling and load balancing
- Real-time connection status monitoring

### 2. NostrEventPublisher  
- **File**: `RunstrRewards/Services/NostrEventPublisher.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrEventPublisher.swift`
- Publish kind 1 (text notes) and kind 1301 (workout records)
- Handle publishing to multiple relays with status tracking
- Implement retry logic for failed publications
- Rate limiting and error handling

### 3. NostrProfileService
- **File**: `RunstrRewards/Services/NostrProfileService.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrProfileService.swift`
- Fetch and cache user profile data (kind 0 events)
- Handle profile updates and metadata management
- Support for profile picture, name, about fields
- Cross-relay profile synchronization

### 4. NostrCacheManager
- **File**: `RunstrRewards/Services/NostrCacheManager.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrCacheManager.swift`
- Local storage for fetched Nostr events and profiles
- Intelligent cache invalidation strategies
- Offline support with cached data
- Memory and disk cache optimization

### 5. NostrService (Coordinator)
- **File**: `RunstrRewards/Services/NostrService.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrService.swift`
- Main coordinator for all Nostr operations
- Dependency injection for other services
- Centralized error handling and logging
- Service lifecycle management

## Implementation Steps

### Phase 1: Core Infrastructure
1. [ ] Add NostrSDK dependency via Swift Package Manager
2. [ ] Create `NostrConnectionManager` with relay management
3. [ ] Implement connection state monitoring
4. [ ] Add automatic reconnection logic

### Phase 2: Event Management
1. [ ] Create `NostrEventPublisher` with multi-relay support
2. [ ] Implement retry mechanisms for failed publishes
3. [ ] Add event validation and formatting
4. [ ] Create status tracking for published events

### Phase 3: Profile & Caching
1. [ ] Create `NostrProfileService` for user metadata
2. [ ] Implement `NostrCacheManager` for local storage
3. [ ] Add cache invalidation strategies
4. [ ] Implement offline support mechanisms

### Phase 4: Service Coordination
1. [ ] Create main `NostrService` coordinator
2. [ ] Implement service dependency injection
3. [ ] Add centralized logging and monitoring
4. [ ] Create service health checks

## Service Architecture

### Dependency Graph
```
NostrService (Coordinator)
├── NostrKeyManager (from Issue #1)
├── NostrConnectionManager
├── NostrEventPublisher
├── NostrProfileService  
├── NostrCacheManager
└── NostrWorkoutService (from Issue #2)
```

### Relay Configuration
```swift
struct NostrRelay {
    let url: String
    var isConnected: Bool = false
    var lastSeen: Date?
    var connectionAttempts: Int = 0
    var isReliable: Bool = true
    
    static let defaultRelays = [
        "wss://relay.damus.io",
        "wss://nos.lol",
        "wss://relay.snort.social", 
        "wss://relay.primal.net"
    ]
}
```

## Key Adaptations from RUNSTR-IOS

### 1. Integration with RunstrRewards Architecture
- Adapt to existing service patterns in RunstrRewards
- Integrate with `SupabaseService` and existing data models
- Follow RunstrRewards error handling conventions
- Use existing logging and monitoring systems

### 2. Background Task Integration
- Integrate with `BackgroundTaskManager`
- Support background sync and publishing
- Handle iOS app lifecycle events
- Optimize for battery usage

### 3. Offline Support
- Queue operations when network unavailable  
- Sync queued operations when connection restored
- Local cache fallback for read operations
- Graceful degradation of features

## Cache Strategy

### Event Caching
- Cache kind 0 (profiles) for 24 hours
- Cache kind 1301 (workouts) permanently with user control
- LRU eviction for memory management
- Disk persistence for important data

### Cache Invalidation
```swift
enum CachePolicy {
    case immediate // Always fetch from relays
    case cached(maxAge: TimeInterval) // Use cache within age limit
    case cacheFirst // Use cache if available, fallback to relays
    case offlineOnly // Use cache only, no network requests
}
```

## Error Handling Strategy

### Relay Connection Errors
```swift
enum NostrError: Error, LocalizedError {
    case noRelaysAvailable
    case connectionTimeout(relay: String)
    case publishingFailed(relays: [String])
    case invalidEventFormat
    case keyNotFound
    case rateLimited(retryAfter: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .noRelaysAvailable:
            return "No Nostr relays are currently available"
        case .connectionTimeout(let relay):
            return "Connection timeout to relay: \(relay)"
        case .publishingFailed(let relays):
            return "Failed to publish to relays: \(relays.joined(separator: ", "))"
        // ... etc
        }
    }
}
```

### Retry Logic
- Exponential backoff for connection failures
- Circuit breaker pattern for unreliable relays
- Different retry strategies for different operation types
- User notification for permanent failures

## Performance Optimizations

### Connection Pooling
- Reuse connections across operations
- Lazy connection establishment
- Connection health monitoring
- Automatic cleanup of stale connections

### Batch Operations
- Batch multiple events in single relay connection
- Group operations by relay for efficiency
- Parallel processing where appropriate
- Rate limiting to avoid relay blocking

## Testing Strategy

### Unit Tests
- Mock relay responses for testing
- Test error handling scenarios
- Validate event formatting and parsing
- Test cache behavior and invalidation

### Integration Tests  
- Test with real relay connections
- Network failure scenarios
- Background task execution
- Cross-service integration

## Security Considerations

### Event Validation
- Validate all incoming events before processing
- Sanitize user-generated content
- Verify event signatures where applicable
- Rate limit to prevent abuse

### Key Management Integration
- Secure integration with `NostrKeyManager`
- No private key exposure in logs
- Proper cleanup of sensitive data
- Secure event signing process

## Monitoring & Observability

### Metrics to Track
- Relay connection success rates
- Event publishing success/failure rates
- Cache hit/miss ratios
- Background sync performance
- Network usage statistics

### Logging Strategy
```swift
enum NostrLogLevel {
    case debug   // Detailed operation logs
    case info    // Important state changes  
    case warning // Recoverable errors
    case error   // Critical failures
}
```

## Success Criteria
- [ ] All four core services implemented and working
- [ ] Reliable multi-relay connection management  
- [ ] Robust error handling and retry mechanisms
- [ ] Efficient caching with offline support
- [ ] Clean integration with existing RunstrRewards architecture
- [ ] Comprehensive test coverage (>80%)
- [ ] Performance meets requirements (sub-second operations)

## Files to Create/Modify

### New Files
- `RunstrRewards/Services/NostrConnectionManager.swift`
- `RunstrRewards/Services/NostrEventPublisher.swift`
- `RunstrRewards/Services/NostrProfileService.swift`
- `RunstrRewards/Services/NostrCacheManager.swift`
- `RunstrRewards/Services/NostrService.swift`
- `RunstrRewards/Models/NostrRelay.swift`
- `RunstrRewards/Models/NostrEvent.swift`

### Modified Files
- `RunstrRewards.xcodeproj/project.pbxproj` (add NostrSDK dependency)
- `RunstrRewards/App/AppDelegate.swift` (initialize Nostr services)
- `RunstrRewards/Services/BackgroundTaskManager.swift` (add Nostr tasks)

## Reference Implementation
Port and adapt from all files in `RUNSTR/RUNSTR IOS/Core/Services/Nostr/` directory, maintaining architectural patterns while integrating with RunstrRewards conventions.

## Dependencies
- NostrSDK Swift Package Manager dependency
- Foundation and Network frameworks
- Core Data or SQLite for local caching

## Priority: High  
Foundation for all other Nostr features - must be solid and reliable.

## Estimated Effort: 5-6 days
Most complex issue due to service architecture and reliability requirements.