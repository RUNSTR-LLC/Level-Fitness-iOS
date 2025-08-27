# P2P Challenges Implementation Plan for RUNSTR REWARDS

## Executive Summary

Add peer-to-peer fitness challenges to RUNSTR REWARDS with minimal changes to existing architecture. Users can challenge each other directly with Bitcoin stakes, RUNSTR acts as the trusted arbitrator, and everything settles automatically via HealthKit data.

## Core Concept

**"Venmo for Fitness Bets"** - Challenge friends to fitness competitions with real Bitcoin stakes. RUNSTR holds funds in escrow, monitors performance via HealthKit, and automatically distributes winnings.

## Simplified MVP Approach

### The Simplest Possible Flow
```
1. User A challenges User B (via push notification)
2. Both users pay X sats to RUNSTR's wallet
3. RUNSTR monitors the challenge via HealthKit
4. RUNSTR pays winner automatically
```

No complex escrow tracking, no invoice generation - just simple payments to RUNSTR's wallet with automatic settlement.

## Payment Flow & Escrow System

### The Escrow Model
```
User A (Challenger) → RUNSTR Escrow → Winner
User B (Challenged) → RUNSTR Escrow → Winner
```

### Detailed Payment Flow

#### 1. Challenge Creation
```swift
// User A creates challenge
Challenge {
    type: "5K Race"
    stakes: 5000 sats
    duration: "This Week"
}
→ Challenge created (no payment yet)
→ Push notification to User B
```

#### 2. Challenge Acceptance & Escrow
```swift
// User B accepts challenge
if (challenge.hasStakes) {
    // Both users must deposit stakes
    showPaymentInstructions(
        message: "Send 5000 sats to escrow to confirm challenge",
        lightningAddress: "challenges@runstrrewards.com", 
        invoiceId: "challenge_abc123_userB"
    )
}
→ User B sends 5000 sats to RUNSTR escrow
→ User A notified to complete their deposit
→ User A sends 5000 sats to RUNSTR escrow
→ Challenge becomes ACTIVE
```

#### 3. Escrow Management
```swift
// RUNSTR Escrow Account Structure
EscrowTransaction {
    challengeId: "abc123"
    userA_deposit: 5000 sats (received)
    userB_deposit: 5000 sats (received)
    totalPot: 10000 sats
    runstrFee: 500 sats (5%)
    winnerPayout: 9500 sats
    status: "held|settled|refunded"
}
```

#### 4. Settlement Process
```swift
// Automatic settlement via HealthKit
Challenge.endDate reached →
    HealthKitService.comparePerformance() →
    DetermineWinner() →
    if (winner) {
        LightningWallet.send(9500 sats → winner)
        LightningWallet.send(500 sats → RUNSTR fee wallet)
        NotificationService.sendResults(both users)
    } else if (tie) {
        LightningWallet.send(4750 sats → each user)
        LightningWallet.send(500 sats → RUNSTR)
    }
```

### Simplified Payment Instructions (MVP)

#### Challenge Acceptance Screen
```
┌─────────────────────────────────────┐
│  💪 CHALLENGE FROM JOHN             │
│                                     │
│  Type: 5K Race                      │
│  Stakes: 1000 sats (~$1.00)        │
│  Duration: This Week                │
│                                     │
│  "I bet I can run a faster 5K!"    │
│                                     │
│  ⚡ TO ACCEPT THIS CHALLENGE:       │
│                                     │
│  Send exactly 1000 sats to:         │
│  runstr@getalby.com                │
│                                     │
│  Memo: challenge_abc123_sarah       │
│                                     │
│  [I've Paid] [Copy Address]         │
│  [Decline Challenge]                │
└─────────────────────────────────────┘
```

