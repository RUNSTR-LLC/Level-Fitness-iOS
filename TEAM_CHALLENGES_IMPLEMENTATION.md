# Team-Based Challenges & Events Implementation Plan

## Executive Summary

Transform RUNSTR REWARDS into a platform where teams are self-governing fitness economies. Teams earn revenue through event tickets and challenge arbitration fees while providing free events to drive engagement. Members join teams for free and participate in team-created events and peer-to-peer challenges, all settled via HealthKit data and Bitcoin.

## Core Concept

**"Teams as Fitness DAOs"** - Each team operates like a decentralized autonomous organization with its own wallet, events, challenges, and economy. Team captains are entrepreneurs who can monetize their community through:
- Virtual event ticket sales
- Challenge arbitration fees (5-10% of stakes)
- Sponsored competitions
- Premium team features

## The Business Model

### RUNSTR Platform Revenue:
- **Team Creation Fee**: $19.99/month paid by team captain to create/maintain team
- **Transaction Fees**: 2-3% of all Bitcoin flows through platform
- **Premium Features**: Advanced analytics, API access (future)
- **Enterprise Solutions**: White label for organizations (future)

### How Teams Make Money:
- **Event Ticket Sales**: Teams set their own event entry fees (500-5000 sats typical)
- **Challenge Arbitration Fees**: Teams take 5-10% of all challenge stakes
- **Sponsored Events**: Partner with brands for sponsored competitions (future)
- **NO membership fees**: Teams don't charge members to join

### Member Economics:
- **FREE to join any team**: Zero barrier to entry
- **Pay-per-participation**: Only pay when entering paid events or challenges
- **Earn Bitcoin**: Win events and challenges to be net positive
- **Choose engagement level**: Participate in free or paid activities

## Architecture Overview

```
Team Ecosystem:
├── Team Wallet (existing)
│   ├── Holds event entry fees
│   ├── Holds challenge stakes
│   └── Distributes prizes
├── Events (existing, enhanced)
│   ├── Free events (engagement)
│   ├── Paid events (revenue)
│   └── Sponsored events
├── Challenges (NEW)
│   ├── Member vs Member
│   ├── Open challenges
│   └── Team vs Team
└── Notification Inbox (NEW)
    ├── Event invites
    ├── Challenge requests
    └── Results & payouts
```

## Database Schema

```sql
-- Modify events table to support challenges
ALTER TABLE events
ADD COLUMN event_type VARCHAR(20) DEFAULT 'standard', -- 'standard', 'challenge', 'sponsored'
ADD COLUMN is_challenge BOOLEAN DEFAULT false,
ADD COLUMN challenger_id UUID REFERENCES profiles(id),
ADD COLUMN challenged_ids UUID[], -- Array for multiple opponents
ADD COLUMN arbitration_fee_percent INTEGER DEFAULT 10,
ADD COLUMN team_fee_collected INTEGER DEFAULT 0;

-- Notification inbox for persistent notifications
CREATE TABLE notification_inbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id),
    team_id UUID REFERENCES teams(id),
    
    -- Notification content
    type VARCHAR(50), -- 'event_invite', 'challenge_request', 'payment_needed', etc
    title TEXT NOT NULL,
    body TEXT,
    icon_url TEXT,
    
    -- Action handling
    action_type VARCHAR(50), -- 'accept_challenge', 'join_event', 'pay_entry'
    action_data JSONB, -- Flexible data for different action types
    
    -- Related entities
    from_user_id UUID REFERENCES profiles(id),
    event_id UUID REFERENCES events(id),
    
    -- Status tracking
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false,
    action_taken VARCHAR(50), -- 'accepted', 'declined', 'joined'
    expires_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acted_at TIMESTAMPTZ
);

-- Team wallet transactions for transparency
CREATE TABLE team_wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id),
    type VARCHAR(50), -- 'event_entry', 'challenge_stake', 'prize_payout', 'fee_collection'
    amount INTEGER NOT NULL, -- satoshis
    user_id UUID REFERENCES profiles(id),
    event_id UUID REFERENCES events(id),
    description TEXT,
    balance_after INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_inbox_user_unread ON notification_inbox(user_id, read, created_at DESC);
CREATE INDEX idx_inbox_team ON notification_inbox(team_id, created_at DESC);
CREATE INDEX idx_wallet_trans_team ON team_wallet_transactions(team_id, created_at DESC);
```

