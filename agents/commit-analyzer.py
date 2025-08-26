#!/usr/bin/env python3
"""
Commit Analyzer for Lessons Learned Tracker
Analyzes git commits to extract learning opportunities and technical insights.
"""

import subprocess
import re
import json
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

@dataclass
class CommitLesson:
    commit_hash: str
    commit_message: str
    context: str
    problem: str
    solution: str
    category: str
    files_changed: List[str]
    lines_changed: int
    timestamp: str

class CommitAnalyzer:
    """Analyzes git commits for learning patterns."""
    
    def __init__(self):
        self.fix_patterns = [
            r"(?i)(fix|resolve|correct|repair):\s*(.+)",
            r"(?i)(build\s+fix|bug\s+fix|ui\s+fix):\s*(.+)",
            r"(?i)(address|handle|solve)\s+(.+?)\s+(issue|error|problem)",
            r"(?i)(update|change|modify)\s+(.+?)\s+to\s+(fix|resolve|correct)"
        ]
        
        self.context_patterns = [
            r"(?i)(implementing|building|creating|adding)\s+(.+?)(?:$|\s+-)",
            r"(?i)(for|in|on)\s+(.*?(?:page|view|component|feature|wizard))(?:$|\s+-)",
            r"(?i)(team|user|workout|competition|earnings)\s+(.*?)(?:$|\s+-)"
        ]
        
        self.technical_keywords = {
            "AutoLayout": ["constraint", "layout", "anchor", "priority", "hierarchy"],
            "Navigation": ["navigation", "push", "present", "segue", "controller"],
            "API": ["supabase", "coinos", "api", "request", "response", "network"],
            "Build": ["build", "compile", "xcode", "target", "scheme", "project"],
            "Swift": ["syntax", "property", "method", "class", "struct", "protocol"],
            "UI": ["view", "button", "label", "scroll", "collection", "table"]
        }
    
    def analyze_recent_commits(self, limit: int = 20) -> List[CommitLesson]:
        """Analyze recent commits for learning opportunities."""
        commits = self._get_recent_commits(limit)
        lessons = []
        
        for commit in commits:
            lesson = self._extract_lesson_from_commit(commit)
            if lesson:
                lessons.append(lesson)
        
        return lessons
    
    def analyze_commit_by_hash(self, commit_hash: str) -> Optional[CommitLesson]:
        """Analyze a specific commit for lessons."""
        commit_info = self._get_commit_info(commit_hash)
        if commit_info:
            return self._extract_lesson_from_commit(commit_info)
        return None
    
    def _get_recent_commits(self, limit: int) -> List[Dict]:
        """Get recent commit information."""
        try:
            # Get commit hashes and messages
            result = subprocess.run([
                'git', 'log', f'-{limit}', '--pretty=format:%H|%s|%ad|%an',
                '--date=iso'
            ], capture_output=True, text=True, cwd='.')
            
            commits = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 4:
                        commits.append({
                            'hash': parts[0],
                            'message': parts[1],
                            'date': parts[2],
                            'author': parts[3]
                        })
            
            return commits
            
        except subprocess.CalledProcessError:
            return []
    
    def _get_commit_info(self, commit_hash: str) -> Optional[Dict]:
        """Get detailed information for a specific commit."""
        try:
            # Get commit details
            result = subprocess.run([
                'git', 'show', '--stat', '--format=%H|%s|%ad|%an',
                commit_hash
            ], capture_output=True, text=True, cwd='.')
            
            if result.returncode != 0:
                return None
                
            lines = result.stdout.strip().split('\n')
            header = lines[0]
            
            if '|' in header:
                parts = header.split('|')
                if len(parts) >= 4:
                    # Extract file changes
                    files_changed = []
                    lines_changed = 0
                    
                    for line in lines[1:]:
                        if '.swift' in line and '|' in line:
                            file_match = re.search(r'(\S+\.swift)', line)
                            if file_match:
                                files_changed.append(file_match.group(1))
                            
                            # Extract line count changes
                            line_match = re.search(r'\|\s*(\d+)', line)
                            if line_match:
                                lines_changed += int(line_match.group(1))
                    
                    return {
                        'hash': parts[0],
                        'message': parts[1],
                        'date': parts[2],
                        'author': parts[3],
                        'files_changed': files_changed,
                        'lines_changed': lines_changed
                    }
            
        except subprocess.CalledProcessError:
            pass
            
        return None
    
    def _extract_lesson_from_commit(self, commit_info: Dict) -> Optional[CommitLesson]:
        """Extract lesson from commit information."""
        message = commit_info['message']
        
        # Check if this is a fix commit
        is_fix = any(re.search(pattern, message) for pattern in self.fix_patterns)
        
        if not is_fix:
            return None
        
        # Extract lesson components
        context = self._extract_commit_context(message)
        problem = self._extract_commit_problem(message)
        solution = self._extract_commit_solution(message, commit_info.get('files_changed', []))
        category = self._categorize_commit(message, commit_info.get('files_changed', []))
        
        return CommitLesson(
            commit_hash=commit_info['hash'][:8],
            commit_message=message,
            context=context,
            problem=problem,
            solution=solution,
            category=category,
            files_changed=commit_info.get('files_changed', []),
            lines_changed=commit_info.get('lines_changed', 0),
            timestamp=commit_info['date']
        )
    
    def _extract_commit_context(self, message: str) -> str:
        """Extract context from commit message."""
        for pattern in self.context_patterns:
            match = re.search(pattern, message)
            if match:
                return match.group(2).strip()
        
        # Fallback: extract from commit message structure
        if ':' in message:
            return message.split(':')[1].strip()
        
        return "Development work"
    
    def _extract_commit_problem(self, message: str) -> str:
        """Extract problem description from commit message."""
        # Look for specific error descriptions
        error_descriptions = [
            r"(?i)(blank page|nothing shows|not appearing)",
            r"(?i)(build error|compilation error|syntax error)",
            r"(?i)(constraint error|autolayout issue|layout problem)",
            r"(?i)(navigation.*?(?:not working|broken|failed))",
            r"(?i)(missing|undefined|not found)"
        ]
        
        for pattern in error_descriptions:
            match = re.search(pattern, message)
            if match:
                return match.group(0)
        
        # Extract from fix patterns
        for pattern in self.fix_patterns:
            match = re.search(pattern, message)
            if match and len(match.groups()) > 1:
                return f"Issue with {match.group(2)}"
        
        return "Development issue encountered"
    
    def _extract_commit_solution(self, message: str, files_changed: List[str]) -> str:
        """Extract solution from commit message and file changes."""
        # Look for solution descriptions in message
        solution_patterns = [
            r"(?i)(added|implemented|created|updated)\s+(.+)",
            r"(?i)(changed|modified|fixed)\s+(.+?)\s+to\s+(.+)",
            r"(?i)(now\s+using|switched\s+to|replaced\s+with)\s+(.+)"
        ]
        
        for pattern in solution_patterns:
            match = re.search(pattern, message)
            if match:
                return match.group(0)
        
        # Infer from file changes
        if files_changed:
            if any('View' in f for f in files_changed):
                return "Updated UI components and layout constraints"
            elif any('Service' in f for f in files_changed):
                return "Modified service layer implementation"
            elif any('Controller' in f for f in files_changed):
                return "Fixed view controller logic and navigation"
        
        return "Applied technical fix"
    
    def _categorize_commit(self, message: str, files_changed: List[str]) -> str:
        """Categorize commit based on message and files."""
        message_lower = message.lower()
        
        # Check message content
        if any(keyword in message_lower for keyword in ["constraint", "layout", "autolayout"]):
            return "UI/Layout"
        elif any(keyword in message_lower for keyword in ["navigation", "push", "present"]):
            return "Navigation"
        elif any(keyword in message_lower for keyword in ["build", "compile", "xcode"]):
            return "Build/Compilation"
        elif any(keyword in message_lower for keyword in ["api", "supabase", "network"]):
            return "API Integration"
        
        # Check file patterns
        if files_changed:
            if any('View' in f or 'UI' in f for f in files_changed):
                return "UI/Layout"
            elif any('Service' in f or 'Manager' in f for f in files_changed):
                return "Architecture"
            elif any('Controller' in f for f in files_changed):
                return "Navigation"
        
        return "General"
    
    def generate_commit_lesson_summary(self, lessons: List[CommitLesson]) -> str:
        """Generate a summary of lessons from commits."""
        if not lessons:
            return "No lessons extracted from recent commits."
        
        summary = f"## Commit Analysis Summary ({len(lessons)} lessons extracted)\n\n"
        
        # Group by category
        by_category = {}
        for lesson in lessons:
            if lesson.category not in by_category:
                by_category[lesson.category] = []
            by_category[lesson.category].append(lesson)
        
        for category, cat_lessons in by_category.items():
            summary += f"### {category} ({len(cat_lessons)} lessons)\n"
            for lesson in cat_lessons:
                summary += f"- **{lesson.commit_hash}**: {lesson.problem} → {lesson.solution}\n"
            summary += "\n"
        
        return summary

# Example usage
if __name__ == "__main__":
    analyzer = CommitAnalyzer()
    recent_lessons = analyzer.analyze_recent_commits(10)
    
    print(analyzer.generate_commit_lesson_summary(recent_lessons))
    
    for lesson in recent_lessons:
        print(f"\nLesson from {lesson.commit_hash}:")
        print(f"Context: {lesson.context}")
        print(f"Problem: {lesson.problem}")
        print(f"Solution: {lesson.solution}")
        print(f"Category: {lesson.category}")
        print(f"Files: {', '.join(lesson.files_changed)}")