# Team Marketplace Vision

## Executive Summary

**RunstrRewards Team Marketplace** transforms the app from simple team subscriptions into a dynamic competitive economy where users strategically switch between teams to maximize Bitcoin earnings, while RunstrRewards profits from switching friction through exit fees.

### Core Business Model Shift
- **From**: Static team subscriptions ($1.99/month per member)
- **To**: Dynamic marketplace with exit fees (2,000 sats per team switch) + team loyalty programs
- **Result**: Users become strategic "free agents" optimizing earnings across teams

---

## Business Model & Revenue Streams

### Primary Revenue: Exit Fees
- **2,000 sats per team switch** paid directly to RunstrRewards lightning address
- Users pay from CoinOS wallet → RunstrRewards hardcoded lightning address
- No complex wallet infrastructure needed (simplified implementation)

### Secondary Revenue: Enhanced Team Competition
- Teams compete for top performers through loyalty bonuses
- Higher team engagement = more events = more Bitcoin flowing through ecosystem
- Teams invest more in member retention and rewards

### Economic Psychology
- Exit fee creates switching friction but justified by earning potential
- Users will pay 2k sats believing they'll earn it back on better teams
- Teams must prove value through loyalty programs to retain talent

---

## Core Features Implementation

## Feature 1: Enhanced Team Discovery Cards with Strategic Stats ⏳

**Status**: Not Started
**Implementation Target**: Version 1.1

### Requirements
- [ ] Add comprehensive team performance metrics to discovery cards
- [ ] Display team statistics that help users make strategic decisions
- [ ] Show earning potential indicators for different fitness levels

### Team Card Enhanced Data Display
- [ ] **Performance Metrics**
  - [ ] Average member workout streak (days)
  - [ ] Average workout pace (min/km)
  - [ ] Average workout duration (minutes)
  - [ ] Team activity level (workouts/week)

- [ ] **Competition Data**
  - [ ] Total prize pool available (Bitcoin)
  - [ ] Number of active challenges
  - [ ] Recent events completed
  - [ ] Event frequency (events/month)

- [ ] **Member Experience Indicators**
  - [ ] Current member count and capacity
  - [ ] Member retention rate (%)
  - [ ] Average member tenure
  - [ ] Loyalty bonus programs active

### Technical Implementation
- [ ] **Files to Modify**:
  - [ ] `RunstrRewards/Features/Teams/TeamsViewController.swift` - Update team cards
  - [ ] `RunstrRewards/Services/TeamDataService.swift` - Add analytics queries
  - [ ] Team card UI components - Add stats displays
  
- [ ] **New Database Queries**:
  - [ ] Team performance aggregation functions
  - [ ] Member retention calculations
  - [ ] Activity level metrics

### Success Metrics
- [ ] Users spend more time evaluating teams before joining
- [ ] Increased team switching based on performance data
- [ ] Higher engagement with team discovery flow

---

## Feature 2: Exit Fee System + One Team Constraint 🚨

**Status**: Not Started  
**Implementation Target**: Version 1.1 (Critical)

### Requirements
- [ ] Enforce single team membership across the app
- [ ] Implement 2,000 sats exit fee for leaving teams
- [ ] Direct lightning payment to RunstrRewards address

### One Team Constraint Implementation
- [ ] **Database Constraints**
  - [ ] Add unique constraint on user_id in team_members table
  - [ ] Prevent multiple active team memberships
  - [ ] Block team joining if user already has active membership

- [ ] **UI Flow Updates**
  - [ ] "Leave Current Team" requirement before joining new teams
  - [ ] Clear messaging about one-team limitation
  - [ ] Team switching flow with exit fee explanation

### Exit Fee Payment System
- [ ] **Lightning Payment Integration**
  - [ ] Hardcode RunstrRewards lightning address in app
  - [ ] CoinOS wallet payment flow for 2,000 sats
  - [ ] Payment verification before allowing team exit

- [ ] **Exit Fee Flow**
  - [ ] Payment confirmation dialog with fee explanation
  - [ ] CoinOS payment processing
  - [ ] Success confirmation and team removal
  - [ ] Failure handling and retry logic

### Technical Implementation
- [ ] **Files to Modify**:
  - [ ] `RunstrRewards/Features/Teams/TeamDetailViewController.swift` - Add exit fee logic
  - [ ] `RunstrRewards/Services/TeamDataService.swift` - Add membership validation
  - [ ] `RunstrRewards/Services/TransactionDataService.swift` - Add exit fee payments
  
- [ ] **Configuration**:
  - [ ] Add RunstrRewards lightning address constant
  - [ ] Add exit fee amount constant (2,000 sats)

### Success Metrics
- [ ] Exit fee revenue tracking
- [ ] Reduced casual team switching
- [ ] Increased strategic team selection

---

## Feature 3: Team Loyalty Rewards & Retention Tools 💰

**Status**: Not Started
**Implementation Target**: Version 1.2

### Requirements
- [ ] Captain tools to create loyalty bonus programs
- [ ] Automated loyalty distribution system
- [ ] Display loyalty programs in team discovery

### Captain Loyalty Tools
- [ ] **Loyalty Program Creation**
  - [ ] Set daily/weekly/monthly loyalty bonuses
  - [ ] Performance-based loyalty multipliers
  - [ ] Tenure milestone rewards (1 month, 3 months, etc.)

- [ ] **Member Retention Dashboard**
  - [ ] Track member loyalty program participation
  - [ ] Monitor retention rates and churn risk
  - [ ] Suggest optimal loyalty bonus amounts