## Implementation Components

### 1. Enhanced Team Page

```swift
// TeamDetailViewController.swift - Modified structure
class TeamDetailViewController: UIViewController {
    
    // Existing sections
    private let headerView: TeamHeaderView
    private let leaderboardView: LeaderboardView
    
    // Enhanced events section
    private let eventsSection: EventsSection {
        // Now includes both events and challenges
        freeEvents: [Event]     // Drive engagement
        paidEvents: [Event]     // Generate revenue
        activeChallenges: [Challenge]  // P2P competitions
    }
    
    // New team wallet visibility
    private let walletSection: TeamWalletView {
        balance: Int // Current team wallet balance
        recentTransactions: [Transaction]
        upcomingPayouts: [Payout]
    }
}
```

### 2. Challenge Creation Flow

```swift
// ChallengeCreationViewController.swift
class ChallengeCreationViewController: UIViewController {
    
    // Challenge configuration
    private let opponentSelector: MemberPickerView  // Select 1+ opponents
    private let challengeType: UISegmentedControl   // Distance, Time, Total
    private let metricPicker: MetricSelectionView   // 5K, 10K, Weekly Miles
    private let durationPicker: DurationPicker      // Today, This Week, Custom
    
    // Stakes configuration
    private let stakesToggle: UISwitch
    private let stakesAmount: UITextField  // Sats per person
    private let teamFeeLabel: UILabel      // Shows team's arbitration fee
    
    // Create challenge
    func createChallenge() {
        // 1. Create challenge as special event type
        let challenge = Challenge(
            type: .challenge,
            teamId: currentTeam.id,
            challengerId: currentUser.id,
            challengedIds: selectedOpponents,
            stakes: stakesAmount,
            teamFee: currentTeam.arbitrationFee
        )
        
        // 2. Send notifications to challenged users
        for opponent in selectedOpponents {
            NotificationService.send(
                to: opponent,
                type: .challengeRequest,
                title: "\(currentUser.name) challenged you!",
                body: "\(challengeType) for \(stakes) sats",
                teamId: currentTeam.id,
                actionData: ["challenge_id": challenge.id]
            )
        }
        
        // 3. If stakes, show payment instructions
        if hasStakes {
            showPaymentInstructions(challenge)
        }
    }
}
```

### 3. Notification Inbox

```swift
// NotificationInboxViewController.swift
class NotificationInboxViewController: UIViewController {
    
    private let tableView = UITableView()
    private var notifications: [NotificationItem] = []
    private var groupedNotifications: [String: [NotificationItem]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotifications()
        markAllAsRead()
        clearBadge()
    }
    
    // Group notifications by date
    private func groupNotifications() {
        groupedNotifications = Dictionary(grouping: notifications) { notification in
            if Calendar.current.isDateInToday(notification.createdAt) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(notification.createdAt) {
                return "Yesterday"
            } else {
                return "Earlier"
            }
        }
    }
    
    // Handle different notification types
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notification = getNotification(at: indexPath)
        
        switch notification.type {
        case .challengeRequest:
            let cell = ChallengeRequestCell()
            cell.configure(notification)
            cell.onAccept = { self.acceptChallenge(notification) }
            cell.onDecline = { self.declineChallenge(notification) }
            return cell
            
        case .eventInvite:
            let cell = EventInviteCell()
            cell.configure(notification)
            cell.onJoin = { self.joinEvent(notification) }
            return cell
            
        case .paymentNeeded:
            let cell = PaymentRequestCell()
            cell.configure(notification)
            cell.onPay = { self.showPaymentInstructions(notification) }
            return cell
            
        case .resultAnnouncement:
            let cell = ResultCell()
            cell.configure(notification)
            return cell
            
        default:
            let cell = BasicNotificationCell()
            cell.configure(notification)
            return cell
        }
    }
}

// Notification cell types
class ChallengeRequestCell: UITableViewCell {
    func configure(_ notification: NotificationItem) {
        // Show challenger info
        avatarImageView.load(notification.fromUser.avatarUrl)
        titleLabel.text = "\(notification.fromUser.name) challenged you"
        
        // Show challenge details
        detailLabel.text = notification.body
        
        // Show team context
        teamLabel.text = "in \(notification.team.name)"
        
        // Action buttons if not acted on
        if !notification.actedOn {
            acceptButton.isHidden = false
            declineButton.isHidden = false
        } else {
            statusLabel.text = notification.actionTaken
        }
    }
}
```

