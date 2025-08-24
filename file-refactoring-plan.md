# RunstrRewards: File Refactoring Implementation Plan (Revised)

## Overview
Based on analysis of the actual codebase, this plan focuses on refactoring the 5 largest files while preserving the real feature set: teams with events, competitions/leaderboards, workout sync, and Bitcoin rewards.

## Key Findings from Codebase Analysis
- ✅ Teams have: events, members, leaderboards, about sections
- ❌ Teams do NOT have: challenges or chatrooms (outdated files exist but aren't used)
- ✅ Main features: HealthKit sync, Bitcoin wallet, competitions, team management
- ✅ 22 existing service classes already handle specialized functions

## 📊 **Files Requiring Refactoring**

| File | Lines | Over Limit | Priority | Key Features |
|------|-------|------------|----------|--------------|
| `SupabaseService.swift` | 2,139 | 328% | 🚨 Critical | All database operations |
| `TeamDetailViewController.swift` | 1,486 | 197% | 🚨 Critical | Team info, members, events |
| `SubscriptionService.swift` | 1,208 | 142% | ⚠️ High | StoreKit integration |
| `SettingsViewController.swift` | 1,122 | 124% | ⚠️ High | App settings, preferences |
| `ViewController.swift` | 1,047 | 109% | 🔶 Medium | Main dashboard |

---

## 🎯 **Phase 1: SupabaseService Refactoring (Critical - 3-4 days)**

### Current SupabaseService Structure Analysis
- **Size**: 2,139 lines (328% over 500-line limit)
- **Contains**: Auth, teams, workouts, competitions, events, Bitcoin transactions
- **Dependencies**: 15+ view controllers rely on this service
- **Risk**: High - central to all app functionality

### Refactoring Strategy
**Create domain-specific services while maintaining existing public interface:**

#### Step 1.1: Create `AuthDataService.swift` (~400 lines)
- [ ] **Extract Functions**:
  - `signInWithApple(idToken:nonce:)`
  - `signOut()`
  - `restoreSession(accessToken:refreshToken:)`
  - `syncLocalProfileToSupabase(userId:username:fullName:)`
- [ ] **Extract Models**:
  - `UserSession`
  - `UserProfileData`
- [ ] **Dependencies**: AuthenticationService, KeychainService

#### Step 1.2: Create `TeamDataService.swift` (~500 lines)
- [ ] **Extract Functions**:
  - `createTeam(_:)`
  - `updateTeam(_:)`
  - `deleteTeam(_:)`
  - `joinTeam(_:)`
  - `leaveTeam(_:)`
  - `getTeamMembers(_:)`
  - `updateTeamMemberRole(_:)`
  - `getTeamsForUser(_:)`
- [ ] **Extract Models**:
  - `Team`
  - `TeamMember` 
  - `TeamData`
  - `TeamMemberWithProfile`
- [ ] **Dependencies**: ErrorHandlingService, OfflineDataService

#### Step 1.3: Create `WorkoutDataService.swift` (~400 lines)
- [ ] **Extract Functions**:
  - `syncWorkoutData(_:)`
  - `getRecentWorkouts(limit:)`
  - `validateWorkoutData(_:)`
  - `detectDuplicateWorkouts(_:)`
  - `handleAntiCheat(_:)`
  - `getUserWorkouts(_:)`
- [ ] **Extract Models**:
  - `HealthKitWorkout`
  - `WorkoutData`
  - Duplicate detection logic
- [ ] **Dependencies**: AntiCheatService, HealthKitService

#### Step 1.4: Create `CompetitionDataService.swift` (~400 lines)
- [ ] **Extract Functions**:
  - `createEvent(_:)`
  - `updateEvent(_:)`
  - `joinEvent(_:)`
  - `getEventParticipants(_:)`
  - `updateLeaderboard(_:)`
  - `getLeaderboardData(_:)`
  - `getCompetitionEvents(_:)`
- [ ] **Extract Models**:
  - `CompetitionEvent`
  - `EventParticipant`
  - `LeaderboardData`
  - Event-related enums
- [ ] **Dependencies**: RealtimeLeaderboardService

#### Step 1.5: Create `TransactionDataService.swift` (~300 lines)
- [ ] **Extract Functions**:
  - `recordTransaction(_:)`
  - `getUserTransactions(_:)`
  - `updateWalletBalance(_:)`
  - `getTeamWalletData(_:)`
  - `updateTeamWalletId(_:)`
- [ ] **Extract Models**:
  - `TransactionData`
  - `WalletData`
  - Bitcoin-related models
- [ ] **Dependencies**: LightningWalletManager, CoinOSService

#### Step 1.6: Keep `SupabaseService.swift` as Coordinator (~200 lines)
- [ ] **Responsibilities**:
  - Initialize all sub-services
  - Provide backwards-compatible public interface
  - Handle cross-service operations
  - Manage shared Supabase client instance
- [ ] **Maintain public interface for existing code**:
  ```swift
  // Delegate to appropriate service
  func createTeam(_ team: Team) async throws -> Team {
      return try await TeamDataService.shared.createTeam(team)
  }
  ```

### Step 1.7: Update Dependencies Across Codebase
- [ ] **Find all SupabaseService usages**: Search for `SupabaseService.shared`
- [ ] **Update imports gradually**: Change one file at a time to specific services
- [ ] **Test after each change**: Ensure functionality preserved

---

## 🎯 **Phase 2: TeamDetailViewController Refactoring (2-3 days)**

### Current Structure Analysis
- **Size**: 1,486 lines (197% over limit)
- **Features**: Team header, about section, members list, events section
- **TabType enum**: league, events (no chat/challenges)
- **Captain-specific UI**: Event creation and management

### Refactoring Strategy
**Split into focused view components:**

#### Step 2.1: Create `TeamDetailContainerViewController.swift` (~300 lines)
- [ ] **Responsibilities**:
  - Main navigation and layout coordination
  - Team header display (TeamDetailHeaderView)
  - Tab switching logic between League and Events
  - Captain status management
- [ ] **Contains**:
  - ScrollView and content view setup
  - Header view management
  - Child view controller coordination

#### Step 2.2: Create `TeamMembersViewController.swift` (~400 lines)
- [ ] **Extract from**: Team members functionality
- [ ] **Features**:
  - Members list display (TeamMembersListView)
  - Join/leave team functionality
  - Captain controls for member management
  - Member profile integration
- [ ] **Dependencies**: TeamDataService, AuthenticationService

#### Step 2.3: Create `TeamEventsViewController.swift` (~400 lines)
- [ ] **Extract from**: Events tab functionality
- [ ] **Features**:
  - Event list display and management
  - Event creation (captain only)
  - Event participation
  - Prize distribution interface
- [ ] **Dependencies**: CompetitionDataService, EventCreationWizardViewController

#### Step 2.4: Create `TeamLeagueViewController.swift` (~300 lines)
- [ ] **Extract from**: League tab functionality
- [ ] **Features**:
  - Team leaderboards display
  - Competition statistics
  - Team performance metrics
  - Real-time competition updates
- [ ] **Dependencies**: CompetitionDataService, RealtimeLeaderboardService

#### Step 2.5: Update TeamDetailViewController Navigation
- [ ] **Update presenting controllers**: TeamsViewController, QR code scanner
- [ ] **Test navigation flow**: Ensure proper container → child view flow
- [ ] **Maintain state**: Ensure data persists across tab switches

---

## 🎯 **Phase 3: SubscriptionService Refactoring (2 days)**

### Current Structure Analysis
- **Size**: 1,208 lines (142% over limit)
- **Contains**: StoreKit operations, subscription logic, payment processing

### Refactoring Strategy
**Split into StoreKit-focused concerns:**

#### Step 3.1: Create `StoreKitService.swift` (~400 lines)
- [ ] **Extract Functions**:
  - Core StoreKit operations
  - Product fetching and validation
  - Transaction handling and receipt validation
  - Store configuration validation
- [ ] **Focus**: Pure StoreKit interface

#### Step 3.2: Create `SubscriptionManagerService.swift` (~400 lines)
- [ ] **Extract Functions**:
  - Business logic for team/member subscriptions
  - Subscription state management
  - Billing cycle handling
  - Subscription renewal logic
- [ ] **Focus**: RunstrRewards-specific subscription logic

#### Step 3.3: Create `PaymentProcessorService.swift` (~300 lines)
- [ ] **Extract Functions**:
  - Payment validation and processing
  - Refund handling
  - Payment history tracking
  - Error handling for payment failures
- [ ] **Focus**: Payment processing and error recovery

#### Step 3.4: Keep `SubscriptionService.swift` as Coordinator (~100 lines)
- [ ] **Provide unified interface for existing code**
- [ ] **Coordinate between StoreKit, subscription logic, and payments**

---

## 🎯 **Phase 4: SettingsViewController Refactoring (1-2 days)**

### Current Structure Analysis
- **Size**: 1,122 lines (124% over limit)
- **Contains**: Account settings, notifications, app preferences, subscriptions

### Refactoring Strategy
**Split into focused settings categories:**

#### Step 4.1: Create `SettingsContainerViewController.swift` (~200 lines)
- [ ] **Navigation and section management**
- [ ] **Settings menu and category switching**

#### Step 4.2: Create `AccountSettingsViewController.swift` (~300 lines)
- [ ] **Profile management, authentication, account deletion**

#### Step 4.3: Create `NotificationSettingsViewController.swift` (~300 lines)
- [ ] **Push notifications, workout alerts, team notifications**

#### Step 4.4: Create `AppPreferencesViewController.swift` (~250 lines)
- [ ] **Privacy settings, data sync preferences, app behavior**

#### Step 4.5: Create `SubscriptionSettingsViewController.swift` (~250 lines)
- [ ] **Billing management, subscription status, team roles**

---

## 🎯 **Phase 5: ViewController (Dashboard) Refactoring (1-2 days)**

### Current Structure Analysis
- **Size**: 1,047 lines (109% over limit)
- **Contains**: Main dashboard, wallet summary, activity overview, navigation

### Refactoring Strategy
**Split into dashboard components:**

#### Step 5.1: Create `DashboardContainerViewController.swift` (~300 lines)
- [ ] **Main navigation setup and layout coordination**
- [ ] **Navigation to Teams, Earnings, Workouts, Competitions**

#### Step 5.2: Create `WalletSummaryViewController.swift` (~300 lines)
- [ ] **Bitcoin wallet balance, recent transactions, quick actions**

#### Step 5.3: Create `ActivitySummaryViewController.swift` (~300 lines)
- [ ] **Recent workouts, achievements, streak tracking**

#### Step 5.4: Create `TeamSummaryViewController.swift` (~250 lines)
- [ ] **Current team status, recent team activity, quick team actions**

---

## ⚙️ **Implementation Strategy**

### Pre-Refactoring Checklist
- [ ] **Create feature branch**: `git checkout -b refactor/file-size-reduction`
- [ ] **Run full app test**: Establish functionality baseline
- [ ] **Document public APIs**: List all methods other files depend on
- [ ] **Create backup commit**: Save current state before refactoring

### During Refactoring Process
1. **One phase at a time**: Complete SupabaseService before moving to next
2. **Maintain public interfaces**: Prevent breaking changes during refactoring
3. **Test after each service extraction**: Verify functionality preserved
4. **Update imports incrementally**: Change dependencies file by file
5. **Commit frequently**: Small, focused commits for easy rollback if needed

### Post-Refactoring Verification
- [ ] **Authentication flow**: Sign in/out works correctly
- [ ] **Team operations**: Create, join, manage teams functions properly
- [ ] **HealthKit sync**: Workout data synchronization continues working
- [ ] **Bitcoin wallet**: All wallet operations remain functional
- [ ] **Events and competitions**: Event creation and participation works
- [ ] **Settings and navigation**: All settings screens accessible and functional
- [ ] **Performance**: No degradation in app performance

## 🗓️ **Timeline Summary**

| Phase | Focus | Duration | Risk Level | Dependencies |
|-------|-------|----------|------------|--------------|
| Phase 1 | SupabaseService | 3-4 days | 🚨 High | Affects all features |
| Phase 2 | TeamDetailViewController | 2-3 days | ⚠️ Medium | Team management |
| Phase 3 | SubscriptionService | 2 days | ⚠️ Medium | Payment processing |
| Phase 4 | SettingsViewController | 1-2 days | 🔶 Low | Settings screens |
| Phase 5 | ViewController (Dashboard) | 1-2 days | 🔶 Low | Main navigation |

**Total Estimated Time**: 10-14 days
**Total Files Created**: ~20 new focused files
**Total Lines Reduced**: ~4,700 lines from oversized files

## 🎯 **Success Criteria**
- [ ] All files under 500-line limit
- [ ] Zero functionality regressions
- [ ] All existing features work as before
- [ ] Clean separation of concerns
- [ ] Easier maintenance and testing
- [ ] No performance degradation

## 📋 **Quality Assurance Checklist**

### Code Quality Standards
- [ ] **File size**: All new files under 500 lines
- [ ] **Single responsibility**: Each service/view has clear, focused purpose
- [ ] **Consistent naming**: Follow existing project naming conventions
- [ ] **Error handling**: Maintain existing error handling patterns
- [ ] **Documentation**: Add brief header documentation for each new file

### Functionality Preservation
- [ ] **End-to-end user flows**: Login → Team creation → Event participation → Bitcoin rewards
- [ ] **Background functionality**: HealthKit sync, notifications, wallet updates
- [ ] **Captain features**: Team management, event creation, member management
- [ ] **Member features**: Team joining, event participation, earnings tracking

---

**Next Steps**: Begin with Phase 1 (SupabaseService) as it's the most critical and affects the most files. This refactoring maintains all actual app features while achieving the architectural goal of keeping files under 500 lines.