#### Payment Status Screen
```
┌─────────────────────────────────────┐
│  CHALLENGE PAYMENT STATUS           │
│                                     │
│  Your Payment: ✅ 1000 sats        │
│  John's Payment: ⏳ Pending...     │
│                                     │
│  Total Prize Pool: 2,000 sats      │
│  Winner Takes: 1,900 sats          │
│  RUNSTR Fee: 100 sats (5%)         │
│                                     │
│  Challenge starts when both         │
│  players have paid.                 │
└─────────────────────────────────────┘
```

## Notification Inbox - Critical Component

### Why Notification Inbox is Essential

Push notifications disappear, but users need a persistent place to see and act on challenges. The notification inbox becomes the command center for all P2P challenges and RUNSTR activity.

### Notification Inbox UI

```
┌─────────────────────────────────────┐
│  🔔 NOTIFICATIONS (3 new)           │
├─────────────────────────────────────┤
│  Today                              │
│  ⚡ John challenged you to 5K race  │
│     1000 sats stake · 2 hrs ago    │
│     [Accept] [Decline]              │
│                                     │
│  📊 You moved up to #5 on team      │
│     Boston Runners · 4 hrs ago     │
│                                     │
│  Yesterday                          │
│  ✅ You won 1900 sats vs Sarah!    │
│     5K: 22:30 vs 24:15 · View →    │
│                                     │
│  💰 Team event starting tomorrow    │
│     Marathon Challenge · Join →     │
│                                     │
│  🏃 Mike accepted your challenge    │
│     Waiting for payments · 1 day ago│
└─────────────────────────────────────┘
```

### Notification Flow
```
Push Notification → Notification Inbox → Action → Result
                          ↑
                    (Persistent storage)
```

Every push notification gets stored in the inbox so users can:
- See challenges they missed
- Take action when convenient  
- Review challenge history
- Track payment status
- Never lose important notifications

## Implementation Architecture

### Database Schema Updates

```sql
-- Super simple P2P challenges table (MVP)
CREATE TABLE p2p_challenges (
    id UUID PRIMARY KEY,
    challenger_id UUID REFERENCES profiles(id),
    challenged_id UUID REFERENCES profiles(id),
    
    -- Challenge details
    type VARCHAR(20), -- '5k_race', 'weekly_miles', 'daily_run'
    target_value DECIMAL, -- 5 (for 5K), 50 (for 50 miles)
    end_date TIMESTAMPTZ,
    
    -- Payment tracking (simple)
    stake_amount INTEGER, -- sats per person
    challenger_paid BOOLEAN DEFAULT false,
    challenged_paid BOOLEAN DEFAULT false,
    
    -- Results
    winner_id UUID REFERENCES profiles(id),
    challenger_result DECIMAL,
    challenged_result DECIMAL,
    payout_completed BOOLEAN DEFAULT false,
    
    -- Status
    status VARCHAR(20), -- 'pending', 'active', 'completed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification inbox table (stores all notifications)
CREATE TABLE notification_inbox (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES profiles(id),
    
    -- Notification details
    type VARCHAR(50), -- 'challenge_received', 'challenge_won', etc
    title TEXT,
    body TEXT,
    
    -- Action data (for buttons)
    action_type VARCHAR(50), -- 'accept_challenge', 'view_details'
    action_data JSONB, -- {challenge_id: 'abc123', amount: 1000}
    
    -- Related entities
    from_user_id UUID REFERENCES profiles(id),
    challenge_id UUID REFERENCES p2p_challenges(id),
    
    -- Status
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false, -- Did they accept/decline?
    expires_at TIMESTAMPTZ, -- For time-sensitive actions
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick queries
CREATE INDEX idx_notifications_user_unread 
ON notification_inbox(user_id, read, created_at DESC);

-- Modify existing challenges table for P2P support (if using existing table)
ALTER TABLE challenges 
ADD COLUMN challenge_type VARCHAR(20) DEFAULT 'team', -- 'team' or 'p2p'
ADD COLUMN challenger_id UUID REFERENCES profiles(id),
ADD COLUMN challenged_id UUID REFERENCES profiles(id),
ADD COLUMN challenger_deposited BOOLEAN DEFAULT false,
ADD COLUMN challenged_deposited BOOLEAN DEFAULT false,
ADD COLUMN escrow_amount INTEGER, -- sats per person
ADD COLUMN total_pot INTEGER, -- total sats in escrow
ADD COLUMN runstr_fee INTEGER, -- our 5% cut
ADD COLUMN winner_id UUID REFERENCES profiles(id),
ADD COLUMN settlement_status VARCHAR(20), -- 'pending', 'settled', 'refunded'
ADD COLUMN settlement_tx_id TEXT, -- Lightning payment ID
ADD COLUMN challenge_message TEXT; -- Optional trash talk

-- Make team_id nullable for P2P challenges
ALTER TABLE challenges 
ALTER COLUMN team_id DROP NOT NULL;

-- Add challenge notifications table
CREATE TABLE challenge_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenge_id UUID REFERENCES challenges(id),
    user_id UUID REFERENCES profiles(id),
    type VARCHAR(50), -- 'challenge_received', 'deposit_pending', 'challenge_started', etc
    message TEXT,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Escrow tracking table
CREATE TABLE challenge_escrow (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenge_id UUID REFERENCES challenges(id) UNIQUE,
    challenger_invoice_id TEXT,
    challenged_invoice_id TEXT,
    challenger_payment_hash TEXT,
    challenged_payment_hash TEXT,
    challenger_paid_at TIMESTAMPTZ,
    challenged_paid_at TIMESTAMPTZ,
    total_amount INTEGER,
    fee_amount INTEGER,
    settlement_amount INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    settled_at TIMESTAMPTZ
);
```