### 4. Team Wallet Management

```swift
// TeamWalletService.swift
class TeamWalletService {
    
    // Event entry fees
    func collectEventEntry(userId: String, eventId: String, amount: Int) {
        // Add to team wallet
        addToWallet(amount, type: .eventEntry, userId: userId, eventId: eventId)
    }
    
    // Challenge stakes and fees
    func collectChallengeStake(userId: String, challengeId: String, amount: Int) {
        // Add stake to pool
        addToWallet(amount, type: .challengeStake, userId: userId, eventId: challengeId)
    }
    
    // Automated payouts
    func distributeEventPrizes(eventId: String) {
        let event = getEvent(eventId)
        let winners = calculateWinners(event)
        
        for (position, winner) in winners.enumerated() {
            let prize = calculatePrize(event.prizePool, position: position)
            payUser(winner.userId, amount: prize, reason: "Event #\(position + 1)")
        }
    }
    
    func settleChallenges(challengeId: String) {
        let challenge = getChallenge(challengeId)
        let winner = determineWinner(challenge)
        
        // Team keeps arbitration fee
        let teamFee = challenge.totalStakes * challenge.arbitrationFeePercent / 100
        let winnerPayout = challenge.totalStakes - teamFee
        
        // Pay winner
        payUser(winner.userId, amount: winnerPayout, reason: "Challenge won")
        
        // Record team earnings
        recordTeamEarnings(teamFee, type: .arbitrationFee, challengeId: challengeId)
    }
    
    // Transparency
    func getWalletHistory(teamId: String) -> [WalletTransaction] {
        // Return all transactions for team members to see
        return fetchTransactions(teamId: teamId, limit: 100)
    }
}
```

### 5. Captain Dashboard

```swift
// CaptainDashboardViewController.swift
class CaptainDashboardViewController: UIViewController {
    
    // Revenue overview
    private let revenueCard: RevenueCard {
        monthlyEventRevenue: Int
        monthlyChallengeRevenue: Int
        totalMembers: Int
        activeMembers: Int
    }
    
    // Event management
    private let eventControls: EventControlsView {
        // Create free events to drive engagement
        // Create paid events for revenue
        // Set entry fees and prize distributions
    }
    
    // Challenge settings
    private let challengeSettings: ChallengeSettingsView {
        enableChallenges: Bool
        arbitrationFeePercent: Int  // 5-20%
        maxStakeAmount: Int         // Prevent huge bets
        requireApproval: Bool       // Manual approval for challenges
    }
    
    // Payout management
    private let payoutQueue: PayoutQueueView {
        pendingPayouts: [Payout]
        scheduledPayouts: [Payout]
        completedPayouts: [Payout]
    }
}
```

## User Flows

### Flow 1: Creating a Team Challenge

```
1. Open team page
2. Tap "Challenges" section
3. Tap "Challenge Someone"
4. Select opponent(s) from team members
5. Choose challenge type (5K race, weekly miles, etc)
6. Set stakes (optional, goes to team wallet)
7. See team fee disclosure (e.g., "Team takes 10% fee")
8. Send challenge
9. Opponent gets push + inbox notification
10. Both pay stakes to team wallet
11. Challenge becomes active
12. HealthKit tracks performance
13. Auto-settlement at end date
14. Winner paid from team wallet (minus team fee)
15. Both get result notifications
```

### Flow 2: Joining a Paid Team Event

