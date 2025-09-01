# Exit Fee System + One Team Constraint

## 🎯 Feature Overview
Implement the foundation of the team marketplace: enforce single team membership and charge 2,000 sats exit fee for leaving teams. This creates switching friction that generates revenue while making team decisions strategic.

## 🚨 Critical Business Logic
This is the **foundation feature** for the team marketplace economy. All other marketplace features depend on this constraint.

## 📋 Requirements

### One Team Membership Constraint
- [ ] Enforce single active team membership per user across entire app
- [ ] Block team joining attempts if user already has active membership
- [ ] Require "Leave Current Team" before joining new teams
- [ ] Update UI flows to reflect one-team limitation

### Exit Fee Payment System
- [ ] Charge 2,000 sats for leaving any team
- [ ] Direct Lightning payment to hardcoded RunstrRewards address
- [ ] CoinOS wallet integration for seamless payment
- [ ] Payment verification before allowing team exit

### User Experience Flow
- [ ] Clear messaging about one-team policy during onboarding
- [ ] Exit fee explanation dialog before payment
- [ ] Team switching flow with cost transparency
- [ ] Success/failure handling for exit fee payments

## 🔧 Technical Implementation

### Database Schema Changes
```sql
-- Add unique constraint to prevent multiple team memberships
ALTER TABLE team_members 
ADD CONSTRAINT unique_active_membership 
UNIQUE (user_id) 
WHERE left_at IS NULL;

-- Track exit fee payments
CREATE TABLE exit_fee_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    team_id UUID NOT NULL REFERENCES teams(id),
    amount INTEGER NOT NULL DEFAULT 2000, -- sats
    lightning_address TEXT NOT NULL,
    lightning_tx_id TEXT,
    payment_status TEXT DEFAULT 'pending', -- pending, completed, failed
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Configuration Constants
```swift
// Add to app configuration
private let RUNSTR_REWARDS_LIGHTNING_ADDRESS = "rewards@runstrrewards.com" // Replace with actual address
private let EXIT_FEE_AMOUNT = 2000 // sats
```

### Files to Modify
- `RunstrRewards/Features/Teams/TeamDetailViewController.swift` - Add exit fee flow in leave team function
- `RunstrRewards/Services/TeamDataService.swift` - Add membership validation functions
- `RunstrRewards/Services/TransactionDataService.swift` - Add exit fee payment processing
- `RunstrRewards/Features/Teams/TeamsViewController.swift` - Add team joining validation
- Database migration files for schema updates

### Lightning Payment Integration
```swift
func processExitFeePayment(userId: String, teamId: String) async throws {
    // 1. Show exit fee explanation dialog
    // 2. Initiate CoinOS payment to RunstrRewards lightning address
    // 3. Verify payment completion
    // 4. Record payment in exit_fee_payments table
    // 5. Allow team exit
    // 6. Handle payment failures with retry options
}
```

## 🎨 UI/UX Requirements

### Exit Fee Flow
1. User taps "Leave Team" in team settings
2. Show dialog: "Leaving costs 2,000 sats exit fee. This fee goes to RunstrRewards to support the platform."
3. Show payment confirmation with team they're leaving
4. Process CoinOS lightning payment 
5. Show success message and remove from team

### Team Joining Flow
1. User tries to join team while already on another team
2. Show dialog: "You can only be on one team at a time. Leave your current team first (2,000 sats exit fee)."
3. Option to "Leave Current Team & Join [New Team]" 
4. Process exit fee payment, then auto-join new team

### Error Handling
- [ ] Insufficient wallet balance for exit fee
- [ ] Lightning payment failures
- [ ] Network connectivity issues during payment
- [ ] Team joining failures after successful exit fee payment

## ✅ Success Criteria
- [ ] Zero users with multiple active team memberships
- [ ] Exit fee payments successfully processed and recorded
- [ ] Revenue tracking for exit fees
- [ ] Reduced casual team switching behavior
- [ ] Users make more strategic team selection decisions

## 🔒 Security Considerations
- [ ] Validate payment completion before allowing team exit
- [ ] Prevent double-charging exit fees
- [ ] Handle payment timeouts and failures gracefully
- [ ] Secure storage of lightning transaction IDs
- [ ] Prevent membership constraint bypassing

## 📊 Analytics & Tracking
- [ ] Track exit fee revenue (daily/weekly/monthly)
- [ ] Monitor team switching frequency changes
- [ ] Track payment success/failure rates
- [ ] User retention impact analysis

## 🧪 Testing Requirements
- [ ] Test single team constraint enforcement across all team joining flows
- [ ] Test exit fee payment success and failure scenarios
- [ ] Test CoinOS wallet integration thoroughly
- [ ] Verify database constraints prevent multiple memberships
- [ ] Load test payment processing system

## 🔗 Dependencies
- CoinOS wallet integration working properly
- Lightning Network payment capabilities
- Database migration deployment
- Team membership validation throughout app

**Priority**: Critical (Foundation Feature)
**Complexity**: High
**Sprint Points**: 13
**Business Impact**: Direct revenue generation