### Automated Distribution System
- [ ] **Loyalty Calculation Engine**
  - [ ] Calculate loyalty bonuses based on rules
  - [ ] Distribute bonuses automatically from team wallet
  - [ ] Track loyalty payment history

- [ ] **Member Experience**
  - [ ] Loyalty bonus notifications
  - [ ] Loyalty earning history in profile
  - [ ] Loyalty multiplier indicators

### Technical Implementation
- [ ] **Files to Modify**:
  - [ ] `RunstrRewards/Features/Teams/TeamWalletViewController.swift` - Add loyalty tools
  - [ ] `RunstrRewards/Services/TransactionDataService.swift` - Add loyalty distribution
  - [ ] Team discovery cards - Add loyalty program displays

- [ ] **Database Schema**:
  - [ ] Team loyalty programs table
  - [ ] Loyalty transaction history
  - [ ] Member loyalty status tracking

### Success Metrics
- [ ] Increased team member retention rates
- [ ] Teams actively using loyalty programs
- [ ] Reduced exit fee payments (better retention)

---

## Feature 4: Strategic Team Switching Analytics 📊

**Status**: Not Started
**Implementation Target**: Version 1.2

### Requirements
- [ ] Earning potential analysis for users
- [ ] Team recommendation system based on workout patterns
- [ ] ROI calculator for team switching decisions

### User Analytics Dashboard
- [ ] **Earning Potential Calculator**
  - [ ] Compare current team earnings vs. other teams
  - [ ] Project potential earnings based on user's workout patterns
  - [ ] Account for exit fees in ROI calculations

- [ ] **Team Compatibility Analysis**
  - [ ] Match user workout patterns to team event types
  - [ ] Identify teams where user would rank higher
  - [ ] Factor in loyalty bonuses and competition level

### Strategic Switching Tools
- [ ] **"Should I Switch?" Feature**
  - [ ] Weekly analysis of team performance vs. alternatives
  - [ ] Break-even analysis including exit fees
  - [ ] Optimal switching timing recommendations

- [ ] **Team Performance Tracking**
  - [ ] Track earnings across different teams over time
  - [ ] Identify most profitable team types for user
  - [ ] Historical switching ROI analysis

### Technical Implementation
- [ ] **Files to Modify**:
  - [ ] `RunstrRewards/Features/Profile/ProfileViewController.swift` - Add analytics tab
  - [ ] New analytics service for team comparison
  - [ ] Team recommendation engine

- [ ] **Analytics Engine**:
  - [ ] User performance analysis algorithms
  - [ ] Team earning potential calculations
  - [ ] Switching ROI optimization

### Success Metrics
- [ ] Increased strategic team switching
- [ ] Higher user lifetime value through optimization
- [ ] More exit fee revenue from informed switching

---

## Implementation Architecture

### Lightning Payment Integration
```swift
// Hardcoded RunstrRewards lightning address
private let RUNSTR_REWARDS_LIGHTNING_ADDRESS = "your_lightning_address@getalby.com"

// Exit fee payment flow
func processExitFeePayment() {
    // Pay 2,000 sats from user's CoinOS wallet to RunstrRewards address
    // Verify payment completion
    // Allow team exit
}
```

### Database Schema Updates
```sql
-- Ensure one team per user constraint
ALTER TABLE team_members ADD CONSTRAINT unique_user_membership UNIQUE (user_id, left_at);

-- Team loyalty programs
CREATE TABLE team_loyalty_programs (
    id UUID PRIMARY KEY,
    team_id UUID REFERENCES teams(id),
    bonus_amount INTEGER, -- sats
    bonus_frequency TEXT, -- daily/weekly/monthly
    created_at TIMESTAMP DEFAULT NOW()
);

-- Exit fee tracking
CREATE TABLE exit_fee_payments (
    id UUID PRIMARY KEY,
    user_id UUID,
    team_id UUID,
    amount INTEGER DEFAULT 2000,
    lightning_tx_id TEXT,
    paid_at TIMESTAMP DEFAULT NOW()
);
```

---

## Business Impact Projections

### Revenue Modeling
- **100 active users** switching teams 2x/month = **400k sats/month** exit fee revenue
- **1,000 active users** = **4M sats/month** = ~$1,600 monthly recurring revenue
- Plus existing team subscription revenue + loyalty program circulation

### User Behavior Changes
- Strategic team evaluation becomes core user behavior
- Teams invest in member experience to reduce churn
- Higher-stakes decision making increases engagement
- Users become more active to justify exit fee investments

---

## Next Steps

1. **Start with Feature 2** (Exit Fee + One Team Constraint) - Foundation requirement
2. **Implement Feature 1** (Enhanced Discovery) - Drives marketplace behavior  
3. **Add Feature 3** (Loyalty Programs) - Team retention tools
4. **Complete with Feature 4** (Analytics) - User optimization tools

**Target Timeline**: 4-6 weeks for complete marketplace implementation

---

## Success Criteria

### For Users
- Clear understanding of switching economics
- Ability to make strategic team decisions
- Higher earning potential through optimization

### For Teams/Captains  
- Tools to compete for and retain top members
- Clear metrics on member retention ROI
- Loyalty program effectiveness tracking

### For RunstrRewards
- Sustainable exit fee revenue stream
- Increased user engagement through strategic decisions
- Higher lifetime value per user through marketplace dynamics

---

*This document will be updated as features are implemented and marketplace dynamics are refined based on real user behavior.*