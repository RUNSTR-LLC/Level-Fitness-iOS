# RunstrRewards Learning Log
*Session-by-session insights and patterns for continuous improvement*

## Quick Reference - Top Patterns & Solutions

### Critical iOS Patterns
1. **Navigation Setup**: Always embed in UINavigationController first
2. **Container Heights**: ScrollView containers need explicit height constraints
3. **AutoLayout Order**: Add subviews before creating constraints
4. **Background Sync**: Use BGTaskScheduler with proper identifiers
5. **Lightning Security**: Never expose private keys, validate all CoinOS responses

### Common Bug Fixes
- **Blank screens** → Missing height constraints on scroll containers
- **Navigation failures** → Check navigationController setup
- **Build errors** → Verify Xcode project references
- **Memory leaks** → Check delegate weak references
- **Background sync fails** → Verify HealthKit permissions and BGTask setup

---

## Recent Sessions

### Session 2025-08-28: Custom Code Review Commands
**What we built**: Created `/review` and `/quick-review` slash commands for Claude Code
**Key learnings**:
- Custom commands go in `.claude/commands/` directory
- Extended thinking mode enables deeper analysis (70,000 tokens)
- Project-specific commands can reference CLAUDE.md automatically
- Command files use markdown with frontmatter configuration

**Files created**: 
- `.claude/commands/review.md` - Comprehensive review with extended thinking
- `.claude/commands/quick-review.md` - Fast critical issues check

**Prevention**: Document custom tooling setup for future projects

---

## Categorized Lessons

### 🏗️ Architecture Patterns

#### Modular Design (From CLAUDE.md)
- **Standard**: Files under 500 lines of code
- **Benefit**: Easier debugging, testing, and maintenance
- **Implementation**: Break features into logical components early

#### Background-First Design
- **Pattern**: App works without user opening it
- **Implementation**: HealthKit background sync + push notifications as primary UI
- **Key files**: BackgroundTaskManager, HealthKitService, NotificationService

### 🐛 Bug Fixes & Troubleshooting

#### Navigation Issues
- **Problem**: Silent pushViewController failures
- **Root cause**: Missing UINavigationController setup
- **Solution**: Always embed main VC in navigation controller
- **Prevention**: Add navigation setup checklist to new feature template

#### Container Layout Problems
- **Problem**: Blank scrollable content areas
- **Root cause**: Missing height constraints on scroll containers
- **Solution**: Explicit height constraints or use containerView patterns
- **Prevention**: Layout checklist for all scrollable content

### 💰 Lightning/Bitcoin Integration

#### CoinOS Security Patterns
- **Critical**: Never expose wallet private keys in logs or UI
- **Validation**: Always verify transaction responses from CoinOS API
- **Error handling**: Graceful fallbacks for network failures
- **Testing**: Use testnet for all development and testing

#### Background Wallet Updates
- **Pattern**: Sync wallet balance during background HealthKit processing
- **Implementation**: Combine wallet checks with workout processing
- **Performance**: Cache balance locally, update on sync intervals

### 📱 iOS Background Processing

#### HealthKit Background Sync
- **Setup**: BGTaskScheduler with proper Info.plist configuration
- **Permissions**: Request HealthKit authorization early in app lifecycle
- **Processing**: Batch workout data processing for efficiency
- **Error handling**: Graceful handling of HealthKit unavailability

#### Push Notification Strategy
- **Team branding**: Use team colors and logos, not RunstrRewards branding
- **Content**: Focus on competition updates and Bitcoin rewards
- **Timing**: Coordinate with background sync completion
- **Personalization**: Team-specific messaging and rewards

---

## Pattern Library - Reusable Solutions

### Navigation Controller Setup
```swift
// Always embed in navigation controller
let navController = UINavigationController(rootViewController: mainViewController)
navController.isNavigationBarHidden = true // if needed
```

### Scroll Container Height Fix
```swift
// Explicit height for scroll containers
scrollView.heightAnchor.constraint(equalToConstant: view.frame.height)
```

### Safe Background Task Processing
```swift
// Proper BGTask with timeout handling
func scheduleBackgroundSync() {
    let request = BGProcessingTaskRequest(identifier: "com.runstr.background-sync")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    try? BGTaskScheduler.shared.submit(request)
}
```

---

## Integration Notes

### Related Documentation
- **LESSONS_LEARNED.md**: Detailed technical solutions and debugging patterns
- **MEMORY.md**: Project context and high-level architectural decisions  
- **DEVELOPMENT_LOG.md**: Daily session notes and implementation progress
- **CLAUDE.md**: Project requirements and development philosophy

### Knowledge Hierarchy
1. **LEARNING.md** (this file): Session insights and quick patterns
2. **LESSONS_LEARNED.md**: Deep technical solutions
3. **MEMORY.md**: Strategic architectural decisions
4. **CLAUDE.md**: Project requirements and standards

---

## Gotchas & Warnings

### 🚨 Critical Warnings
- **Never commit secrets**: Bitcoin private keys, API keys, test data
- **No mock data in production**: All data from HealthKit, Supabase, or empty states
- **Team branding only**: Push notifications must use team assets, not app branding
- **Background sync reliability**: Critical for invisible app experience

### ⚠️ Common Mistakes
- Forgetting navigation controller setup for new screens
- Missing height constraints on scroll content
- Not testing background sync in real iOS background conditions
- Exposing Lightning Network details to end users (should be invisible)

---

*This file is maintained by the learner agent to capture insights from each development session.*