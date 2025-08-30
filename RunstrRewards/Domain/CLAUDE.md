# Domain Layer

## Purpose
Pure business logic and data models - the heart of RunstrRewards with zero framework dependencies.

## Contains
- **Models/**: Core data structures (Team, User, Competition, Workout, Wallet)
- **Repositories/**: Interfaces for data access (implemented by Data layer)
- **UseCases/**: Business logic orchestration (future expansion)

## Key Rules
- **No UI imports**: Never import UIKit, SwiftUI, or presentation frameworks
- **No external dependencies**: Foundation only, no networking or database code
- **Framework-agnostic**: Models should work in any Swift environment
- **Pure Swift**: Business rules, validations, and calculations only

## Dependencies
- **Depends on**: Foundation only
- **Used by**: All other layers (Data, Presentation, Core)

## Red Flags (Never Do This)
- ❌ Import UIKit, SwiftUI, or any UI framework
- ❌ Make network calls or database queries
- ❌ Reference external APIs or services
- ❌ Include view logic or presentation concerns
- ❌ Add device-specific code (HealthKit, notifications, etc.)

## Model Organization

### Competition/
- Competition events, leaderboards, team competitions
- Prize pools, entry fees, participation rules

### Team/
- Team management, membership, branding
- Team wallets, captain permissions, QR codes

### User/
- User profiles, authentication state, preferences
- Subscription status, earning history

### Wallet/
- Bitcoin balances, Lightning Network addresses
- Transaction records, payment states

### Workout/
- Exercise data, metrics, sync sources
- Anti-cheat validation rules, deduplication logic

## For Agents
When working in this folder, focus on **data integrity and business rules**.

**Reference Pattern**: See `CompetitionEvent.swift` for proper model structure:
- Clean struct definitions with Codable
- Custom CodingKeys for API mapping
- Proper date handling and optional properties
- JSONB field handling for complex data

**Key Principles**:
- Models map directly to database tables
- All business logic belongs here (calculations, validations)
- Keep models simple and focused on data representation
- Use computed properties for derived values

## Legacy Note
Some models may still exist in the old `Models/` folder at root level. New models go in `Domain/Models/` with proper subfolder organization. Reference the new structure for consistency.

## Critical for RunstrRewards
- **Competition models** drive the invisible competition experience
- **Team models** enable the team-branded notification system  
- **Wallet models** handle real Bitcoin Lightning Network transactions
- **Workout models** support background HealthKit sync and anti-cheat systems