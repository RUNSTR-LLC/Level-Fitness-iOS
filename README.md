# RunstrRewards - The Invisible Micro App for Fitness Competition

**RunstrRewards is the invisible micro app that turns fitness into Bitcoin-earning competitions.** Members subscribe to teams, sync workouts automatically in the background, and earn real Bitcoin rewards through team-branded competitions - all without needing to actively use the app.

## How It Works

**For Members ($1.99/month to teams):**
1. Discover and subscribe to teams via QR codes or in-app browsing
2. Authorize HealthKit access for automatic background workout sync
3. Receive team-branded push notifications about competitions and rewards
4. Earn real Bitcoin rewards automatically through Lightning Network

**For Teams ($19.99/month to RunstrRewards):**
1. Create team page and exclusive competitions/leaderboards 
2. Set up Bitcoin prize pools and reward structures
3. Market team via QR codes on social media
4. Earn recurring revenue from member subscriptions

## The "Invisible" Experience

Members rarely open the app. The entire experience happens through:
- **Background HealthKit sync** - Workouts automatically count toward competitions
- **Team-branded push notifications** - All engagement via notifications, not app UI
- **Automatic Bitcoin rewards** - Lightning Network payouts without manual claims

**Core App Usage (Only 4 reasons to open the app):**
1. **Permissions** - Initial HealthKit and notification setup
2. **Team Discovery** - Browse and subscribe to new teams  
3. **Leaderboard Details** - View detailed competition standings
4. **Bitcoin Management** - Send Bitcoin out of wallet

## Technical Architecture

- **iOS Swift** with modular architecture (< 500 lines per file)
- **HealthKit Integration** for automatic workout data collection
- **CoinOS Lightning Network** for real Bitcoin rewards (not fake tokens)
- **Background Task Management** for iOS limitations
- **Push Notifications** with team branding (not RunstrRewards branding)
- **Real-time Leaderboards** with live position tracking
- **Anti-cheat Systems** with cross-platform duplicate detection

## Current Status

**MVP is 95% complete and ready for App Store submission:**
- ✅ Full HealthKit background sync working
- ✅ Real Bitcoin transactions via Lightning Network
- ✅ Team creation, management, and member subscriptions
- ✅ Competition/leaderboard system with live tracking
- ✅ Team-branded push notification system
- ✅ QR code sharing for viral team growth
- ✅ Anti-cheat and duplicate detection

## Business Model

**Dual Subscription Revenue:**
- Teams pay RunstrRewards $19.99/month for platform access
- Members pay teams $1.99/month for exclusive competitions
- RunstrRewards takes percentage of member subscription revenue
- Teams keep 100% of premium event entry fees

## Development Setup

1. Clone repository
2. Open `RunstrRewards.xcodeproj` in Xcode
3. Configure HealthKit entitlements
4. Set up Supabase backend connection
5. Configure CoinOS Lightning Network credentials
6. Build and run on device (HealthKit requires physical device)

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete project vision and technical details
- **[LEVEL_FITNESS_EXPLAINED.md](LEVEL_FITNESS_EXPLAINED.md)** - Business model deep dive
- **[PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md)** - Development timeline

## Key Innovation

Unlike fitness apps that try to replace user habits, RunstrRewards enhances existing habits invisibly. Users keep their favorite workout apps (Strava, Apple Fitness, etc.) while earning real Bitcoin rewards for team competitions automatically in the background.

**This is not a fitness tracking app - it's competition infrastructure that works invisibly.**