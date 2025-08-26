#!/usr/bin/env python3
"""
Lessons Learned Agent - Main Orchestrator
Integrates chat monitoring, commit analysis, and CLAUDE.md updating into a complete learning system.
"""

import os
import sys
import json
from datetime import datetime
from typing import Dict, List, Optional
import subprocess

# Import our components
import importlib.util
import sys

def import_module_from_path(module_name: str, file_path: str):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

# Import components
current_dir = os.path.dirname(os.path.abspath(__file__))
chat_detector_module = import_module_from_path("chat_pattern_detector", os.path.join(current_dir, "chat-pattern-detector.py"))
commit_analyzer_module = import_module_from_path("commit_analyzer", os.path.join(current_dir, "commit-analyzer.py"))
lesson_formatter_module = import_module_from_path("lesson_formatter", os.path.join(current_dir, "lesson-formatter.py"))
claude_md_updater_module = import_module_from_path("claude_md_updater", os.path.join(current_dir, "claude-md-updater.py"))

ChatPatternDetector = chat_detector_module.ChatPatternDetector
CommitAnalyzer = commit_analyzer_module.CommitAnalyzer
LessonFormatter = lesson_formatter_module.LessonFormatter
ClaudeMdUpdater = claude_md_updater_module.ClaudeMdUpdater

