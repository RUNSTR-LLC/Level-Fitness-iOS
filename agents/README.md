# Lessons Learned Tracker Agent

A complete system for automatically extracting and documenting development lessons from chat conversations and git commits.

## Quick Start

### 1. Analyze Recent Commits
```bash
cd /Users/dakotabrown/LevelFitness-IOS/agents
python lessons-learned-agent.py analyze-commits 10
```

### 2. Monitor Commits in Real-time
```bash
python lessons-learned-agent.py monitor-commits
# Then make commits with detailed messages - lessons auto-extract
```

### 3. Analyze Chat Conversation
```bash
# Save conversation to file, then:
python lessons-learned-agent.py analyze-chat conversation.txt
```

### 4. Manual Lesson Entry
```bash
python lessons-learned-agent.py manual "Team creation wizard" "Container showed blank page" "Added height constraint" "UI/Layout"
```

## Recommended Commit Message Format

For best lesson extraction, use this format:

```
[CATEGORY]: Brief description

CONTEXT: What we were building
PROBLEM: Specific error or issue
SOLUTION: What fixed it
LESSON: Key takeaway
TIME: How long it took
```

Example:
```
[BUILD FIX]: Container height constraint missing

CONTEXT: Team creation wizard Step 1 UI implementation
PROBLEM: stepContainer showed blank page despite all components added
SOLUTION: Added heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
LESSON: Container views in ScrollView hierarchies need explicit height constraints
TIME: 45 minutes debugging
```

## Categories

- **UI/Layout**: AutoLayout, constraints, view hierarchy
- **Navigation**: UINavigationController, view presentation  
- **API Integration**: Supabase, CoinOS, network calls
- **Build/Compilation**: Xcode project, Swift syntax
- **Architecture**: Design patterns, file organization

## Files Created

1. **lessons-learned-tracker.md** - Agent definition and documentation
2. **chat-pattern-detector.py** - Extracts lessons from conversations
3. **commit-analyzer.py** - Analyzes git commits for patterns
4. **lesson-formatter.py** - Formats lessons for CLAUDE.md
5. **claude-md-updater.py** - Updates CLAUDE.md safely
6. **lessons-learned-agent.py** - Main orchestrator

## How It Works

1. **Pattern Detection**: Monitors for error/solution patterns in chat and commits
2. **Lesson Extraction**: Identifies context, problem, solution, and category
3. **Formatting**: Converts to CLAUDE.md structure with numbered points
4. **Integration**: Safely adds to existing CLAUDE.md maintaining structure

## Agent Usage in Claude Code

When working with this agent in Claude Code:

```python
# For real-time commit monitoring
agent = LessonsLearnedAgent("/Users/dakotabrown/LevelFitness-IOS")
agent.monitor_git_commits(watch_mode=True)

# For post-session analysis  
results = agent.run_full_analysis(conversation_text="...")
```

## Benefits

- **Automatic Documentation**: No manual lesson writing needed
- **Pattern Recognition**: Learns from both chat and commit patterns
- **Structured Output**: Follows your established CLAUDE.md format
- **Real-time Monitoring**: Captures lessons as they happen
- **Safe Updates**: Backs up CLAUDE.md before modifications

## Future Enhancements

- Integration with IDE to capture real-time debugging sessions
- Slack/Discord integration for team lesson sharing
- Weekly summary reports of lessons learned
- Cross-reference with existing lessons to prevent duplicates