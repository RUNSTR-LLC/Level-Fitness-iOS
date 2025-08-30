# RunstrRewards Agent Documentation

## Available Agents

### learner
**Purpose**: Extract and organize lessons learned from development sessions

**When to use**: After fixing bugs, completing features, or discovering important patterns

**Instructions**: See `learner-instructions.md` for detailed formatting and integration guidelines

**Output file**: `LEARNING.md` - Structured knowledge base with session insights

## Knowledge File Hierarchy

```
LEARNING.md          ← Session-by-session insights (maintained by learner agent)
├── LESSONS_LEARNED.md   ← Detailed technical solutions
├── MEMORY.md           ← High-level project context
├── DEVELOPMENT_LOG.md  ← Daily session progress
└── CLAUDE.md          ← Project requirements and standards
```

## Usage Examples

```bash
# After fixing a complex bug
/agents learner "Just fixed a critical Lightning Network bug in wallet synchronization"

# After completing a major feature
/agents learner "Completed team invitation system with QR codes and push notifications"

# After discovering an important pattern
/agents learner "Found reliable pattern for HealthKit background sync with proper error handling"
```

The learner agent will read the conversation context, existing knowledge files, and update LEARNING.md with properly categorized insights.