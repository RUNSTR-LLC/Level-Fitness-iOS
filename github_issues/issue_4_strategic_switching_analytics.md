# Strategic Team Switching Analytics

## 🎯 Feature Overview  
Provide users with sophisticated analytics to make strategic team switching decisions. Help users optimize their earning potential by analyzing their workout patterns against available teams, factoring in exit fees and loyalty bonuses.

## 📊 Business Logic
Users become strategic "free agents" who use data to optimize earnings. This increases user engagement and justifies exit fee payments through clear ROI analysis.

## 📋 Requirements

### User Analytics Dashboard
- [ ] Personal earning potential analysis across available teams
- [ ] ROI calculator including exit fees and loyalty bonuses
- [ ] Team compatibility scoring based on workout patterns
- [ ] Historical earnings tracking across team switches

### Team Recommendation Engine  
- [ ] Match user workout patterns to optimal team event types
- [ ] Identify teams where user would rank higher competitively
- [ ] Factor in team loyalty programs and competition levels
- [ ] Predict earning potential with confidence intervals

### Strategic Switching Tools
- [ ] "Should I Switch?" analysis with clear recommendations
- [ ] Break-even time calculation (how long to recover exit fee)
- [ ] Optimal switching timing based on team event calendars
- [ ] Team switching ROI tracking and performance analysis

## 🔧 Technical Implementation

### Analytics Data Models
```swift
struct TeamCompatibilityScore {
    let teamId: String
    let compatibilityScore: Double // 0.0 to 1.0
    let projectedEarnings: Int // sats per month
    let competitiveRanking: Int // estimated position on team
    let loyaltyBonusPotential: Int // additional sats from loyalty
    let confidenceLevel: Double // prediction confidence
}

struct SwitchingAnalysis {
    let currentTeamEarnings: Int
    let targetTeamProjection: Int
    let exitFeeCost: Int
    let breakEvenDays: Int
    let monthlyROI: Double
    let recommendation: SwitchingRecommendation
}

enum SwitchingRecommendation {
    case stronglyRecommend(reason: String)
    case consider(reason: String) 
    case stay(reason: String)
    case stronglyDiscourage(reason: String)
}
```

### Database Schema
```sql
-- User performance analytics
CREATE TABLE user_performance_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    analysis_date DATE NOT NULL,
    avg_workout_frequency DECIMAL, -- workouts per week
    avg_workout_duration INTEGER, -- minutes
    avg_workout_distance DECIMAL, -- km
    preferred_workout_types JSONB, -- [running, cycling, etc.]
    performance_percentile DECIMAL, -- vs all users 0.0-1.0
    created_at TIMESTAMP DEFAULT NOW()
);

-- Team switching history and ROI tracking
CREATE TABLE team_switching_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    from_team_id UUID REFERENCES teams(id),
    to_team_id UUID NOT NULL REFERENCES teams(id),
    exit_fee_paid INTEGER DEFAULT 2000,
    switch_date DATE NOT NULL,
    projected_earnings INTEGER, -- what analytics predicted
    actual_earnings INTEGER, -- what user actually earned
    roi_achieved DECIMAL, -- actual ROI vs predicted
    days_to_break_even INTEGER,
    satisfaction_rating INTEGER, -- 1-5 user rating of switch
    created_at TIMESTAMP DEFAULT NOW()
);

-- Team earning potential cache (updated daily)
CREATE TABLE team_earning_potential (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id),
    user_performance_tier TEXT NOT NULL, -- low, medium, high
    projected_monthly_earnings INTEGER, -- sats
    competition_level DECIMAL, -- 0.0-1.0 (difficulty to rank high)
    loyalty_bonus_potential INTEGER, -- additional sats
    event_frequency DECIMAL, -- events per month
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Files to Modify
- `RunstrRewards/Features/Profile/ProfileViewController.swift` - Add analytics tab
- New: `StrategicAnalyticsService.swift` - Core analytics engine  
- New: `TeamRecommendationEngine.swift` - Matching algorithms
- New: `SwitchingAnalyticsViewController.swift` - Analytics dashboard
- `RunstrRewards/Services/TeamDataService.swift` - Add analytics queries

### Analytics Calculation Engine
```swift
class StrategicAnalyticsService {
    func analyzeUserPerformance(userId: String) async throws -> UserPerformanceProfile
    func calculateTeamCompatibility(userId: String, teamId: String) async throws -> TeamCompatibilityScore
    func generateSwitchingRecommendation(userId: String, targetTeamId: String) async throws -> SwitchingAnalysis
    func trackSwitchingROI(userId: String, switchId: String) async throws
}

