# Presentation Layer

## Purpose
User interface components, navigation, and user interaction - the minimal visible layer for the "invisible micro app."

## Contains
- **Scenes/**: Feature-specific view controllers organized by domain
- **Components/**: Reusable UI elements (cards, buttons, forms)
- **Theme/**: Design system, colors, typography, industrial design elements

## Key Rules
- **Team branding first**: All UI should prominently feature team branding, not RunstrRewards
- **Minimal by design**: Users rarely interact - focus on essential actions only
- **Background-aware**: UI should reflect that app works invisibly via notifications
- **Data via services**: Never make direct API calls, use Data layer services

## Dependencies
- **Depends on**: Data layer services, Domain models, Core utilities
- **Used by**: Nothing (top layer of architecture)

## Red Flags (Never Do This)
- ❌ Make network calls directly from UI (use Data services)
- ❌ Include business logic (belongs in Domain layer)
- ❌ Hardcode colors/fonts (use Theme/DesignSystem.swift)
- ❌ Feature RunstrRewards branding over team branding
- ❌ Create complex flows (keep interactions minimal)

## UI Organization

### Scenes/ (Feature-Specific)
- **Authentication/**: Onboarding, permissions (HealthKit, notifications)
- **Teams/**: Team discovery, detail views, creation wizards
- **Competitions/**: Leaderboards, live competition views
- **Earnings/**: Bitcoin wallet, transaction history
- **Events/**: Competition events, management dashboards
- **Profile/**: User settings, sync sources, preferences

### Components/ (Reusable)
- **Cards/**: Challenge cards, navigation cards, streak displays
- **Buttons/**: Consistent button styles across app
- **Forms/**: Input components with validation
- **Lists/**: Team lists, transaction lists, member lists

### Theme/
- **DesignSystem.swift**: Colors, fonts, spacing constants
- **IndustrialBackgroundViews.swift**: Team-branded background elements

## Navigation Patterns

### Child Controller Pattern
Most complex screens use child view controllers for modular organization.
**Reference**: `TeamDetailViewController.swift` shows proper child controller setup.

### Tab-Based Navigation
Competition and team views use segmented controls for easy switching.

### Modal Presentation
Creation flows (teams, events) use modal presentation with step-by-step wizards.

## Critical UI Principles

### Invisible App Design
- Most user value comes from background sync and notifications
- UI focuses on: team discovery, leaderboard checking, Bitcoin management
- Avoid feature bloat - this is not a daily-use fitness app

### Team-Branded Experience
- Team colors, logos, and names should dominate the interface
- RunstrRewards branding should be subtle/minimal
- Competition notifications feature team branding exclusively

### Bitcoin Integration UI
- Lightning Network complexity hidden from users
- Simple balance displays and transaction history
- One-tap payment flows for team subscriptions

## For Agents
When working in this folder, focus on **user experience and team branding**.

**Reference patterns**: 
- `TeamDetailViewController.swift` for child controller organization
- `DesignSystem.swift` for consistent styling
- Cards in `Components/Cards/` for reusable UI elements

**Key considerations**:
- Keep interactions minimal (invisible app philosophy)
- Prioritize team branding over RunstrRewards branding
- Ensure UI works with background sync assumptions

## Migration Status
- **From**: Legacy `Features/` structure with mixed concerns
- **To**: Clean `Scenes/` organization by domain
- **Status**: ~90% migrated, some legacy files marked for deletion
- **New UI**: Always use `Presentation/Scenes/` structure

## Critical for RunstrRewards

### Onboarding Flow
Minimal setup: HealthKit permissions → Team discovery → Subscription → Background sync starts

### Team Discovery
QR code scanning, team browsing, direct team links for viral growth

### Competition Views  
Real-time leaderboards with live position updates, team-branded throughout

### Bitcoin Wallet
Simple Lightning Network interface hiding complexity, team prize distributions

Remember: This is the thin presentation layer for an invisible micro app. The real magic happens in background sync and team-branded push notifications.