### Simplified Service Architecture (MVP)

```swift
// P2PChallengeService.swift (200 lines max)
class P2PChallengeService {
    
    // Challenge lifecycle (simple)
    func createChallenge(
        from: String,
        to: String,
        type: String,
        stakes: Int
    ) -> Challenge
    
    func acceptChallenge(challengeId: String)
    func declineChallenge(challengeId: String)
    
    // Payment (super simple for MVP)
    func getPaymentInstructions(challengeId: String, userId: String) -> String {
        return "Pay \(stakes) sats to runstr@getalby.com with memo: challenge_\(challengeId)_\(userId)"
    }
    
    func markPaid(challengeId: String, userId: String) // Manual for MVP
    
    // Progress & Settlement
    func checkProgress(challengeId: String) // Called by HealthKit sync
    func settleChallenge(challengeId: String) // Compare data, pay winner
}

// NotificationInboxService.swift
class NotificationInboxService {
    
    // Core notification management
    func sendNotification(
        to userId: String,
        type: NotificationType,
        title: String,
        body: String,
        actionData: [String: Any]? = nil
    ) {
        // 1. Send push notification
        PushNotificationService.send(to: userId, title: title, body: body)
        
        // 2. Store in inbox
        storeInInbox(userId, type, title, body, actionData)
        
        // 3. Update badge count
        updateBadgeCount(for: userId)
    }
    
    // Inbox management
    func getNotifications(for userId: String) -> [NotificationItem]
    func markAsRead(notificationId: String)
    func markAsActedOn(notificationId: String)
    func getUnreadCount(for userId: String) -> Int
    
    // Cleanup
    func deleteOldNotifications() // Run daily
}
```

### Push Notification Strategy

```swift
// ChallengeNotificationHandler.swift
extension NotificationService {
    
    enum ChallengeNotificationType {
        case challengeReceived(from: String, type: String, stakes: Int?)
        case depositRequired(amount: Int)
        case opponentDeposited
        case challengeStarted
        case progressUpdate(ahead: Bool, by: Double)
        case challengeWon(amount: Int)
        case challengeLost
        case challengeTied(amount: Int)
    }
    
    func sendChallengeNotification(
        to userId: String,
        type: ChallengeNotificationType
    ) {
        switch type {
        case .challengeReceived(let from, let challengeType, let stakes):
            send(
                title: "🎯 New Challenge!",
                body: "\(from) challenged you to a \(challengeType)" + 
                      (stakes != nil ? " for \(stakes!) sats!" : "!"),
                action: "View Challenge"
            )
            
        case .depositRequired(let amount):
            send(
                title: "⚡ Payment Required",
                body: "Send \(amount) sats to confirm your challenge",
                action: "Pay Now"
            )
            
        case .challengeWon(let amount):
            send(
                title: "🏆 Victory!",
                body: "You won \(amount) sats! Funds sent to your wallet.",
                action: "View Results"
            )
        // ... etc
        }
    }
}
```

