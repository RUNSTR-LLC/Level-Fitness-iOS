---
description: Comprehensive code review with deep analysis using most powerful model
argument-hint: [files or feature to review]
---

<task_setup>
Extended thinking: 70000
</task_setup>

You are a senior iOS architect and code reviewer specializing in production-ready apps. Perform a comprehensive code review of the RunstrRewards fitness competition app.

## Review Context

First, read @CLAUDE.md to understand the project requirements, then analyze: $ARGUMENTS

## Review Checklist

### Core Architecture & Standards
- **File size**: Are files under 500 lines of code?
- **Separation of concerns**: Clear modular architecture?
- **Production ready**: No mock data, placeholders, or sample content?
- **Real data only**: HealthKit, Supabase, or proper empty states?

### iOS & Swift Best Practices
- **Memory management**: Proper retain cycles, weak references?
- **Background processing**: Correct HealthKit background sync patterns?
- **Performance**: Efficient data processing, UI updates on main thread?
- **Error handling**: Comprehensive error cases and user feedback?

### RunstrRewards-Specific Requirements
- **Invisible design**: Minimal app interaction, background-first approach?
- **Team branding**: Notifications use team branding, not RunstrRewards?
- **Bitcoin security**: Lightning Network integration secure and tested?
- **Anti-cheat**: HealthKit validation and duplicate detection working?

### Security & Production Readiness
- **Lightning vulnerabilities**: CoinOS integration secure?
- **HealthKit permissions**: Proper privacy and background access?
- **API security**: Supabase RLS policies and authentication?
- **Data validation**: Input sanitization and type safety?

### Business Logic Verification
- **Competition logic**: Accurate scoring and leaderboard calculations?
- **Payment flows**: Prize distribution and wallet management correct?
- **Subscription model**: Team/member revenue flows implemented properly?
- **Background sync**: Workout data processing reliable and accurate?

## Output Format

Provide:
1. **Critical Issues**: Security vulnerabilities, crashes, data corruption risks
2. **Architecture Concerns**: Violations of project standards or iOS patterns
3. **Performance Issues**: Memory leaks, inefficient processing, UI blocking
4. **Business Logic Problems**: Competition scoring, payments, team management
5. **Recommendations**: Specific fixes with file:line references
6. **Production Readiness**: App Store submission blockers

Be specific with file paths and line numbers. Focus on actionable feedback that prevents bugs and improves code quality.