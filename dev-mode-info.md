# Development Mode Testing Guide

## 🚀 Development Mode is ENABLED

The app is now configured for testing without subscription barriers. You can:

### ✅ What You Can Do Now:
1. **Create unlimited teams** - No captain subscription required
2. **Access all team management features** - Events, leaderboards, analytics
3. **Test as a subscribed user** - All team features unlocked
4. **Create and manage events** - No subscription checks
5. **View and manage leaderboards** - Full access

### 🔧 Development Mode Settings:
- Location: `SubscriptionService.swift` line 9
- Current Status: `DEVELOPMENT_MODE = true`
- All subscription checks return "captain" status automatically

### 📱 Testing Instructions:

1. **Run the app in simulator:**
   ```bash
   open RunstrRewards.xcodeproj
   # Then press Cmd+R to run
   ```

2. **Create a new team:**
   - Navigate to Teams page
   - Look for the **orange "+" button** in the top-right corner of the header
   - Tap the create team button
   - Fill in team details
   - No subscription prompt will appear (development mode bypasses this)

3. **Test team features:**
   - Create events
   - Manage leaderboards
   - View analytics
   - All features are unlocked

### ⚠️ Important Notes:

1. **For Production:** 
   - **MUST** set `DEVELOPMENT_MODE = false` in `SubscriptionService.swift`
   - This flag bypasses ALL subscription checks
   - Never ship to App Store with this enabled

2. **Database Cleanup:**
   - Old test teams may still exist in Supabase
   - You can delete them through the Teams page UI
   - Each team has a delete button if you're the captain

3. **What's Modified:**
   - ✅ SubscriptionService - Development mode flag and bypass logic
   - ✅ TeamCreationWizardViewController - Conditional subscription checks
   - ✅ TeamDataService - Allow multiple teams in dev mode

### 🧹 To Clean Up Test Teams:

Since Supabase MCP isn't connected, use the app UI:
1. Go to Teams page
2. Tap on a test team
3. If you're the captain, you'll see a delete option
4. Confirm deletion

Or manually via Supabase dashboard:
1. Log into your Supabase project
2. Navigate to Table Editor → teams
3. Delete test entries
4. Also check team_members table for orphaned records

### 🔄 To Toggle Development Mode:

Edit `/RunstrRewards/Services/SubscriptionService.swift`:
```swift
// Line 9 - Toggle this flag
static let DEVELOPMENT_MODE = true  // Set to false for production
```

### 📊 Testing Checklist:

- [ ] Create a team without subscription
- [ ] Add team members
- [ ] Create an event
- [ ] Set up a leaderboard
- [ ] Test team analytics
- [ ] Delete a test team
- [ ] Verify all features work

## 🎯 Ready to Test!

The app is now ready for full team testing without any subscription barriers. Build succeeded and all development mode changes are in place.

Remember to set `DEVELOPMENT_MODE = false` before any production builds or App Store submissions!