```
1. See event in team page
2. Tap to view details
3. See entry fee (e.g., 1000 sats)
4. Tap "Join Event"
5. Pay entry fee to team wallet
6. Get confirmation notification
7. Event starts at scheduled time
8. Compete via HealthKit tracking
9. Event ends
10. Prize distribution from team wallet
11. Get result + payout notification
```

### Flow 3: Team Captain Revenue Flow

```
1. Captain creates mix of free and paid events
2. Free events drive member engagement
3. Paid events generate revenue
4. Members create challenges (team earns fees)
5. View revenue dashboard
6. See wallet balance and history
7. Withdraw team earnings (minus member payouts)
8. Reinvest in bigger prize pools
```

## Today's Implementation Plan - Start Now

### What We're Building
A notification inbox + team challenges system that enables teams to monetize through event tickets and challenge arbitration fees. Members join free, captains pay $19.99/month to RUNSTR.

### Why This Order
1. **Notification Inbox First**: Foundation for all team activity
2. **Challenges as Events**: Reuse 90% of existing code
3. **Free Membership**: Remove friction for growth

---

## Day 1 (TODAY): Notification Inbox Backend
**Goal**: Create persistent notification storage that never loses user activity

### Morning Tasks (2-3 hours)

#### Task 1: Database Schema (30 min)
```sql
-- Run this migration immediately
CREATE TABLE notification_inbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    team_id UUID REFERENCES teams(id),
    type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    action_type VARCHAR(50),
    action_data JSONB,
    from_user_id UUID REFERENCES profiles(id),
    event_id UUID REFERENCES events(id),
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inbox_user_unread ON notification_inbox(user_id, read, created_at DESC);
CREATE INDEX idx_inbox_user_recent ON notification_inbox(user_id, created_at DESC);
```

#### Task 2: NotificationInboxService.swift (90 min)
Create `Services/NotificationInboxService.swift`:
```swift
import Foundation
import Supabase

class NotificationInboxService {
    static let shared = NotificationInboxService()
    private let supabase = SupabaseService.shared
    
    // Store notification (called whenever we send push)
    func storeNotification(
        userId: String,
        type: String,
        title: String,
        body: String,
        teamId: String? = nil,
        fromUserId: String? = nil,
        eventId: String? = nil,
        actionData: [String: Any]? = nil
    ) async throws {
        let data: [String: Any] = [
            "user_id": userId,
            "type": type,
            "title": title,
            "body": body,
            "team_id": teamId as Any,
            "from_user_id": fromUserId as Any,
            "event_id": eventId as Any,
            "action_data": actionData as Any
        ]
        
        try await supabase.client
            .from("notification_inbox")
            .insert(data)
            .execute()
    }
    
    // Get notifications for user
    func getNotifications(for userId: String, limit: Int = 50) async throws -> [NotificationItem] {
        let response = try await supabase.client
            .from("notification_inbox")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try JSONDecoder().decode([NotificationItem].self, from: response.data)
    }
    
    // Mark as read
    func markAsRead(_ notificationId: String) async throws {
        try await supabase.client
            .from("notification_inbox")
            .update(["read": true])
            .eq("id", value: notificationId)
            .execute()
    }
    
    // Get unread count for badge
    func getUnreadCount(for userId: String) async throws -> Int {
        let response = try await supabase.client
            .from("notification_inbox")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("read", value: false)
            .execute()
        
        return response.count ?? 0
    }
}
```

#### Task 3: Hook into existing NotificationService (30 min)
Modify `Services/NotificationService.swift`:
```swift
// Add to existing notification send methods
func sendTeamNotification(...) {
    // Existing push notification code...
    
    // NEW: Store in inbox
    Task {
        try await NotificationInboxService.shared.storeNotification(
            userId: userId,
            type: notificationType,
            title: title,
            body: body,
            teamId: teamId,
            actionData: actionData
        )
    }
}
```

### Afternoon Tasks (2-3 hours)

