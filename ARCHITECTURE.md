# RunstrRewards Architecture Overview

## Core Principle: Clean Architecture with Layer Separation

RunstrRewards follows a clean architecture pattern with clear layer boundaries designed for the "invisible micro app" vision where background sync and push notifications drive user engagement.

## Layer Communication Rules

```
Presentation Layer
     ↓ (calls)
   Data Layer  
     ↓ (uses models from)
  Domain Layer
     ↓ (depends on)
   Core Layer
```

### Communication Flow
- **Presentation** → Data (via Services, never directly to external APIs)
- **Data** → Domain (using domain models, implementing repository patterns)  
- **Domain** → Core (for utilities, constants, shared protocols)
- **Core** → Foundation only (no dependencies on other layers)

### Forbidden Dependencies
- ❌ Domain → Data/Presentation (domain must stay pure)
- ❌ Core → Any other layer (utilities must be independent)
- ❌ Direct API calls from Presentation (must go through Data services)

## Critical App-Specific Patterns

### Background Sync Architecture
- **Entry Point**: `Data/Services/HealthKit/HealthKitBackgroundService.swift`
- **Data Flow**: HealthKit → WorkoutDataService → CompetitionDataService → Notifications
- **Key Services**: BackgroundTaskManager, WorkoutSyncQueue, EventProgressTracker

### Bitcoin/Lightning Integration  
- **Primary Service**: `Data/Services/Wallet/CoinOSService.swift`
- **Team Wallets**: `Data/Services/Team/TeamWalletManager.swift`
- **Transaction Flow**: CoinOS API → LightningWalletManager → UI updates

### Push Notification System
- **Intelligence**: `Data/Services/Notifications/NotificationIntelligence.swift`
- **Team Branding**: All notifications feature team branding, not RunstrRewards
- **Event Triggers**: Competition updates, workout rewards, team announcements

## Service Discovery Quick Reference

| Functionality | Primary Service | Location |
|---------------|----------------|----------|
| Authentication | AuthenticationService | Data/Services/Authentication/ |
| HealthKit Sync | HealthKitService | Data/Services/HealthKit/ |
| Bitcoin Payments | CoinOSService | Data/Services/Wallet/ |
| Team Management | TeamDataService | Data/Services/Team/ |
| Competition Logic | CompetitionDataService | Data/Services/Competition/ |
| Push Notifications | NotificationService | Data/Services/Notifications/ |
| Background Tasks | BackgroundTaskManager | Data/Services/Background/ |

## Recent Architectural Changes

### Migration in Progress
- **From**: Legacy `Features/` structure  
- **To**: Clean architecture with `Domain/`, `Data/`, `Presentation/`
- **Status**: ~90% complete, some legacy files remain marked for deletion
- **Note**: New code goes in the new structure, legacy files being phased out

### Key Decisions
- Single-responsibility services over large managers
- Background sync as primary data source (not user interaction)
- Real Bitcoin integration (no mock data in production)
- Team branding throughout notification system

## Development Guidelines

### For New Features
1. Start with Domain models (what data do we need?)
2. Create Data services (how do we get/store it?)
3. Build Presentation components (how do users interact?)
4. Consider background sync implications (how does it work invisibly?)

### For AI Agents
- **Domain-Agent**: Focus on business logic, model relationships
- **Data-Agent**: Handle service patterns, async operations, external integrations
- **Presentation-Agent**: UI/UX, navigation, user interaction flows
- **Integration-Agent**: Cross-layer changes, architectural modifications

### Critical Success Metrics
- Background sync reliability (99%+ HealthKit data capture)
- Real-time competition updates (<24hr latency)
- Zero Bitcoin transaction failures
- Team-branded notification delivery (not RunstrRewards branded)

## Emergency Patterns

### If Background Sync Fails
1. Check `BackgroundTaskManager` task registration
2. Verify `HealthKitService` permissions
3. Review `WorkoutSyncRetryManager` queue status
4. Validate `EventProgressTracker` competition updates

### If Bitcoin Payments Fail  
1. Verify `CoinOSService` API connectivity
2. Check `TeamWalletManager` balance validation
3. Review `TransactionDataService` error logs
4. Validate Lightning Network node status

This architecture supports RunstrRewards' core vision: an invisible micro app that turns fitness into Bitcoin-earning competitions through seamless background operation and team-branded engagement.