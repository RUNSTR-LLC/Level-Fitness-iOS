# Learner Agent Instructions

## Purpose
Extract, organize, and maintain institutional knowledge from development sessions for the RunstrRewards iOS app.

## When to Activate
The learner agent should be used proactively after:
- ✅ Fixing bugs or resolving complex errors
- ✅ Completing major features or significant refactoring
- ✅ Discovering important iOS/Swift patterns or gotchas
- ✅ Finding security issues or performance improvements
- ✅ Learning new APIs or integration patterns
- ✅ Resolving technical challenges that took significant time
- ✅ Implementing Lightning Network/Bitcoin features
- ✅ Working with HealthKit background sync
- ✅ Setting up push notifications or team branding

## Data Sources to Read
Before updating LEARNING.md, always read:
1. **LEARNING.md** - Check existing entries to avoid duplication
2. **LESSONS_LEARNED.md** - Reference detailed technical solutions
3. **MEMORY.md** - Understand project context and high-level decisions
4. **DEVELOPMENT_LOG.md** - Recent session notes and progress
5. **CLAUDE.md** - Project requirements and standards

## Entry Format Standards

### Session Entry Template
```markdown
### Session YYYY-MM-DD: [Brief Title]
**What we built**: [1-2 sentence summary]
**Key learnings**:
- [Specific insight with technical detail]
- [Pattern discovered or mistake avoided]
- [Integration or API learning]

**Files affected**: 
- `path/to/file.swift` - [What changed and why]

**Prevention**: [How to avoid this issue in future]
```

### Quick Reference Entry Template
```markdown
- **[Problem Type]** → [Solution] ([file reference if applicable])
```

### Categorized Lesson Template
```markdown
#### [Specific Issue Title]
- **Problem**: [What went wrong or what we needed to learn]
- **Root cause**: [Technical explanation]
- **Solution**: [How it was fixed]
- **Prevention**: [Checklist item or pattern to follow]
- **Files**: [Specific file:line references]
```

## Categorization Guidelines

### 🏗️ Architecture Patterns
- Modular design decisions
- Service layer organization
- Background processing architecture
- Data flow patterns

### 🐛 Bug Fixes & Troubleshooting  
- Runtime crashes and their solutions
- Build errors and dependency issues
- Logic bugs in competition/wallet code
- iOS-specific gotchas

### 💰 Lightning/Bitcoin Integration
- CoinOS API patterns
- Security best practices
- Transaction handling
- Error recovery strategies

### 📱 iOS Background Processing
- HealthKit background sync
- BGTaskScheduler setup
- Push notification implementation
- App lifecycle management

### 🎯 RunstrRewards-Specific
- Team branding requirements
- Invisible app design patterns
- Competition logic implementation
- Anti-cheat system learnings

## Quality Standards

### Must Include
- **Specific file references** with line numbers when possible
- **Actionable solutions** that can be immediately implemented
- **Prevention strategies** to avoid repeating issues
- **Context about why** the solution works for RunstrRewards

### Avoid
- ❌ Vague or generic advice
- ❌ Duplicating existing LESSONS_LEARNED.md content
- ❌ Overly verbose explanations
- ❌ Solutions without file/code references

## Integration Rules

1. **Cross-reference existing docs**: Link to LESSONS_LEARNED.md for deep technical details
2. **Update Quick Reference**: Keep top 10 most important patterns current
3. **Maintain chronology**: Recent Sessions should stay chronological
4. **Remove outdated entries**: Archive old patterns that are no longer relevant
5. **Link related entries**: Connect similar patterns across categories

## Agent Success Metrics
- Reduces repeated debugging of same issues
- Provides quick reference for common RunstrRewards patterns
- Captures iOS/Swift learnings that prevent future mistakes
- Documents Lightning Network integration gotchas
- Maintains searchable knowledge base for background sync issues