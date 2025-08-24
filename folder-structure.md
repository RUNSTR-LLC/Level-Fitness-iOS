# RunstrRewards Folder Structure Organization

## Overview
This document tracks the reorganization of the RunstrRewards iOS project into a maintainable, feature-based folder structure. Each feature is grouped logically with related files kept together.

## Target Folder Structure

```
RunstrRewards/
├── App/
│   ├── AppDelegate.swift
│   ├── Info.plist
│   └── RunstrRewards.entitlements
├── Core/
│   ├── Models/           # Data models and entities
│   ├── Services/         # Business logic services (already organized)
│   └── Extensions/       # Utility extensions
├── Features/            # Feature-based organization
│   ├── Authentication/
│   ├── Teams/
│   ├── Competitions/ 
│   ├── Events/
│   ├── Profile/
│   ├── Workouts/
│   ├── Earnings/
│   └── Settings/
├── Shared/
│   ├── UI/              # Reusable UI components
│   ├── Design/          # Design system and styling
│   └── Utils/           # Utility classes and helpers
└── Resources/
    ├── Assets.xcassets/
    └── Base.lproj/
```

## File Migration Plan

### ✅ Phase 1: Preparation
- [x] Create folder-structure.md documentation
- [ ] Create new folder structure in Xcode (groups only, no file moves)
- [ ] Test build to ensure no issues

### 🚧 Phase 2: File Migration by Feature

#### App/ - Core Application Files
- [ ] AppDelegate.swift
- [ ] Info.plist
- [ ] RunstrRewards.entitlements

#### Features/Authentication/
- [ ] LoginViewController.swift
- [ ] OnboardingViewController.swift
- [ ] UserProfileSetupViewController.swift
- [ ] HealthKitPermissionViewController.swift
- [ ] NotificationPermissionViewController.swift

#### Features/Teams/
- [ ] TeamsViewController.swift
- [ ] TeamCard.swift
- [ ] TeamDetailViewController.swift
- [ ] TeamDetailAboutSection.swift
- [ ] TeamDetailHeaderView.swift
- [ ] TeamDetailChatViewController.swift
- [ ] TeamDetailEventsViewController.swift
- [ ] TeamDetailLeagueViewController.swift
- [ ] TeamDetailTabNavigation.swift
- [ ] TeamCreationWizardViewController.swift
- [ ] TeamBasicInfoStepViewController.swift
- [ ] TeamLeaderboardSetupStepViewController.swift
- [ ] TeamMetricSelectionStepViewController.swift
- [ ] TeamReviewStepViewController.swift
- [ ] TeamMembersListView.swift
- [ ] TeamSubscriptionStatusView.swift
- [ ] TeamWalletBalanceView.swift
- [ ] TeamWalletFundingViewController.swift
- [ ] TeamActivityFeedView.swift
- [ ] QRCodeDisplayViewController.swift
- [ ] QRCodeScannerViewController.swift

#### Features/Competitions/
- [ ] CompetitionsViewController.swift
- [ ] CompetitionTabNavigationView.swift
- [ ] LeaderboardItemView.swift
- [ ] LiveLeaderboardView.swift
- [ ] LeagueView.swift

#### Features/Events/
- [ ] EventsView.swift
- [ ] EventCard.swift
- [ ] EventCardView.swift
- [ ] EventDetailViewController.swift
- [ ] EventCreationWizardViewController.swift
- [ ] EventBasicInfoStepViewController.swift
- [ ] EventMetricsStepViewController.swift
- [ ] EventScheduleStepViewController.swift
- [ ] EventReviewStepViewController.swift
- [ ] EventProgressView.swift
- [ ] EventStatCard.swift
- [ ] EventManagementCell.swift
- [ ] EventManagementDashboardViewController.swift
- [ ] PrizeDistributionViewController.swift
- [ ] PrizePoolTrackerView.swift
- [ ] MemberPayoutHistoryViewController.swift

#### Features/Profile/
- [ ] ProfileViewController.swift
- [ ] ProfileHeaderView.swift
- [ ] ProfileTabNavigationView.swift
- [ ] ProfileAccountTabView.swift
- [ ] ProfileSubscriptionView.swift
- [ ] ProfileSupportView.swift
- [ ] ProfileSyncSourcesView.swift
- [ ] ProfileWorkoutHistoryView.swift
- [ ] ProfileWorkoutsTabView.swift
- [ ] EditProfileViewController.swift
- [ ] NotificationTogglesView.swift

#### Features/Workouts/
- [ ] WorkoutsViewController.swift
- [ ] WorkoutCard.swift
- [ ] WorkoutStatsView.swift
- [ ] WorkoutSyncSourceCard.swift
- [ ] WorkoutSyncView.swift
- [ ] WorkoutTabNavigationView.swift
- [ ] ConnectedAppsViewController.swift

#### Features/Earnings/
- [ ] EarningsViewController.swift
- [ ] EarningsHeaderView.swift
- [ ] WalletBalanceView.swift
- [ ] WalletActionButton.swift
- [ ] WalletSectionView.swift
- [ ] TransactionCard.swift
- [ ] TransactionHistoryView.swift
- [ ] PaymentSheetViewController.swift
- [ ] LotteryComingSoonViewController.swift

#### Features/Settings/
- [ ] SettingsViewController.swift
- [ ] PrivacySettingsViewController.swift
- [ ] HelpSupportViewController.swift

#### Shared/UI/ - Reusable Components
- [ ] NavigationCard.swift
- [ ] StatItem.swift
- [ ] StreakCardView.swift
- [ ] ChallengeCard.swift
- [ ] ChallengeDetailViewController.swift
- [ ] MessageView.swift
- [ ] MessageInputView.swift
- [ ] ChatMessageView.swift
- [ ] WebViewController.swift
- [ ] ViewController.swift (main dashboard)

#### Shared/Design/ - Design System
- [ ] DesignSystem.swift
- [ ] IndustrialBackgroundViews.swift
- [ ] IconGenerator.swift

#### Resources/ - Assets and Resources
- [ ] Assets.xcassets/ (move from current location)
- [ ] Base.lproj/ (move from current location)

### ✅ Phase 3: Validation
- [ ] Full app build and test
- [ ] Verify all imports resolve correctly
- [ ] Run app to ensure no runtime issues
- [ ] Update project.pbxproj references as needed

## Migration Notes

### What Won't Break:
- Swift imports work with folder structure automatically in most cases
- Xcode project groups can be reorganized without affecting builds
- Existing Services/ folder is well-organized and will remain mostly unchanged

### What Needs Attention:
- project.pbxproj file references must be updated during migration
- Any hardcoded file paths (unlikely in iOS projects)
- Storyboard references (minimal impact since project uses programmatic UI)

### Benefits of New Structure:
- Feature-based development becomes easier
- New developers can navigate the codebase intuitively
- Related files grouped together logically
- Maintains the <500 line file principle established in the project
- Clear separation between business logic (Services/), UI components (Features/), and shared utilities

## Progress Tracking

**Created:** [Current Date]
**Last Updated:** [Update as files are moved]
**Status:** In Progress - Phase 1

Use checkboxes above to track migration progress. Update this document as files are successfully moved and tested.