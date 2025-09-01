# RunstrRewards - The Invisible Micro App for Team-Based Fitness Competition

## Project Vision

**RunstrRewards is the invisible micro app that turns fitness into Bitcoin-earning competitions.** Users join teams for free, sync workouts automatically in the background, and earn real Bitcoin rewards through team-branded competitions and peer-to-peer challenges - all without needing to actively use the app.

### Core Value Proposition
- **Members**: Join teams for free, compete using existing workout data, earn Bitcoin through events, challenges, and loyalty rewards
- **Teams**: Create leagues ($5.99 setup fee), earn through virtual event tickets and P2P challenge arbitration
- **RunstrRewards**: Revenue from team creation fees, exit fees, and platform transaction facilitation

### Business Model & Revenue
- **Team Creation**: $5.99 one-time fee to create a league (free during development)
- **P2P Challenge Arbitration**: Teams earn fees facilitating member-vs-member competitions
- **Exit Fees**: Members pay RUNSTR when switching teams (promotes strategic team selection)
- **Virtual Event Tickets**: Prize pool funding through event participation fees
- **Future**: Premium tools, white label solutions, corporate wellness, API access

### Technical Architecture
```
HealthKit Data → Background Sync → LEAGUE Leaderboards → Lightning Wallet (CoinOS)
                               → P2P Challenges → Team Discovery Intelligence
                               → Team-Branded Notifications → Exit Fee Processing
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
5. **Strategic Team Movement**: Exit fees create mercenary dynamics balanced by team loyalty rewards
6. **LEAGUE Competition**: Teams create leagues with intelligent member discovery and performance analytics

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
- Highlight P2P challenge or exit fee impacts
- Flag LEAGUE branding and team discovery changes

## Technical Requirements

### Core Features
- **HealthKit Background Sync**: Automatic workout data collection
- **Team Discovery Intelligence**: Performance analytics, member stats, prize pool data for strategic team selection
- **LEAGUE Competition**: Team-created leagues with branded leaderboards and events
- **P2P Challenge System**: Member-vs-member competitions with team arbitration
- **Lightning Wallet**: CoinOS-powered Bitcoin rewards and exit fee processing
- **Team Management**: Event creation, challenge arbitration, loyalty reward distribution

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
Discover Team → Join Free → HealthKit Sync → LEAGUE Competition → P2P Challenges → Bitcoin Rewards → Strategic Team Switching (Exit Fees)

## Key Metrics & Success
- **North Star**: Active team members earning Bitcoin through competitions and challenges
- **Technical**: 99%+ HealthKit sync, <24hr competition updates, zero payment vulnerabilities
- **Business**: 1,000+ members in 6mo, 200+ teams by month 12, $75k+ monthly revenue from fees
- **Game Theory**: Healthy team switching rates balanced by loyalty program retention

## Competitive Positioning
**What We Are**: Invisible micro app, LEAGUE competition infrastructure, P2P challenge facilitator, "Bitcoin sportsbook for fitness"
**What We're Not**: Fitness tracking app, social platform, daily-use app, subscription retention platform

## Development Priorities

### Phase 1 (MVP) - ✅ COMPLETE
- [x] Free team joining and discovery system
- [x] HealthKit background sync integration
- [x] LEAGUE creation with team branding and management
- [x] CoinOS Lightning wallet integration with exit fee processing
- [x] Team-branded push notifications
- [x] Real-time leaderboards and events
- [x] P2P challenge system with team arbitration
- [x] Anti-cheat and duplicate detection systems

### Phase 2 (Growth) - 🚧 IN PROGRESS
- [x] QR code team marketing system
- [x] Event management and virtual ticket sales
- [x] Team discovery intelligence with performance analytics
- [ ] Loyalty reward system to counteract mercenary behavior
- [ ] Advanced team revenue optimization features
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

## Game Theory & Strategic Design

### Member Incentives
- **Performance Stratification**: Fast runners seek dominant positions, slower runners target smaller teams
- **Economic Optimization**: All users seek maximum Bitcoin earning potential through events and challenges
- **Strategic Movement**: Exit fees create calculated team-switching decisions
- **Loyalty Balance**: Teams offer rewards to retain valuable performers

### Team Captain Strategy
- **Member Quality vs Quantity**: Balance elite performers with participation volume
- **Revenue Streams**: Event tickets, P2P arbitration fees, member retention
- **Market Competition**: Compete on prize pools, performance stats, earning opportunities
- **LEAGUE Positioning**: Create compelling competition formats and loyalty programs

### Platform Economics
- **Team Creation**: $5.99 fee encourages league proliferation (free during development)
- **Exit Fee Monetization**: Profit from natural member movement between teams
- **Network Effects**: More teams = more switching opportunities = more revenue
- **Market Efficiency**: Performance-based sorting with strategic friction

## Notes for Development

- **Prioritize invisible functionality** - the app should work without users opening it
- **LEAGUE branding must be prominent** - leaderboards and competitions feature team identity, not RunstrRewards
- **Keep the app minimal** - only core use cases: permissions, team discovery, LEAGUE standings, challenge management, Bitcoin/exit fee processing
- **Team discovery intelligence** - show performance metrics, member counts, prize pools to enable strategic decisions
- **P2P challenge system** - seamless member-vs-member betting with team arbitration
- **Exit fee processing** - smooth team switching with clear cost communication
- **Push notifications are the primary UI** - team-branded messages drive all engagement
- **QR codes are critical for growth** - make it trivial for teams to share direct signup links

Remember: We're building an invisible micro app for strategic fitness competition. Every decision should enable the mercenary dynamics that drive team movement while giving teams tools to retain valuable members through loyalty rewards and superior earning opportunities.

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