# Enhanced Team Discovery Cards with Strategic Stats

## 🎯 Feature Overview
Transform team discovery cards to display comprehensive performance metrics and strategic data, enabling users to make informed decisions about which teams offer the best earning potential.

## 📋 Requirements

### Team Performance Metrics Display
- [ ] Average member workout streak (consecutive days)
- [ ] Average workout pace (min/km) 
- [ ] Average workout duration (minutes)
- [ ] Team activity level (total workouts/week)

### Competition & Earning Data
- [ ] Total prize pool available (Bitcoin balance)
- [ ] Number of active challenges/events
- [ ] Recent events completed (last 30 days)
- [ ] Event frequency (average events per month)

### Member Experience Indicators  
- [ ] Current member count vs. capacity
- [ ] Member retention rate (%)
- [ ] Average member tenure (months)
- [ ] Active loyalty bonus programs

## 🔧 Technical Implementation

### Files to Modify
- `RunstrRewards/Features/Teams/TeamsViewController.swift` - Update team discovery UI
- `RunstrRewards/Services/TeamDataService.swift` - Add analytics query functions
- Team card UI components - Add stats display sections
- Database queries for team analytics aggregation

### New Database Queries Needed
```sql
-- Team performance analytics
SELECT 
  AVG(workout_streak) as avg_streak,
  AVG(workout_pace) as avg_pace,
  AVG(workout_duration) as avg_duration,
  COUNT(workouts)/7 as workouts_per_week
FROM team_performance_view 
WHERE team_id = ?

-- Team competition data
SELECT 
  SUM(prize_pool) as total_prize_pool,
  COUNT(active_challenges) as active_challenges,
  COUNT(recent_events) as recent_events
FROM team_competitions 
WHERE team_id = ?
```

### UI Design Requirements
- Display stats in visually appealing cards with icons
- Use progress bars/charts for comparative metrics
- Highlight competitive advantages (high activity, good retention)
- Color-code performance levels (green=high, yellow=medium, red=low)

## 🎨 Design Mockup Requirements
- Stats should be scannable at a glance
- Use RunstrRewards industrial design theme
- Include Bitcoin-themed icons for prize pools
- Show loyalty bonuses prominently if available

## ✅ Success Criteria
- [ ] Users spend more time evaluating teams in discovery
- [ ] Increased correlation between team stats and user joining decisions
- [ ] Teams with better stats see higher join rates
- [ ] Users report feeling more confident about team selection

## 🔗 Related Features
- Links to **Exit Fee System** - users need good data to justify paying exit fees
- Links to **Team Loyalty Programs** - loyalty programs displayed prominently
- Links to **Strategic Analytics** - discovery data feeds user optimization tools

## 📈 Business Impact
- Drives team competition for better performance metrics
- Increases user engagement with team discovery flow  
- Creates pressure for teams to maintain high activity levels
- Enables strategic team marketplace behavior

## 🧪 Testing Requirements
- [ ] Test with teams having various performance levels
- [ ] Verify stats calculations are accurate
- [ ] Test UI performance with large numbers of teams
- [ ] A/B test different stat presentations for conversion

**Priority**: High
**Complexity**: Medium  
**Sprint Points**: 8
**Dependencies**: Team analytics infrastructure