class LessonsLearnedAgent:
    """Main agent that orchestrates lesson extraction and documentation."""
    
    def __init__(self, project_path: str):
        self.project_path = project_path
        self.claude_md_path = os.path.join(project_path, "CLAUDE.md")
        
        # Initialize components
        self.chat_detector = ChatPatternDetector()
        self.commit_analyzer = CommitAnalyzer()
        self.formatter = LessonFormatter()
        self.updater = ClaudeMdUpdater(self.claude_md_path)
        
        # Session tracking
        self.session_lessons = []
        self.session_start_time = datetime.now()
    
    def analyze_chat_session(self, conversation_text: str) -> Dict[str, any]:
        """Analyze a chat session for lessons learned."""
        print("🔍 Analyzing chat session for lesson patterns...")
        
        lessons = self.chat_detector.extract_lessons_from_conversation(conversation_text)
        
        if lessons:
            print(f"📚 Found {len(lessons)} potential lessons in conversation")
            
            # Group lessons by category
            grouped_lessons = self._group_lessons_by_category(lessons)
            
            results = {}
            for category, cat_lessons in grouped_lessons.items():
                # Generate feature name based on context
                feature_name = self._infer_feature_name(cat_lessons)
                
                # Format for CLAUDE.md
                formatted_section = self.formatter.format_lesson_section(
                    cat_lessons, category, feature_name
                )
                
                results[category] = {
                    "feature_name": feature_name,
                    "lessons": cat_lessons,
                    "formatted_section": formatted_section,
                    "lesson_count": len(cat_lessons)
                }
            
            return results
        
        print("ℹ️ No clear lesson patterns found in conversation")
        return {}
    
    def analyze_recent_commits(self, limit: int = 10) -> Dict[str, any]:
        """Analyze recent commits for lessons."""
        print(f"🔍 Analyzing last {limit} commits for lesson patterns...")
        
        os.chdir(self.project_path)
        commit_lessons = self.commit_analyzer.analyze_recent_commits(limit)
        
        if commit_lessons:
            print(f"📚 Found {len(commit_lessons)} lessons from commits")
            
            # Group by category
            grouped = {}
            for lesson in commit_lessons:
                if lesson.category not in grouped:
                    grouped[lesson.category] = []
                grouped[lesson.category].append(lesson)
            
            results = {}
            for category, lessons in grouped.items():
                feature_name = self._infer_feature_name_from_commits(lessons)
                
                formatted_section = self.formatter.format_lesson_section(
                    lessons, category, feature_name
                )
                
                results[category] = {
                    "feature_name": feature_name,
                    "lessons": lessons,
                    "formatted_section": formatted_section,
                    "commit_count": len(lessons)
                }
            
            return results
        
        print("ℹ️ No fix commits found in recent history")
        return {}
    
    def update_claude_md_with_lessons(self, lesson_results: Dict[str, any], source: str = "chat") -> bool:
        """Update CLAUDE.md with extracted lessons."""
        print(f"📝 Updating CLAUDE.md with lessons from {source}...")
        
        success_count = 0
        total_count = len(lesson_results)
        
        for category, result in lesson_results.items():
            success = self.updater.add_lesson_to_section(
                result['formatted_section'],
                category,
                result['feature_name']
            )
            
            if success:
                success_count += 1
        
        print(f"✅ Successfully updated {success_count}/{total_count} lesson sections")
        return success_count == total_count
    
    def run_full_analysis(self, conversation_text: Optional[str] = None, commit_limit: int = 10) -> Dict[str, any]:
        """Run complete analysis pipeline."""
        print("🚀 Starting full lessons learned analysis...")
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "chat_lessons": {},
            "commit_lessons": {},
            "summary": {}
        }
        
        # Analyze chat if provided
        if conversation_text:
            chat_results = self.analyze_chat_session(conversation_text)
            results["chat_lessons"] = chat_results
            
            if chat_results:
                self.update_claude_md_with_lessons(chat_results, "chat")
        
        # Analyze recent commits
        commit_results = self.analyze_recent_commits(commit_limit)
        results["commit_lessons"] = commit_results
        
        if commit_results:
            self.update_claude_md_with_lessons(commit_results, "commits")
        
        # Generate summary
        total_lessons = len(results["chat_lessons"]) + len(results["commit_lessons"])
        results["summary"] = {
            "total_lessons_extracted": total_lessons,
            "chat_lesson_categories": list(results["chat_lessons"].keys()),
            "commit_lesson_categories": list(results["commit_lessons"].keys()),
            "claude_md_updated": total_lessons > 0
        }
        
        print(f"🎉 Analysis complete! Extracted {total_lessons} lessons")
        return results
    
    def monitor_git_commits(self, watch_mode: bool = True) -> None:
        """Monitor git commits in real-time for lesson extraction."""
        if not watch_mode:
            return
        
        print("👀 Monitoring git commits for lesson opportunities...")
        print("   Run 'git commit' with detailed messages for best results")
        print("   Use format: [TYPE]: Brief description with context and solution details")
        print("   Press Ctrl+C to stop monitoring")
        
        last_commit = self._get_last_commit_hash()
        
        try:
            while True:
                import time
                time.sleep(5)  # Check every 5 seconds
                
                current_commit = self._get_last_commit_hash()
                if current_commit != last_commit:
                    print(f"🆕 New commit detected: {current_commit[:8]}")
                    
                    # Analyze the new commit
                    lesson = self.commit_analyzer.analyze_commit_by_hash(current_commit)
                    if lesson:
                        print(f"📚 Extracted lesson from commit: {lesson.context}")
                        
                        # Add to CLAUDE.md
                        formatted = self.formatter.format_lesson_section([lesson], lesson.category, lesson.context)
                        self.updater.add_lesson_to_section(formatted, lesson.category, lesson.context)
                    
                    last_commit = current_commit
                    
        except KeyboardInterrupt:
            print("\n👋 Stopped monitoring commits")
    
    def _group_lessons_by_category(self, lessons: List) -> Dict[str, List]:
        """Group lessons by their category."""
        grouped = {}
        for lesson in lessons:
            category = getattr(lesson, 'category', 'General')
            if category not in grouped:
                grouped[category] = []
            grouped[category].append(lesson)
        return grouped
    
    def _infer_feature_name(self, lessons: List) -> str:
        """Infer feature name from lesson contexts."""
        contexts = [getattr(lesson, 'context', '') for lesson in lessons]
        
        # Look for common feature keywords
        feature_keywords = {
            "team": "Team Management",
            "earnings": "Earnings Page", 
            "competition": "Competitions Page",
            "workout": "Workouts Integration",
            "wallet": "Bitcoin Wallet",
            "navigation": "Navigation System",
            "wizard": "Creation Wizard",
            "leaderboard": "Leaderboard System"
        }
        
        for keyword, feature in feature_keywords.items():
            if any(keyword in context.lower() for context in contexts):
                return feature
        
        return "Feature Implementation"
    
    def _infer_feature_name_from_commits(self, commit_lessons: List) -> str:
        """Infer feature name from commit messages."""
        messages = [lesson.commit_message for lesson in commit_lessons]
        combined_text = " ".join(messages).lower()
        
        feature_keywords = {
            "team": "Team System",
            "build": "Build Configuration",
            "ui": "UI Implementation", 
            "navigation": "Navigation System",
            "wallet": "Bitcoin Wallet",
            "api": "API Integration",
            "constraint": "Layout System"
        }
        
        for keyword, feature in feature_keywords.items():
            if keyword in combined_text:
                return feature
        
        return "Development Fixes"
    
    def _get_last_commit_hash(self) -> str:
        """Get the hash of the last commit."""
        try:
            result = subprocess.run([
                'git', 'rev-parse', 'HEAD'
            ], capture_output=True, text=True, cwd=self.project_path)
            
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        
        return ""
    
    def create_lesson_from_manual_input(self, context: str, problem: str, solution: str, category: str = "General") -> bool:
        """Create a lesson from manual input."""
        print(f"📝 Creating manual lesson: {context}")
        
        # Create lesson object using imported module
        LessonPattern = chat_detector_module.LessonPattern
        lesson = LessonPattern(
            context=context,
            problem=problem,
            solution=solution,
            category=category
        )
        
        # Format and add to CLAUDE.md
        formatted = self.formatter.format_lesson_section([lesson], category, context)
        return self.updater.add_lesson_to_section(formatted, category, context)