#### Task 4: NotificationInboxViewController.swift (90 min)
Create `Features/Notifications/NotificationInboxViewController.swift`:
```swift
import UIKit

class NotificationInboxViewController: UIViewController {
    private let tableView = UITableView()
    private var notifications: [NotificationItem] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        markAllAsRead()
        updateTabBarBadge()
    }
    
    private func setupUI() {
        title = "Notifications"
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Configure table
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        
        // Add refresh
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Layout
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func loadNotifications() {
        Task {
            do {
                let userId = AuthenticationService.shared.currentUserId!
                notifications = try await NotificationInboxService.shared.getNotifications(for: userId)
                
                await MainActor.run {
                    tableView.reloadData()
                    refreshControl.endRefreshing()
                }
            } catch {
                print("Failed to load notifications: \(error)")
            }
        }
    }
}
```

#### Task 5: Add to Tab Bar (30 min)
Modify `MainTabBarController.swift`:
```swift
// Add notifications tab
let notificationsVC = NotificationInboxViewController()
notificationsVC.tabBarItem = UITabBarItem(
    title: "Inbox",
    image: UIImage(systemName: "bell"),
    selectedImage: UIImage(systemName: "bell.fill")
)
let notificationsNav = UINavigationController(rootViewController: notificationsVC)

// Update viewControllers array
viewControllers = [teamsNav, competitionsNav, workoutsNav, notificationsNav, profileNav]

// Add badge update timer
Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
    Task {
        await self.updateNotificationBadge()
    }
}
```

### End of Day 1 Checklist
- [ ] Database migration run successfully
- [ ] NotificationInboxService created and working
- [ ] Notifications being stored when sent
- [ ] Basic inbox UI showing notifications
- [ ] Tab bar shows inbox with badge

---

## Day 2-3: Quick Wins Before Challenges

### Day 2 Morning: Polish Notification Inbox (2 hours)
- [ ] Create different cell types (challenge, event, result)
- [ ] Add accept/decline buttons to challenge cells
- [ ] Group by Today/Yesterday/Earlier
- [ ] Add swipe to delete
- [ ] Test with existing team events

### Day 2 Afternoon: Free Team Membership (2 hours)
- [ ] Hide subscription UI for members
- [ ] Show "Join Free" button instead
- [ ] Update team creation to emphasize revenue model
- [ ] Test free join flow

### Day 3: Prepare for Challenges (4 hours)
- [ ] Extend events table for challenge support
- [ ] Create Challenge model extension
- [ ] Add "Challenges" section to team page UI
- [ ] Create simple challenge creation modal

---

## Days 4-5: Implement Challenges

### Day 4: Challenge Creation Flow
**Morning:**
- [ ] Create ChallengeCreationModal
- [ ] Add opponent selection from team members
- [ ] Add stake amount input
- [ ] Show team arbitration fee

**Afternoon:**
- [ ] Wire up challenge creation to events table
- [ ] Send notification to challenged user
- [ ] Add challenge to team page
- [ ] Test challenge creation flow

### Day 5: Challenge Settlement
**Morning:**
- [ ] Extend EventProgressTracker for challenges
- [ ] Add winner determination logic
- [ ] Calculate team fee and winner payout

**Afternoon:**
- [ ] Test settlement with HealthKit data
- [ ] Verify team wallet transactions
- [ ] Send result notifications
- [ ] End-to-end challenge test

---

## Phase 1: Notification Inbox Foundation (Days 1-3)
**Goal**: Add persistent notification storage so users never miss team activity

### Day 1: Backend Infrastructure
```sql
-- Morning: Create database schema
CREATE TABLE notification_inbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id),
    team_id UUID REFERENCES teams(id),
    type VARCHAR(50),
    title TEXT NOT NULL,
    body TEXT,
    action_type VARCHAR(50),
    action_data JSONB,
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inbox_user_unread ON notification_inbox(user_id, read, created_at DESC);
```

```swift
// Afternoon: Create service layer
// NotificationInboxService.swift (100 lines)
class NotificationInboxService {
    static let shared = NotificationInboxService()
    
    func storeNotification(userId: String, type: String, title: String, body: String, actionData: [String: Any]?) async
    func getNotifications(for userId: String, limit: Int = 50) async -> [NotificationItem]
    func markAsRead(notificationId: String) async
    func getUnreadCount(for userId: String) async -> Int
    func deleteOldNotifications() async // Run daily cleanup
}
```

