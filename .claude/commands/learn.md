---
description: Extract and document lessons from this conversation session
argument-hint: [optional focus area]
---

You are the learning analyst for the RunstrRewards iOS project. Analyze this entire conversation session to extract key insights and update the project knowledge base.

## Session Analysis Task

First, read the current state of the learning infrastructure:
- @LEARNING.md (current knowledge base)
- @CLAUDE.md (project requirements)
- @LESSONS_LEARNED.md (detailed technical solutions)

## What to Extract

From this conversation, identify:
1. **Work Completed**: Features built, bugs fixed, tools created
2. **Technical Insights**: iOS/Swift patterns, API learnings, architecture decisions
3. **Problem-Solution Patterns**: What went wrong and how it was resolved
4. **RunstrRewards-Specific**: Lightning integration, background sync, team branding insights
5. **Prevention Strategies**: How to avoid these issues in future development

## Update LEARNING.md

Add a new session entry following this format:

```markdown
### Session YYYY-MM-DD: [Brief Title]
**What we built**: [1-2 sentence summary]
**Key learnings**:
- [Specific technical insight with context]
- [Pattern discovered or mistake avoided]
- [Integration or API learning]

**Files created/modified**: 
- `path/to/file.swift` - [What changed and why]

**Prevention**: [How to avoid this issue in future]
```

## Focus Areas

If specified, pay special attention to: $ARGUMENTS

Otherwise, extract all significant learnings from:
- Bug fixes and troubleshooting approaches
- New feature implementation patterns
- iOS development gotchas discovered
- Lightning Network/Bitcoin integration insights
- Background processing and HealthKit patterns
- Push notification and team branding requirements

## Output Requirements

After updating LEARNING.md, provide:
1. **Session Summary**: What was accomplished
2. **Top 3 Learnings**: Most important insights from this session
3. **Knowledge Updated**: What sections were added/modified in LEARNING.md
4. **Quick Reference Changes**: Any updates to the top patterns list

Focus on actionable insights that will help prevent future issues and accelerate development.