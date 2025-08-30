# RunstrRewards - The Invisible Micro App for Team-Based Fitness Competition

## Project Vision

**RunstrRewards is the invisible micro app that turns fitness into Bitcoin-earning competitions.** Users subscribe to teams they love, sync workouts automatically in the background, and earn real Bitcoin rewards through team-branded competitions - all without needing to actively use the app.

### Core Value Proposition
- **Members**: Subscribe to teams ($1.99/month), compete using existing workout data, earn Bitcoin automatically
- **Teams**: Professional competition platform ($19.99/month) with member revenue and engagement tools
- **RunstrRewards**: Dual subscription revenue model (team subscriptions + member revenue share)

### Business Model & Revenue
- **Team Platform**: $19.99/month for competition platform access
- **Member Revenue**: Percentage of member subscriptions ($1.99/month per member)
- **Event Fees**: Premium competitions with entry fees for larger prize pools
- **Future**: Premium tools, white label solutions, corporate wellness, API access

### Technical Architecture
```
HealthKit Data → Background Sync → Team Competitions → Lightning Wallet (CoinOS)
                               → Team-Branded Notifications → Real-time Leaderboards
```

## Development Philosophy

### Invisible-First Design
- **Background sync is primary** - App works without user intervention
- **Push notifications are the main UI** - Team-branded messages drive engagement
- **Minimal app interaction** - Only for permissions, team discovery, leaderboard details, scheduled event information, Bitcoin management
- **Real Bitcoin rewards** - Lightning Network integration, not fake tokens or points

### Code Standards
- **Files should be under 500 lines of code**
- **Simple, organized architecture**  
- **Modular components that can be easily understood**
- **Clear separation of concerns**
- **NO MOCK OR SAMPLE DATA** - All data must come from real sources (HealthKit, Supabase, user input)
- **Production-ready code only** - No placeholders, sample data, or fake content in production builds
- **Real data or empty state** - Show actual workout data or proper empty states, never fake data

### Key Principles
1. **Invisible by Design**: Users rarely open app - everything happens via background sync and push notifications
2. **Team-Branded Experience**: All notifications and interactions prominently feature team branding, not RunstrRewards
3. **Passive Competition**: Members compete automatically using their existing workout routines and apps
4. **Bitcoin-Native**: Real Lightning Network rewards, not fake points or tokens

## Git Commit Guidelines

### Commit Format
```
[emoji] [Component]: Clear description

Details:
- What was changed and why
- Files affected: List specific files modified
- Testing: ✅ Tested | ⚠️ Needs testing | 🧪 Testing in progress
- Build: ✅ Builds successfully | 🔧 Build issues fixed

Context: [Brief note about what triggered this change]
```

### Emoji Conventions
- 🚀 New feature - 🐛 Bug fix - 🔧 Configuration - 📱 UI/UX - ⚡ Performance
- 🏗️ Architecture - 📝 Documentation - ✅ Tests - 🔐 Security - 🧹 Cleanup - 💡 WIP

### Commit Triggers
Commit after: component complete, bug fixed, build succeeds, feature milestone, before breaks, after refactoring

### Special Notes
- Flag background sync changes
- Note Bitcoin/Lightning Network changes
- Highlight team subscription or revenue impacts

## Technical Requirements

### Core Features
- **HealthKit Background Sync**: Automatic workout data collection
- **Team Discovery**: In-app browsing + QR code direct linking
- **Team-Branded Notifications**: Push notifications with team branding
- **Lightning Wallet**: CoinOS-powered Bitcoin rewards
- **Team Management**: Leaderboard and event creation tools

### Platform Integrations
- Apple HealthKit, CoinOS Lightning Network, Push notifications, QR codes, Background tasks

### Anti-Cheat System
- HealthKit validation, heart rate correlation, cross-platform duplicate detection

### App Architecture
```
RunstrRewards/
├── Features/        # Discovery, Teams, Competitions, Wallet
├── Services/        # HealthKit sync, CoinOS, Push notifications
├── Models/          # Team, User, Competition, Event models
└── Shared/UI/       # Reusable components with team branding
```

### Data Flow
Discover Team → Subscribe → HealthKit Sync → Competition Processing → Bitcoin Rewards

## Key Metrics & Success
- **North Star**: Active team members with valid subscriptions syncing weekly
- **Technical**: 99%+ HealthKit sync, <24hr competition updates, zero payment vulnerabilities
- **Business**: 1,000+ members in 6mo, 50+ teams by month 12, $50k+ monthly revenue

## Competitive Positioning
**What We Are**: Invisible micro app, competition infrastructure, dual subscription platform, "Stripe for fitness competitions"
**What We're Not**: Fitness tracking app, social platform, daily-use app

## Development Priorities

### Phase 1 (MVP) - ✅ COMPLETE
- [x] Team discovery and subscription system
- [x] HealthKit background sync integration
- [x] Team pages with full branding and management
- [x] CoinOS Lightning wallet integration  
- [x] Team-branded push notifications
- [x] Real-time leaderboards and events
- [x] Anti-cheat and duplicate detection systems

### Phase 2 (Growth) - 🚧 IN PROGRESS
- [x] QR code team marketing system
- [x] Event management tools for teams
- [ ] Advanced team analytics dashboard
- [ ] Team revenue optimization features
- [ ] Corporate wellness integrations

### Phase 3 (Scale)
- [ ] White label solutions for large organizations
- [ ] Advanced team leaderboard and event formats with automation
- [ ] API access for third-party fitness platforms
- [ ] International expansion and multi-currency support

## Development Resources

- **Technical Insights**: See [LESSONS_LEARNED.md](./LESSONS_LEARNED.md) for detailed debugging solutions and architecture patterns
- **Daily Progress**: See [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) for session notes and decision rationale
- **Critical Patterns**: Navigation setup, container height constraints, modular architecture planning, **Xcode project file safety**

## Notes for Development

- **Prioritize invisible functionality** - the app should work without users opening it
- **Team branding must be prominent** in all notifications and experiences, not RunstrRewards branding
- **Keep the app minimal** - only core use cases: permissions, team discovery, leaderboard standings, event information, Bitcoin management
- **Bitcoin integration should be seamless** - users shouldn't need to understand Lightning Network complexity
- **Push notifications are the primary UI** - team-branded messages drive all engagement
- **QR codes are critical for growth** - make it trivial for teams to share direct signup links

Remember: We're building an invisible micro app for passive competition. Every decision should enable teams to engage their members through background sync and branded notifications while requiring minimal app interaction.

## Current MVP Status (Updated)

The app is 95% complete for MVP launch:
- ✅ HealthKit background sync working with automatic workout detection
- ✅ CoinOS Lightning Network integration complete with real Bitcoin transactions
- ✅ Team creation and management system with captain controls
- ✅ Real-time leaderboards and events with live position tracking
- ✅ Push notification system with team branding (not RunstrRewards branding)
- ✅ Anti-cheat and duplicate detection across platforms (Strava, Garmin, etc.)
- ✅ Bitcoin reward distribution through Lightning Network
- ✅ QR code team sharing for viral growth
- ✅ Background task management for iOS limitations
- ✅ Team wallet management for prize distribution

**Ready for App Store submission** - Only minor polish and testing needed.