### Day 2: UI Components
```swift
// Morning: Create view controller
// NotificationInboxViewController.swift (150 lines)
class NotificationInboxViewController: UIViewController {
    private let tableView = UITableView()
    private var notifications: [NotificationItem] = []
    
    // Reuse existing UI patterns from EventCard
    func setupUI() {
        // Industrial design theme
        // Grouped by Today/Yesterday/Earlier
    }
}

// Afternoon: Create cell types
// NotificationCells.swift (100 lines)
class BasicNotificationCell: UITableViewCell { }
class ActionableNotificationCell: UITableViewCell {
    // With buttons for accept/decline/join
}
```

### Day 3: Integration
- Morning: Add notification tab to MainTabBarController
- Morning: Hook into existing NotificationService to store all push notifications
- Afternoon: Add badge management for unread count
- Afternoon: Test with existing team events and announcements

**Deliverable**: Working notification inbox showing all team activity

---

## Phase 2: Challenges as Team Events (Days 4-7)
**Goal**: Enable member-to-member challenges using existing event infrastructure

### Day 4: Database & Model Updates
```sql
-- Morning: Extend existing events table
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS event_subtype VARCHAR(20) DEFAULT 'standard',
ADD COLUMN IF NOT EXISTS is_challenge BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS challenger_id UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS challenged_user_ids UUID[],
ADD COLUMN IF NOT EXISTS challenge_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS team_arbitration_fee INTEGER DEFAULT 10;

-- No new tables needed! Challenges ARE events
```

```swift
// Afternoon: Extend Event model
extension Event {
    var isChallenge: Bool { eventSubtype == "challenge" }
    var challengerName: String? { /* fetch from challenger_id */ }
    var challengedNames: [String] { /* fetch from challenged_user_ids */ }
    var arbitrationFee: Int { team_arbitration_fee }
    
    func acceptChallenge(userId: String) async
    func declineChallenge(userId: String) async
}
```

### Day 5: Challenge Creation UI
```swift
// Morning: Simple challenge modal
// ChallengeCreationModal.swift (150 lines)
class ChallengeCreationModal: UIViewController {
    // Reuse existing UI components
    private let opponentPicker: UITableView // List team members
    private let challengeType = UISegmentedControl(items: ["5K Race", "Weekly Miles", "Daily Run"])
    private let stakesField = UITextField() // Optional stakes
    private let createButton = UIButton()
    
    func createChallenge() {
        // Create as special event type
        let event = Event(
            teamId: currentTeam.id,
            name: "Challenge: \(currentUser.name) vs \(opponent.name)",
            eventSubtype: "challenge",
            isChallenge: true,
            challengerId: currentUser.id,
            challengedUserIds: [opponent.id],
            entryFee: stakesAmount
        )
        
        // Send notification to opponent
        NotificationInboxService.storeNotification(
            userId: opponent.id,
            type: "challenge_request",
            title: "\(currentUser.name) challenged you!",
            body: "\(challengeType) for \(stakes) sats"
        )
    }
}
```

### Day 6: Challenge Section in Team Page
```swift
// Morning: Add challenges section to TeamDetailViewController
extension TeamDetailViewController {
    func setupChallengesSection() {
        // Add below existing events section
        challengesHeaderLabel.text = "Active Challenges"
        
        // Reuse EventCard UI for challenge display
        for challenge in activeChallenges {
            let card = EventCard()
            card.configure(with: challenge)
            card.showChallengeInfo() // Shows vs. instead of participants
        }
        
        // Add challenge button for members
        if !isCaptain {
            addChallengeButton()
        }
    }
}

// Afternoon: Challenge acceptance flow
extension NotificationInboxViewController {
    func acceptChallenge(_ notification: NotificationItem) {
        let challengeId = notification.actionData["event_id"]
        
        // Show payment if has stakes
        if let stakes = notification.actionData["stakes"] as? Int {
            showTeamWalletPayment(amount: stakes, eventId: challengeId)
        } else {
            // Direct acceptance for free challenges
            EventService.joinEvent(challengeId)
        }
    }
}
```