class TeamRecommendationEngine {
    func findOptimalTeams(for userId: String) async throws -> [TeamRecommendation]
    func predictEarningPotential(userId: String, teamId: String) async throws -> EarningProjection
    func calculateBreakEvenTime(exitFee: Int, projectedIncrease: Int) -> Int
}
```

## 🎨 UI/UX Requirements

### Analytics Dashboard Layout
- [ ] **Current Team Performance Section**
  - Earnings this month, ranking position, loyalty bonuses
  - Performance trend chart (improving/declining)
  - Team satisfaction score and key metrics

- [ ] **Team Opportunities Section**  
  - Top 3 recommended teams with earning projections
  - Quick comparison table (current vs recommended)
  - "Switch Potential" score for each recommendation

- [ ] **Strategic Insights Section**
  - "Your earning potential is 45% higher on Team Alpha"
  - "You rank 2nd on current team, could be 1st on Team Beta"
  - "Break-even time: 12 days after exit fee"

### Switching Decision Interface
```
┌─────────────────────────────────────────┐
│ Switch to "Lightning Runners"?          │
├─────────────────────────────────────────┤
│ Current: Team Thunder ⚡               │
│ • Monthly earnings: 15,000 sats         │
│ • Your ranking: #4 of 12               │  
│ • Loyalty bonus: 2,000 sats            │
├─────────────────────────────────────────┤
│ Projected: Lightning Runners 🏃        │
│ • Monthly earnings: 22,000 sats (+47%) │
│ • Estimated ranking: #2 of 15          │
│ • Loyalty bonus: 3,500 sats            │
├─────────────────────────────────────────┤
│ Switch Analysis:                        │
│ • Exit fee: 2,000 sats                 │
│ • Break-even: 8 days                   │
│ • Monthly ROI: +5,500 sats             │
│                                         │
│ 🟢 RECOMMENDED: Strong earning upside   │
│                                         │
│ [Cancel] [Pay Exit Fee & Switch]       │
└─────────────────────────────────────────┘
```

## ✅ Success Criteria
- [ ] Users make more strategic (vs emotional) team switching decisions
- [ ] Higher user satisfaction with team switches
- [ ] Increased willingness to pay exit fees when ROI is clear
- [ ] Users engage with analytics dashboard regularly
- [ ] Improved prediction accuracy over time with ML learning

## 📊 Advanced Analytics Features

### Machine Learning Improvements
- [ ] Learn from successful vs unsuccessful team switches
- [ ] Improve earning projection accuracy over time  
- [ ] Identify user behavior patterns for better recommendations
- [ ] Factor in seasonal fitness trends and team performance cycles

### Competitive Intelligence
- [ ] Anonymous benchmarking against similar users
- [ ] Market analysis of team switching trends
- [ ] Identify undervalued teams with high potential
- [ ] Track team performance changes over time

## 🔄 Data Pipeline Architecture
```swift
// Daily analytics update job
func updateUserAnalytics() async {
    // 1. Calculate user performance metrics from workout data
    // 2. Update team earning potential for different user tiers
    // 3. Generate fresh team recommendations for active users
    // 4. Send weekly "optimization opportunities" notifications
    // 5. Update ML models with recent switching outcomes
}
```

## 🧠 Smart Notifications
- [ ] Weekly optimization alerts: "You could earn 30% more on Team X"
- [ ] Timing alerts: "Team Y just lost their top performer - opportunity!"
- [ ] ROI alerts: "Your break-even time is now just 5 days"
- [ ] Market alerts: "3 teams are competing for members like you"

## 📈 Business Impact Metrics
- [ ] Increased exit fee revenue from strategic switching
- [ ] Higher user lifetime value through optimization
- [ ] Improved user retention through better team matching
- [ ] More accurate prediction models leading to user satisfaction

## 🔗 Integration Dependencies
- **Workout Data**: HealthKit sync for performance analysis
- **Team Data**: Real-time team performance metrics
- **Wallet Data**: Earning history for projection accuracy  
- **Exit Fee System**: ROI calculations including switching costs

## ⚠️ Ethical Considerations
- [ ] Don't over-encourage switching (balance revenue vs user benefit)
- [ ] Transparent about prediction accuracy and limitations
- [ ] Respect user privacy in competitive analysis
- [ ] Fair algorithms that don't disadvantage certain user types

## 🧪 Testing Requirements
- [ ] Test prediction accuracy with historical data
- [ ] A/B test different recommendation presentation styles
- [ ] Validate ROI calculations against actual user outcomes
- [ ] Load test analytics calculations for all users
- [ ] Test edge cases (new users, inactive users, outlier performers)

**Priority**: Medium-High (Optimization Tool)
**Complexity**: High (ML/Analytics)  
**Sprint Points**: 13
**Dependencies**: Rich analytics data, exit fee system, user performance tracking