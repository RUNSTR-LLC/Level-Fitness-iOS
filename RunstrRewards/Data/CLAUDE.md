# Data Layer

## Purpose
All external data operations - APIs, databases, device integrations, and background services.

## Contains
- **Network/**: API clients (Supabase, CoinOS Lightning Network)
- **Local/**: Caching, UserDefaults, offline storage
- **Services/**: Organized by domain (Authentication, HealthKit, Wallet, etc.)

## Key Rules
- **All async operations use async/await** (no completion handlers in new code)
- **Services are singletons** with shared instance pattern
- **Handle errors gracefully** with proper logging and user feedback
- **No UI concerns** - return data/models, never handle presentation

## Dependencies
- **Depends on**: Domain models, external SDKs (Supabase, HealthKit, etc.)
- **Used by**: Presentation layer (never directly from Domain)

## Red Flags (Never Do This)
- ❌ Import UIKit or SwiftUI (data services shouldn't handle UI)
- ❌ Use completion handlers for new async code (use async/await)
- ❌ Put business logic here (belongs in Domain layer)
- ❌ Make services stateful beyond caching (keep them focused)
- ❌ Skip error handling or fail silently

## Service Organization

### Authentication/
- **AuthenticationService**: Apple Sign In, user sessions
- **NostrAuthenticationService**: Bitcoin social protocol auth
- **AuthDataService**: User profile data management

### Background/
- **BackgroundTaskManager**: iOS background task coordination
- Critical for invisible app operation and HealthKit sync

### Competition/
- **CompetitionDataService**: Event management, leaderboards
- **EventProgressTracker**: Real-time competition updates
- **AntiCheatService**: Cross-platform duplicate detection
- **RealtimeLeaderboardService**: Live position tracking

### HealthKit/
- **HealthKitService**: Core iOS health data integration
- **HealthKitBackgroundService**: Background sync coordination
- **WorkoutDataService**: Exercise data processing
- **WorkoutDeduplicationService**: Anti-cheat across fitness platforms

### Notifications/
- **NotificationService**: Push notification delivery
- **NotificationIntelligence**: Smart notification timing
- **EventNotificationService**: Competition-specific alerts

### Team/
- **TeamDataService**: Team management, membership
- **TeamWalletManager**: Team prize pool management
- **TeamInvitationService**: QR code and invitation handling

### Wallet/
- **CoinOSService**: Lightning Network Bitcoin transactions
- **LightningWalletManager**: Wallet operations and balances
- **TransactionDataService**: Payment history and records
- **SubscriptionService**: Team and user subscription billing

## Service Patterns

### Singleton Pattern
```swift
class ServiceName {
    static let shared = ServiceName()
    private init() { /* setup */ }
}
```

### Async/Await Pattern
All new services should use async/await for external operations. Reference **SupabaseService.swift** for database patterns.

### Error Handling Pattern
Services should throw specific errors, log appropriately, and never fail silently. Critical for Bitcoin transactions and HealthKit data integrity.

## For Agents
When working in this folder, focus on **external integration reliability**.

**Check service organization** in subfolders - each domain has its own folder.
**Follow existing async patterns** - no completion handlers in new code.
**Reference SupabaseService.swift** for database operation patterns.
**Reference CoinOSService.swift** for external API integration patterns.

## Critical for RunstrRewards

### Background Sync Pipeline
`HealthKitBackgroundService → WorkoutDataService → CompetitionDataService → NotificationService`

### Bitcoin Payment Flow
`CoinOSService → LightningWalletManager → TeamWalletManager → TransactionDataService`

### Team-Branded Notifications
All notifications must feature team branding (not RunstrRewards) via **NotificationIntelligence** service.

### Anti-Cheat System
Cross-platform workout validation through **AntiCheatService** and **WorkoutDeduplicationService** to prevent gaming the Bitcoin rewards.

## Migration Notes
Legacy services may exist in the old `/Services` folder at root level. New services belong in `Data/Services/` with proper domain organization. Always check both locations when looking for existing functionality.