### Day 7: Settlement Integration
```swift
// Use existing EventProgressTracker
extension EventProgressTracker {
    func settleChallenge(_ event: Event) async {
        guard event.isChallenge else { return }
        
        // Get results from HealthKit (existing logic)
        let results = await getEventResults(event)
        
        // Determine winner
        let winner = results.max(by: { $0.value < $1.value })
        
        // Calculate payouts (team keeps fee)
        let totalPot = event.entryFee * event.participants.count
        let teamFee = totalPot * event.arbitrationFee / 100
        let winnerPayout = totalPot - teamFee
        
        // Use existing team wallet payout
        await TeamWalletService.payUser(
            userId: winner.userId,
            amount: winnerPayout,
            reason: "Challenge victory"
        )
        
        // Send result notifications
        for participant in event.participants {
            NotificationInboxService.storeNotification(
                userId: participant.userId,
                type: "challenge_result",
                title: participant == winner ? "🏆 You won!" : "Challenge Complete",
                body: "Results: \(results)"
            )
        }
    }
}
```

**Deliverable**: Working challenges between team members using existing event system

---

## Phase 3: Polish & Captain Tools (Days 8-10)
**Goal**: Add captain controls and polish the experience

### Day 8: Captain Revenue Dashboard
```swift
// Morning: Add to existing captain dashboard
extension CaptainDashboardViewController {
    func addChallengeStats() {
        // Add challenge revenue card
        let challengeRevenueCard = StatsCard()
        challengeRevenueCard.configure(
            title: "Challenge Revenue",
            value: "\(teamChallengeRevenue) sats",
            subtitle: "From \(completedChallenges) challenges"
        )
        
        // Add to existing stats grid
        statsGrid.addArrangedSubview(challengeRevenueCard)
    }
    
    func addChallengeSettings() {
        // Simple settings section
        let feeSlider = UISlider() // 5-20% arbitration fee
        let autoApproveSwitch = UISwitch() // Auto-approve challenges
        let maxStakeField = UITextField() // Maximum stake limit
    }
}
```

### Day 9: Free Membership Update
```swift
// Morning: Remove membership fees
extension TeamSubscriptionStatusView {
    func updateForFreeModel() {
        // Hide subscription UI
        subscriptionButton.isHidden = true
        
        // Show team wallet balance instead
        walletBalanceLabel.text = "Team Pool: \(teamWallet.balance) sats"
        walletBalanceLabel.isHidden = false
        
        // Show "Join Team" for non-members (free)
        if !isMember {
            joinButton.setTitle("Join Team (Free)", for: .normal)
            joinButton.isHidden = false
        }
    }
}

// Afternoon: Update team creation flow
extension TeamCreationWizardViewController {
    func updatePricingStep() {
        // Remove member subscription pricing
        // Add event pricing guidance
        pricingInfoLabel.text = """
        Teams earn revenue from:
        • Paid events (you set the price)
        • Challenge arbitration fees (5-20%)
        • Sponsored competitions
        
        Members join for free!
        """
    }
}
```

### Day 10: Testing & Bug Fixes
- Morning: End-to-end challenge flow testing
- Morning: Team wallet reconciliation testing
- Afternoon: Notification delivery testing
- Afternoon: Settlement accuracy verification
- Afternoon: Captain tool testing

**Deliverable**: Polished MVP with captain controls

---

## MVP Launch Checklist

### Required for Launch
- [x] Notification inbox working
- [x] Challenges work as team events
- [x] Team wallet handles challenge stakes
- [x] Settlement via HealthKit
- [x] Result notifications sent
- [x] Captain can set arbitration fee
- [x] Free team membership

### Can Ship Without (Post-MVP)
- [ ] Inter-team challenges
- [ ] Challenge statistics dashboard
- [ ] Automated dispute resolution
- [ ] Challenge templates
- [ ] Sponsored challenges
- [ ] API for external integrations

---

## Technical Implementation Details