## UI Components

### 1. Notification Inbox (NEW - Critical Component)

```swift
// NotificationInboxViewController.swift
class NotificationInboxViewController: UIViewController {
    
    private let tableView = UITableView()
    private var notifications: [NotificationItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotifications()
        markAllAsRead() // Clear badge when opened
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notification = notifications[indexPath.row]
        
        switch notification.type {
        case .challengeReceived:
            // Show accept/decline buttons
            let cell = ChallengeNotificationCell()
            cell.configure(notification)
            cell.acceptAction = { self.acceptChallenge(notification.challengeId) }
            cell.declineAction = { self.declineChallenge(notification.challengeId) }
            return cell
            
        case .paymentNeeded:
            // Show payment instructions
            let cell = PaymentNotificationCell()
            cell.configure(notification)
            cell.payAction = { self.showPaymentInstructions(notification.challengeId) }
            return cell
            
        default:
            // Basic info cell
            let cell = BasicNotificationCell()
            cell.configure(notification)
            return cell
        }
    }
}

// NotificationCell.swift - Reusable cells for different notification types
class ChallengeNotificationCell: UITableViewCell {
    func configure(_ notification: NotificationItem) {
        avatarView.image = notification.fromUser.avatar
        titleLabel.text = "\(notification.fromUser.name) challenged you"
        detailLabel.text = "5K Race · 1000 sats stake"
        timeLabel.text = notification.timeAgo
        
        if !notification.actedOn {
            acceptButton.isHidden = false
            declineButton.isHidden = false
        }
        
        // Highlight unread
        backgroundColor = notification.read ? .clear : UIColor.blue.withAlphaComponent(0.05)
    }
}
```

### 2. Tab Bar Integration (Add Notification Badge)

```swift
// MainTabBarController.swift
class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        startNotificationBadgeUpdates()
    }
    
    func startNotificationBadgeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.updateNotificationBadge()
        }
    }
    
    func updateNotificationBadge() {
        let unreadCount = NotificationInboxService.shared.getUnreadCount()
        
        // Add badge to profile tab or dedicated notifications tab
        if let notificationsTab = viewControllers?[3] {
            notificationsTab.tabBarItem.badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
        }
    }
}
```

### 3. Challenge Button on Member Cards

```swift
// In TeamMembersListView.swift
class MemberCellView: UIView {
    private let challengeButton = UIButton()
    
    func configure(member: TeamMember) {
        // Add challenge button with bolt icon
        challengeButton.setImage(UIImage(systemName: "bolt.circle"), for: .normal)
        challengeButton.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)
    }
    
    @objc private func challengeTapped() {
        // Open simple challenge modal
        let modal = SimpleChallengeModal()
        modal.opponent = member
        present(modal)
    }
}
```

### 4. Simple Challenge Configuration Modal

```swift
// SimpleChallengeModal.swift (MVP - super simple)
class SimpleChallengeModal: UIViewController {
    
    var opponent: User!
    
    // Just 3 inputs for MVP
    private let challengeType = UISegmentedControl(items: ["5K Race", "Weekly Miles", "Daily Run"])
    private let stakesField = UITextField() // "1000" sats
    private let durationPicker = UISegmentedControl(items: ["Today", "This Week"])
    
    @IBAction func sendChallenge() {
        let challenge = P2PChallengeService.shared.createChallenge(
            from: currentUser.id,
            to: opponent.id,
            type: challengeType.selectedSegmentIndex,
            stakes: Int(stakesField.text) ?? 0
        )
        
        // Send notification to opponent
        NotificationInboxService.shared.sendNotification(
            to: opponent.id,
            type: .challengeReceived,
            title: "\(currentUser.name) challenged you!",
            body: "\(challengeType.titleForSegment) for \(stakesField.text) sats",
            actionData: ["challenge_id": challenge.id]
        )
        
        dismiss()
    }
}
```

