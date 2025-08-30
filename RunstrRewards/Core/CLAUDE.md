# Core Layer

## Purpose
Shared utilities, constants, protocols, and extensions used across all layers - the foundation layer with zero dependencies on other app layers.

## Contains
- **Constants/**: App-wide configuration, API endpoints, magic numbers
- **Extensions/**: Swift standard library extensions, convenience methods
- **Models/**: Shared data structures (not domain-specific)
- **Protocols/**: Interfaces used across multiple layers
- **Utilities/**: Helper services and tools (Keychain, Image Cache, Network Monitor)

## Key Rules
- **Foundation only**: No dependencies on Domain, Data, or Presentation layers
- **Layer-agnostic**: Code here should work in any Swift environment
- **Pure utilities**: No business logic or app-specific functionality
- **Reusable**: Focus on code that could work in other projects

## Dependencies
- **Depends on**: Foundation, system frameworks only
- **Used by**: All other layers (Domain, Data, Presentation)

## Red Flags (Never Do This)
- ❌ Import Domain, Data, or Presentation layer code
- ❌ Include business logic (belongs in Domain)
- ❌ Make network calls or database operations (belongs in Data)
- ❌ Add UI-specific code (belongs in Presentation)
- ❌ Reference app-specific models (use generic protocols)

## Utility Organization

### Constants/
- **AppConstants.swift**: Configuration values, API endpoints, feature flags
- App version, build numbers, environment settings

### Extensions/
- Swift standard library extensions (String, Date, Array, etc.)
- UIKit extensions for common operations
- Foundation extensions for data handling

### Models/
- Generic data structures used across layers
- Error types and result wrappers
- Protocol definitions for shared interfaces

### Protocols/
- Interfaces that multiple layers implement
- Delegation patterns used across the app
- Generic protocols for data handling

### Utilities/
- **KeychainService**: Secure storage for tokens, keys, credentials
- **ImageCacheService**: Image loading and caching utilities  
- **NetworkMonitorService**: Internet connectivity detection
- **ErrorHandlingService**: Centralized error processing

## Service Patterns

### Singleton Utilities
Most Core utilities use singleton pattern for shared state:
```swift
class UtilityService {
    static let shared = UtilityService()
    private init() { /* setup */ }
}
```

### Thread Safety
Critical utilities like **KeychainService** implement proper thread safety with concurrent queues and barriers for write operations.

## For Agents
When working in this folder, focus on **reusability and zero dependencies**.

**Reference pattern**: See `KeychainService.swift` for secure storage implementation:
- Proper thread safety with concurrent queues
- Clear key enumeration for type safety
- Error handling for security operations

**Key principles**:
- Keep utilities generic and reusable
- No references to other app layers
- Focus on Foundation-level functionality
- Thread safety for shared resources

## Critical for RunstrRewards

### Security Services
- **KeychainService**: Stores Bitcoin keys, authentication tokens, Nostr keys
- Handles Lightning Network credentials securely
- Thread-safe operations for background sync

### System Integration
- **NetworkMonitorService**: Background sync reliability
- **ErrorHandlingService**: Centralized error tracking across layers

### Caching
- **ImageCacheService**: Team logos, profile images, event graphics
- Reduces network usage for background operation

## Migration Notes
Some utilities may exist in the old `/Shared/Utils/` or root-level folders. Core utilities belong in `Core/Utilities/` for clear architectural boundaries.

## Extension Guidelines
- String extensions: URL validation, formatting helpers
- Date extensions: Competition date handling, timezone utilities  
- Array extensions: Safe subscripting, filtering helpers
- Never extend with business logic (that belongs in Domain)

Remember: Core is the foundation layer. Everything here should be generic enough to use in any Swift project, with no knowledge of RunstrRewards-specific business logic.