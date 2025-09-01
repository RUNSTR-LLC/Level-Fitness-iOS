# Team Loyalty Rewards & Retention Tools

## 🎯 Feature Overview
Enable captains to create loyalty bonus programs that automatically reward members for staying on teams. This creates competitive differentiation between teams and reduces exit fee revenue by improving retention.

## 💰 Business Logic
Teams compete for members by offering loyalty bonuses. Better loyalty programs = better member retention = competitive advantage in the marketplace.

## 📋 Requirements

### Captain Loyalty Program Tools
- [ ] Create loyalty bonus programs with flexible rules
- [ ] Set daily/weekly/monthly bonus amounts (in sats)
- [ ] Configure tenure-based multipliers (longer members get more)
- [ ] Performance-based bonuses (top performers get extra)
- [ ] Automatic distribution from team wallet

### Loyalty Program Types
- [ ] **Time-based**: Daily login bonuses, weekly participation rewards
- [ ] **Tenure-based**: 1 month, 3 month, 6 month milestone bonuses
- [ ] **Performance-based**: Top 3 members get bonus multipliers
- [ ] **Participation-based**: Workout frequency bonuses
- [ ] **Streak-based**: Consecutive day workout bonuses

### Member Loyalty Experience
- [ ] Loyalty bonus notifications when earned
- [ ] Loyalty earning history in profile
- [ ] Display loyalty program details when viewing teams
- [ ] Show loyalty multipliers and potential earnings

## 🔧 Technical Implementation

### Database Schema
```sql
-- Team loyalty programs
CREATE TABLE team_loyalty_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id),
    program_name TEXT NOT NULL,
    program_type TEXT NOT NULL, -- daily, weekly, monthly, tenure, performance
    bonus_amount INTEGER NOT NULL, -- base bonus in sats
    multiplier_rules JSONB, -- flexible rules for multipliers
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Individual loyalty transactions
CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    team_id UUID NOT NULL REFERENCES teams(id),
    program_id UUID NOT NULL REFERENCES team_loyalty_programs(id),
    amount INTEGER NOT NULL, -- sats earned
    transaction_type TEXT NOT NULL, -- daily, weekly, tenure, performance
    earned_date DATE NOT NULL,
    distributed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Member loyalty status tracking
CREATE TABLE member_loyalty_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    team_id UUID NOT NULL REFERENCES teams(id),
    tenure_days INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    loyalty_tier TEXT DEFAULT 'bronze', -- bronze, silver, gold, platinum
    total_earned INTEGER DEFAULT 0, -- lifetime loyalty sats earned
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Files to Modify
- `RunstrRewards/Features/Teams/TeamWalletViewController.swift` - Add loyalty program management
- `RunstrRewards/Services/TransactionDataService.swift` - Add loyalty distribution logic
- `RunstrRewards/Features/Teams/TeamDetailViewController.swift` - Display loyalty programs
- `RunstrRewards/Features/Profile/ProfileViewController.swift` - Show loyalty earnings
- New: `LoyaltyProgramService.swift` - Core loyalty logic

### Loyalty Calculation Engine
```swift
class LoyaltyProgramService {
    func calculateDailyBonuses(teamId: String) async throws
    func calculateWeeklyBonuses(teamId: String) async throws  
    func calculateTenureBonuses(userId: String, teamId: String) async throws
    func calculatePerformanceBonuses(teamId: String) async throws
    func distributeLoyaltyBonuses(teamId: String, bonuses: [LoyaltyBonus]) async throws
}
```

## 🎨 UI/UX Requirements

### Captain Loyalty Management Interface
- [ ] Loyalty program creation wizard in team wallet
- [ ] Program templates (High Activity Team, Beginner Friendly, Elite Performance)
- [ ] Budget allocation tools (% of team wallet for loyalty)
- [ ] Performance analytics (retention improvement, cost per member)

### Loyalty Program Display
- [ ] Show loyalty programs prominently in team discovery cards
- [ ] Loyalty earning potential calculator for users
- [ ] Visual loyalty tier progression (Bronze → Silver → Gold → Platinum)
- [ ] Historical loyalty earnings in member profiles

### Automated Distribution Flow
1. Daily/weekly job calculates loyalty bonuses
2. Verify team wallet has sufficient balance  
3. Distribute bonuses automatically
4. Send push notifications to members about earnings
5. Update member loyalty status and tiers

## ✅ Success Criteria
- [ ] Teams with loyalty programs show higher retention rates
- [ ] Reduced exit fee payments (members stay longer)
- [ ] Captains actively create and manage loyalty programs
- [ ] Members report loyalty bonuses influence team selection
- [ ] Team wallet usage increases significantly

## 🔄 Automated Distribution Logic
```swift
// Daily loyalty distribution (runs as background job)
func distributeDailyLoyalty() async {
    let activePrograms = try await fetchActiveLoyaltyPrograms()
    
    for program in activePrograms {
        let eligibleMembers = try await getEligibleMembers(program)
        let bonuses = try await calculateBonuses(program, eligibleMembers)
        
        // Verify team wallet balance
        guard try await verifyWalletBalance(program.teamId, totalAmount: bonuses.sum) else {
            // Send low balance alert to captain
            continue
        }
        
        // Distribute bonuses
        try await distributeBonuses(bonuses)
        
        // Send notifications to members
        try await sendLoyaltyNotifications(bonuses)
    }
}
```

## 📊 Analytics & Metrics
- [ ] Loyalty program ROI (retention improvement vs. cost)
- [ ] Most effective program types (daily vs. tenure vs. performance)
- [ ] Member loyalty tier distribution
- [ ] Loyalty bonus impact on team switching decisions
- [ ] Team wallet allocation to loyalty programs

## 🔗 Integration Points
- **Team Wallet**: Loyalty bonuses distributed from team Bitcoin wallet
- **Push Notifications**: Loyalty earning notifications with team branding
- **Team Discovery**: Display loyalty programs prominently on team cards
- **Profile**: Show loyalty earning history and current tier

## ⚠️ Edge Cases & Error Handling
- [ ] Team wallet insufficient balance for loyalty distribution
- [ ] Member leaves team before loyalty bonus distribution
- [ ] Captain deactivates loyalty program mid-cycle
- [ ] Loyalty program rule conflicts (multiple bonuses for same action)
- [ ] Bitcoin price volatility affecting bonus values

## 🧪 Testing Requirements
- [ ] Test loyalty calculation accuracy for all program types
- [ ] Test automated distribution system reliability
- [ ] Test wallet balance verification and error handling
- [ ] Test loyalty program impact on team switching behavior
- [ ] Load test loyalty distribution for teams with many members

**Priority**: High (Retention Tool)
**Complexity**: Medium-High
**Sprint Points**: 10  
**Dependencies**: Team wallet system, automated job scheduling