### 5. Active Challenges View

```swift
// ChallengeProgressView.swift (reuse EventProgressView)
class ChallengeProgressView: UIView {
    func configure(challenge: Challenge, userProgress: Double, opponentProgress: Double) {
        // Show both users' progress
        // Live leaderboard style
        // Time remaining
        // Current stakes/pot
    }
}
```

## Simplified User Journey (With Notification Inbox)

### Complete Flow: Challenge with Stakes

```
John's Side (Challenger):
1. Taps Sarah in team members list
2. Challenge button → Simple modal opens
3. Selects: "5K Race", "1000 sats", "This Week"
4. Taps "Send Challenge"
5. Gets payment instructions
6. Pays 1000 sats to runstr@getalby.com
7. Notification created: "Waiting for Sarah to accept"

Sarah's Side (Challenged):
1. Receives push: "John challenged you to a 5K race!"
2. Opens app later (badge shows on notifications tab)
3. Opens notification inbox
4. Sees challenge at top with [Accept] [Decline] buttons
5. Taps Accept
6. Gets payment instructions screen
7. Pays 1000 sats
8. Challenge becomes active

During the Week:
- Both run their 5Ks
- HealthKit tracks automatically
- Progress notifications in inbox
- Can check standings anytime

Settlement:
- Sunday night: Auto-settlement runs
- John ran 22:30, Sarah ran 24:15
- John wins 1900 sats (RUNSTR keeps 100)
- Both get notifications with results
```

### Key Difference: Never Miss a Challenge

**Without Notification Inbox:**
- Miss the push = miss the challenge
- No way to see pending challenges
- Confusion about what happened

**With Notification Inbox:**
- All challenges stored persistently
- Badge reminds you to check
- Can accept/decline at your convenience
- Full history of all activity

## Anti-Cheat & Dispute Resolution

### Automated Verification
- HealthKit data must be continuous
- Heart rate data required for runs
- Statistical anomaly detection
- Cross-reference with typical performance

### Dispute Process
1. Auto-flag suspicious results
2. 24-hour dispute window
3. RUNSTR reviews HealthKit data
4. Decision is final
5. Bad actors banned from stakes challenges

### Refund Scenarios
- Opponent doesn't deposit within 48 hours → Full refund
- Technical issues prevent completion → Full refund to both
- Proven cheating → Funds to honest party + ban cheater
- Natural disaster/emergency → Case-by-case basis

## Revenue Model

### Transaction Fees
- 5% of challenge stakes (minimum 100 sats)
- Example: 10,000 sat challenge = 500 sat fee

### Premium Features ($4.99/month)
- Unlimited challenges (vs 5 free/month)
- Advanced challenge types
- Challenge history & stats
- Priority dispute resolution

### Projected Revenue
```
1,000 users, 20% engagement:
- 200 active challengers
- 10 challenges/month each = 2,000 challenges
- Average stakes: 2,000 sats
- Fee revenue: 2,000 × 100 sats = 200,000 sats/month (~$200)
- Premium subs: 50 users × $4.99 = $250/month
- Total: ~$450/month

10,000 users, 20% engagement:
- 2,000 active challengers  
- 20,000 challenges/month
- Fee revenue: 2,000,000 sats/month (~$2,000)
- Premium subs: 500 users × $4.99 = $2,495/month
- Total: ~$4,495/month
```

## Simplified MVP Implementation Timeline (1 Week Total!)

