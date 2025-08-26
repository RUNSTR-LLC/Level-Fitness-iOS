#!/usr/bin/env python3
"""
Chat Pattern Detector for Lessons Learned Tracker
Monitors chat conversations to extract problem-solution pairs for documentation.
"""

import re
import json
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

@dataclass
class LessonPattern:
    context: str
    problem: str
    solution: str
    category: str
    time_spent: Optional[str] = None
    files_involved: List[str] = None
    
class ChatPatternDetector:
    """Detects problem-solution patterns in chat conversations."""
    
    def __init__(self):
        self.error_patterns = [
            r"(?i)(didn't work|not working|broken|failed|error)",
            r"(?i)(blank page|nothing shows|not appearing)",
            r"(?i)(build error|compilation error|syntax error)",
            r"(?i)(constraint error|autolayout|layout issue)",
            r"(?i)(crash|exception|fatal error)"
        ]
        
        self.solution_patterns = [
            r"(?i)(fixed by|resolved by|solution was)",
            r"(?i)(turns out|actually need to|found out)",
            r"(?i)(working now|solved|got it working)",
            r"(?i)(the issue was|root cause)",
            r"(?i)(added|changed|modified|updated).*and.*work"
        ]
        
        self.time_patterns = [
            r"(?i)(spent|took|wasted).*?(\d+)\s*(hour|minute|min)s?",
            r"(?i)(\d+)\s*(hour|minute|min)s?.*?(debug|fix|solve)",
            r"(?i)(finally|eventually).*?(\d+)\s*(hour|minute|min)s?"
        ]
        
        self.category_keywords = {
            "UI/Layout": ["constraint", "autolayout", "view", "layout", "grid", "scroll"],
            "Navigation": ["navigation", "push", "present", "segue", "view controller"],
            "API Integration": ["supabase", "coinos", "network", "api", "request", "response"],
            "Build/Compilation": ["build", "compile", "xcode", "syntax", "import", "missing"],
            "Architecture": ["delegate", "pattern", "service", "manager", "singleton"],
            "Performance": ["memory", "background", "sync", "performance", "optimization"]
        }
    
    def extract_lessons_from_conversation(self, conversation_text: str) -> List[LessonPattern]:
        """Extract lesson patterns from a conversation transcript."""
        lessons = []
        
        # Split conversation into exchanges
        exchanges = self._split_into_exchanges(conversation_text)
        
        for exchange in exchanges:
            lesson = self._analyze_exchange(exchange)
            if lesson:
                lessons.append(lesson)
                
        return lessons
    
    def _split_into_exchanges(self, text: str) -> List[str]:
        """Split conversation into problem-solution exchanges."""
        # Split by user/assistant markers or timestamps
        exchanges = []
        current_exchange = ""
        
        lines = text.split('\n')
        for line in lines:
            if any(pattern in line.lower() for pattern in ["user:", "assistant:", "error:", "fixed:"]):
                if current_exchange.strip():
                    exchanges.append(current_exchange.strip())
                current_exchange = line
            else:
                current_exchange += "\n" + line
        
        if current_exchange.strip():
            exchanges.append(current_exchange.strip())
            
        return exchanges
    
    def _analyze_exchange(self, exchange: str) -> Optional[LessonPattern]:
        """Analyze a single exchange for lesson patterns."""
        has_error = any(re.search(pattern, exchange) for pattern in self.error_patterns)
        has_solution = any(re.search(pattern, exchange) for pattern in self.solution_patterns)
        
        if not (has_error and has_solution):
            return None
            
        # Extract components
        context = self._extract_context(exchange)
        problem = self._extract_problem(exchange)
        solution = self._extract_solution(exchange)
        category = self._categorize_lesson(exchange)
        time_spent = self._extract_time_spent(exchange)
        files_involved = self._extract_files(exchange)
        
        if problem and solution:
            return LessonPattern(
                context=context,
                problem=problem,
                solution=solution,
                category=category,
                time_spent=time_spent,
                files_involved=files_involved
            )
        
        return None
    
    def _extract_context(self, text: str) -> str:
        """Extract what was being built/worked on."""
        context_patterns = [
            r"(?i)(implementing|building|creating|working on|adding)\s+(.+?)(?:\.|,|$)",
            r"(?i)(trying to|attempting to)\s+(.+?)(?:\.|,|$)",
            r"(?i)(?:for|in|on)\s+(.*?(?:page|view|component|feature|wizard))(?:\.|,|$)"
        ]
        
        for pattern in context_patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(2).strip()
        
        return "Development work"
    
    def _extract_problem(self, text: str) -> str:
        """Extract the specific problem description."""
        # Look for sentences containing error patterns
        sentences = re.split(r'[.!?]+', text)
        
        for sentence in sentences:
            if any(re.search(pattern, sentence) for pattern in self.error_patterns):
                return sentence.strip()
        
        return "Issue encountered"
    
    def _extract_solution(self, text: str) -> str:
        """Extract the solution description."""
        # Look for sentences containing solution patterns
        sentences = re.split(r'[.!?]+', text)
        
        for sentence in sentences:
            if any(re.search(pattern, sentence) for pattern in self.solution_patterns):
                return sentence.strip()
        
        return "Solution applied"
    
    def _categorize_lesson(self, text: str) -> str:
        """Categorize the lesson based on keywords."""
        text_lower = text.lower()
        
        scores = {}
        for category, keywords in self.category_keywords.items():
            scores[category] = sum(1 for keyword in keywords if keyword in text_lower)
        
        if scores:
            return max(scores, key=scores.get)
        
        return "General"
    
    def _extract_time_spent(self, text: str) -> Optional[str]:
        """Extract time spent on the issue."""
        for pattern in self.time_patterns:
            match = re.search(pattern, text)
            if match:
                number = match.group(2) if len(match.groups()) > 1 else match.group(1)
                unit = match.group(3) if len(match.groups()) > 2 else match.group(2)
                return f"{number} {unit}s"
        
        return None
    
    def _extract_files(self, text: str) -> List[str]:
        """Extract file names mentioned in the conversation."""
        # Look for Swift file patterns
        swift_files = re.findall(r'(\w+(?:View|Controller|Service|Manager)\.swift)', text)
        
        # Look for explicit file paths
        file_paths = re.findall(r'(\w+/\w+/\w+\.swift)', text)
        
        files = list(set(swift_files + file_paths))
        return files[:5]  # Limit to most relevant files
    
    def format_lesson_for_claude_md(self, lesson: LessonPattern, lesson_number: int) -> str:
        """Format a lesson for inclusion in CLAUDE.md."""
        
        formatted_lesson = f"""
#### {lesson_number}. **{self._generate_lesson_title(lesson)}**
- {lesson.problem}
- {self._extract_root_cause(lesson)}
- {lesson.solution}
- {self._generate_prevention_tip(lesson)}"""

        if lesson.files_involved:
            formatted_lesson += f"\n- Files involved: {', '.join(lesson.files_involved)}"
        
        if lesson.time_spent:
            formatted_lesson += f"\n- Time impact: {lesson.time_spent}"
            
        return formatted_lesson
    
    def _generate_lesson_title(self, lesson: LessonPattern) -> str:
        """Generate a descriptive title for the lesson."""
        # Extract key technical terms for title
        problem_words = lesson.problem.lower().split()
        solution_words = lesson.solution.lower().split()
        
        key_terms = []
        technical_terms = ["constraint", "navigation", "layout", "build", "api", "sync", "wallet"]
        
        for term in technical_terms:
            if term in problem_words or term in solution_words:
                key_terms.append(term.title())
        
        if key_terms:
            return f"{' '.join(key_terms)} Issue Resolution"
        
        return f"{lesson.category} Problem Solving"
    
    def _extract_root_cause(self, lesson: LessonPattern) -> str:
        """Infer root cause from problem description."""
        problem_lower = lesson.problem.lower()
        
        if "constraint" in problem_lower:
            return "Root cause: Missing or conflicting AutoLayout constraints"
        elif "blank" in problem_lower or "nothing" in problem_lower:
            return "Root cause: View hierarchy or display logic issue"
        elif "build" in problem_lower or "compile" in problem_lower:
            return "Root cause: Compilation or project configuration issue"
        elif "navigation" in problem_lower:
            return "Root cause: Navigation controller or routing setup issue"
        else:
            return "Root cause: Implementation or configuration issue"
    
    def _generate_prevention_tip(self, lesson: LessonPattern) -> str:
        """Generate prevention strategy based on lesson category."""
        category_tips = {
            "UI/Layout": "Always verify view hierarchy setup before adding constraints",
            "Navigation": "Ensure navigation controller is properly configured in AppDelegate",
            "API Integration": "Add proper error handling and validation for external API calls",
            "Build/Compilation": "Check Xcode project file references and build settings",
            "Architecture": "Follow established delegate and service patterns",
            "Performance": "Profile and test background task performance early"
        }
        
        return category_tips.get(lesson.category, "Document and test solution for future reference")

# Example usage for the agent
if __name__ == "__main__":
    detector = ChatPatternDetector()
    
    # Example conversation text
    sample_conversation = """
    User: The team creation wizard is showing a blank page
    Assistant: Let me check the view hierarchy...
    [Several debugging attempts]
    User: turns out the container needed a height constraint - fixed by adding heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
    Assistant: That makes sense - container views need explicit sizing
    """
    
    lessons = detector.extract_lessons_from_conversation(sample_conversation)
    
    for i, lesson in enumerate(lessons, 1):
        formatted = detector.format_lesson_for_claude_md(lesson, i)
        print(formatted)