### File Changes Summary
```
New Files (4 total, ~500 lines):
├── NotificationInboxService.swift (100 lines)
├── NotificationInboxViewController.swift (150 lines)
├── NotificationCells.swift (100 lines)
└── ChallengeCreationModal.swift (150 lines)

Modified Files (8 total, ~200 lines of changes):
├── MainTabBarController.swift (+20 lines - add notification tab)
├── TeamDetailViewController.swift (+40 lines - add challenges section)
├── Event.swift (+30 lines - challenge properties)
├── EventProgressTracker.swift (+30 lines - challenge settlement)
├── CaptainDashboardViewController.swift (+30 lines - challenge stats)
├── TeamSubscriptionStatusView.swift (+20 lines - free membership)
├── NotificationService.swift (+20 lines - store to inbox)
└── supabase_schema.sql (+10 lines - minimal schema changes)
```

### Database Migrations
```sql
-- Single migration for MVP
BEGIN;

-- Add notification inbox
CREATE TABLE IF NOT EXISTS notification_inbox (...);

-- Extend events for challenges  
ALTER TABLE events ADD COLUMN IF NOT EXISTS ...;

-- Add indexes
CREATE INDEX IF NOT EXISTS ...;

COMMIT;
```

### Risk Mitigation
1. **Reuse existing code**: 90% of functionality exists
2. **Incremental rollout**: Each phase can ship independently
3. **Feature flags**: Can disable challenges per team if issues
4. **Manual overrides**: Captains can resolve disputes
5. **Simple payments**: Use existing team wallet flow

---

## Success Metrics for MVP

### Week 1 Goals
- 10 teams enable challenges
- 50 challenges created
- 80% completion rate
- Zero payment issues

### Month 1 Goals
- 100 teams using challenges
- 500 challenges completed
- $500 in challenge fees collected
- 4.5+ user satisfaction

This phased approach delivers value incrementally while minimizing risk and complexity.

## Revenue Projections

### Per Active Team (50 members)
```
Free Events: 2/week (engagement drivers)
Paid Events: 1/week @ 1000 sats entry = 50,000 sats/week
Challenges: 20/week @ 500 sats avg, 10% fee = 1,000 sats/week
Monthly Team Revenue: ~200,000 sats (~$200)

RUNSTR Platform Fee (3%): ~$6/team/month
```

### At Scale (1,000 active teams)
```
Team Revenue: $200,000/month flowing through platform
RUNSTR Fees: $6,000/month (3% of flow)
Premium Teams: 200 @ $19.99 = $4,000/month
Total RUNSTR Revenue: ~$10,000/month
```

## Key Success Factors

### For Teams
- Easy to create engaging events
- Transparent wallet management
- Fair arbitration system
- Revenue generation tools
- Community building features

### For Members
- Free to join and participate
- Fair competition via HealthKit
- Real Bitcoin rewards
- Never miss notifications
- Trust in team arbitration

### For RUNSTR
- Teams become self-sustaining
- Network effects drive growth
- Multiple revenue streams
- Reduced arbitration burden
- Scalable platform model

## Risk Mitigation

### Challenge Disputes
- HealthKit data is source of truth
- Captain has final say
- Team can vote on disputes
- Bad actors banned from team

### Team Wallet Security
- Multi-sig for large withdrawals
- Daily withdrawal limits
- Transparent transaction history
- Member payout priority

### Regulatory Compliance
- Teams are independent entities
- Skill-based competitions only
- Clear terms of service
- Age verification

## Competitive Advantages

1. **Decentralized Model**: Teams run themselves
2. **Built-in Monetization**: Teams earn from day one
3. **Trust Through Transparency**: All wallet transactions visible
4. **Existing Infrastructure**: 90% already built
5. **Network Effects**: More teams = more value

## Conclusion

By making teams the arbitrators and revenue centers, RUNSTR REWARDS becomes a platform for thousands of fitness micro-economies. Teams are incentivized to create engaging content (events and challenges) while RUNSTR provides the infrastructure. This model scales naturally, reduces central overhead, and creates aligned incentives for all parties.

The notification inbox ensures users never miss important team activity, while the team wallet system handles all payments transparently. This approach transforms RUNSTR from a centralized competition platform into a decentralized ecosystem where teams thrive independently.