### Day 1-2: Core Infrastructure
- [ ] Create p2p_challenges table
- [ ] Create notification_inbox table
- [ ] Build NotificationInboxService (store & retrieve notifications)
- [ ] Build P2PChallengeService (create, accept, settle challenges)

### Day 3-4: UI Components
- [ ] Add Notification Inbox tab to main navigation
- [ ] Build NotificationInboxViewController
- [ ] Create notification cell types (challenge, payment, result)
- [ ] Add challenge button to team member cards
- [ ] Build SimpleChallengeModal (3 inputs only)

### Day 5: Payment & Settlement
- [ ] Payment instructions screen (simple Lightning address + memo)
- [ ] Manual payment confirmation ("I've Paid" button)
- [ ] Daily settlement job (compare HealthKit, pay winner)
- [ ] Hook into existing HealthKit sync

### Day 6-7: Testing & Polish
- [ ] End-to-end challenge flow test
- [ ] Badge count updates
- [ ] Push notification testing
- [ ] Payment flow with testnet
- [ ] Bug fixes and polish

### Files to Create (MVP)
```
New Files (6 only):
├── Services/
│   ├── P2PChallengeService.swift (150 lines)
│   └── NotificationInboxService.swift (100 lines)
├── Features/Notifications/
│   ├── NotificationInboxViewController.swift (200 lines)
│   └── NotificationCells.swift (150 lines)
└── Features/Challenges/
    └── SimpleChallengeModal.swift (100 lines)

Modified Files (4 only):
├── TeamMembersListView.swift (add challenge button)
├── MainTabBarController.swift (add notifications tab)
├── HealthKitSyncService.swift (check challenge progress)
└── supabase_schema.sql (add 2 tables)
```

### Why This Timeline Works
- **Just 6 new files** = Low complexity
- **Reuses everything** = CoinOS wallet, HealthKit sync, push system
- **Manual payment for MVP** = No webhook complexity
- **Simple UI** = Mostly table views and basic forms
- **1 week total** = Ship fast, iterate later

## Technical Considerations

### Lightning Network Integration
- Use existing CoinOS integration
- Generate unique invoice IDs per challenge/user
- Monitor payment confirmations via webhook
- Handle failed payments gracefully

### Background Processing
- Reuse existing background sync
- Check challenge progress hourly
- Settle completed challenges daily
- Send progress notifications intelligently

### Data Privacy
- Only show challenge details to participants
- Anonymous leaderboards optional
- GDPR compliant data handling
- User-controlled visibility settings

## Success Metrics

### Launch Metrics (Month 1)
- 100 challenges created
- 50% acceptance rate
- 80% completion rate
- Zero payment disputes
- <1% technical issues

### Growth Metrics (Month 6)
- 1,000+ monthly challenges
- 25% with stakes
- 15% premium conversion
- 4.5+ app store rating
- <2% dispute rate

## Risk Mitigation

### Technical Risks
- Lightning payment failures → Fallback to manual refund
- HealthKit sync issues → Extended completion window
- Cheating attempts → Multi-factor verification

### Legal Risks
- Gambling regulations → Position as skill-based
- Money transmission → Partner with licensed provider
- Terms of Service → Clear dispute process

### Business Risks
- Low adoption → Start with free challenges
- High dispute rate → Improve verification
- Negative reviews → Quick support response

## Next Steps

1. Review and approve this specification
2. Create database migrations
3. Build P2PChallengeService
4. Design UI mockups
5. Implement MVP features
6. Internal testing
7. Beta launch to subset of users
8. Iterate based on feedback
9. Full launch

## Conclusion

P2P challenges are a natural evolution for RUNSTR REWARDS that:
- Leverages existing infrastructure
- Creates viral growth loops
- Generates transaction revenue
- Maintains the invisible app philosophy
- Differentiates from competitors

The escrow model with RUNSTR as arbitrator provides trust while keeping implementation simple. By starting with basic challenge types and expanding based on user feedback, we can validate the concept quickly and scale confidently.