def main():
    """Main entry point for the agent."""
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python lessons-learned-agent.py analyze-chat <conversation_file>")
        print("  python lessons-learned-agent.py analyze-commits [limit]")
        print("  python lessons-learned-agent.py monitor-commits")
        print("  python lessons-learned-agent.py manual <context> <problem> <solution> [category]")
        return
    
    project_path = "/Users/dakotabrown/LevelFitness-IOS"
    agent = LessonsLearnedAgent(project_path)
    
    command = sys.argv[1]
    
    if command == "analyze-chat":
        if len(sys.argv) < 3:
            print("❌ Please provide conversation file path")
            return
            
        with open(sys.argv[2], 'r') as f:
            conversation = f.read()
        
        results = agent.analyze_chat_session(conversation)
        print(json.dumps(results, indent=2, default=str))
    
    elif command == "analyze-commits":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        results = agent.analyze_recent_commits(limit)
        print(json.dumps(results, indent=2, default=str))
    
    elif command == "monitor-commits":
        agent.monitor_git_commits(watch_mode=True)
    
    elif command == "manual":
        if len(sys.argv) < 5:
            print("❌ Usage: manual <context> <problem> <solution> [category]")
            return
            
        context = sys.argv[2]
        problem = sys.argv[3] 
        solution = sys.argv[4]
        category = sys.argv[5] if len(sys.argv) > 5 else "General"
        
        success = agent.create_lesson_from_manual_input(context, problem, solution, category)
        print("✅ Lesson added to CLAUDE.md" if success else "❌ Failed to add lesson")
    
    elif command == "full-analysis":
        conversation_file = sys.argv[2] if len(sys.argv) > 2 else None
        conversation_text = None
        
        if conversation_file and os.path.exists(conversation_file):
            with open(conversation_file, 'r') as f:
                conversation_text = f.read()
        
        results = agent.run_full_analysis(conversation_text)
        print(json.dumps(results, indent=2, default=str))
    
    else:
        print(f"❌ Unknown command: {command}")

if __name__ == "__main__":
    main()