#!/usr/bin/env python3
"""
Lesson Formatter for Lessons Learned Tracker
Formats extracted lessons into CLAUDE.md compatible markdown following established patterns.
"""

import re
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass

@dataclass
class FormattedLesson:
    title: str
    context: str
    numbered_points: List[str]
    key_takeaway: str
    category: str
    metadata: Dict[str, str]

class LessonFormatter:
    """Formats lessons to match CLAUDE.md structure and style."""
    
    def __init__(self):
        self.section_templates = {
            "UI/Layout": {
                "title_suffix": "Layout Fix - Key Learnings",
                "focus_areas": ["Constraint setup", "View hierarchy", "Grid layouts", "Text handling"]
            },
            "Navigation": {
                "title_suffix": "Navigation Implementation - Key Learnings", 
                "focus_areas": ["Controller setup", "Navigation flow", "View presentation", "Memory management"]
            },
            "API Integration": {
                "title_suffix": "API Integration - Key Learnings",
                "focus_areas": ["Service configuration", "Error handling", "Data parsing", "Network reliability"]
            },
            "Build/Compilation": {
                "title_suffix": "Build Configuration - Key Learnings",
                "focus_areas": ["Project setup", "File references", "Dependency management", "Compilation issues"]
            },
            "Architecture": {
                "title_suffix": "Architecture Implementation - Key Learnings",
                "focus_areas": ["Design patterns", "Component organization", "Service layer", "Data flow"]
            }
        }
    
    def format_lesson_section(self, lessons: List, category: str, feature_name: str) -> str:
        """Format multiple related lessons into a complete CLAUDE.md section."""
        
        if not lessons:
            return ""
        
        template = self.section_templates.get(category, {
            "title_suffix": "Implementation - Key Learnings",
            "focus_areas": ["Technical implementation", "Problem resolution", "Best practices", "Architecture decisions"]
        })
        
        # Generate section header
        section_header = f"### {feature_name} {template['title_suffix']}\n\n"
        
        # Add context paragraph
        main_lesson = lessons[0] if lessons else None
        if main_lesson:
            context = f"**Context**: {main_lesson.context}\n\n"
        else:
            context = f"**Context**: Implementation and debugging of {feature_name.lower()}.\n\n"
        
        # Format numbered points
        numbered_points = ""
        for i, lesson in enumerate(lessons, 1):
            numbered_points += self._format_numbered_point(lesson, i)
            numbered_points += "\n"
        
        # Generate key takeaway
        key_takeaway = self._generate_section_takeaway(lessons, category)
        
        return section_header + context + numbered_points + key_takeaway + "\n"
    
    def _format_numbered_point(self, lesson, point_number: int) -> str:
        """Format a single lesson as a numbered point."""
        
        # Generate title based on lesson content
        title = self._generate_point_title(lesson)
        
        # Format bullet points
        points = []
        if hasattr(lesson, 'problem') and lesson.problem:
            points.append(lesson.problem)
        if hasattr(lesson, 'solution') and lesson.solution:
            points.append(lesson.solution)
        
        # Add technical details if available
        if hasattr(lesson, 'files_involved') and lesson.files_involved:
            points.append(f"Files involved: {', '.join(lesson.files_involved)}")
        
        # Add prevention/best practice
        prevention = self._generate_prevention_tip(lesson)
        if prevention:
            points.append(prevention)
        
        formatted_points = "\n".join(f"- {point}" for point in points)
        
        return f"#### {point_number}. **{title}**\n{formatted_points}\n"
    
    def _generate_point_title(self, lesson) -> str:
        """Generate a descriptive title for a lesson point."""
        
        # Extract key technical terms
        text_to_analyze = ""
        if hasattr(lesson, 'problem'):
            text_to_analyze += lesson.problem + " "
        if hasattr(lesson, 'solution'):
            text_to_analyze += lesson.solution + " "
        if hasattr(lesson, 'commit_message'):
            text_to_analyze += lesson.commit_message + " "
        
        text_lower = text_to_analyze.lower()
        
        # Technical term mapping
        title_patterns = {
            "constraint": "AutoLayout Constraint Management",
            "navigation": "Navigation Controller Setup", 
            "build": "Build Configuration Issues",
            "height": "Container Height Requirements",
            "delegate": "Delegate Pattern Implementation",
            "api": "API Integration Challenges",
            "sync": "Background Sync Optimization",
            "wallet": "Bitcoin Wallet Integration",
            "grid": "Grid Layout Precision",
            "modular": "Modular Architecture Benefits"
        }
        
        for keyword, title in title_patterns.items():
            if keyword in text_lower:
                return title
        
        # Category-based fallback titles
        category_titles = {
            "UI/Layout": "Layout Configuration Challenge",
            "Navigation": "Navigation Flow Resolution", 
            "API Integration": "Service Integration Solution",
            "Build/Compilation": "Build Process Optimization",
            "Architecture": "Architecture Pattern Application"
        }
        
        category = getattr(lesson, 'category', 'General')
        return category_titles.get(category, "Development Challenge Resolution")
    
    def _generate_prevention_tip(self, lesson) -> str:
        """Generate prevention tip based on lesson category and content."""
        
        category = getattr(lesson, 'category', 'General')
        
        category_tips = {
            "UI/Layout": "Always verify container height constraints before adding child views",
            "Navigation": "Ensure navigation controller is embedded in AppDelegate setup",
            "API Integration": "Add proper error handling and retry logic for external API calls", 
            "Build/Compilation": "Check Xcode project file references and build target settings",
            "Architecture": "Follow established delegate patterns and modular component design"
        }
        
        base_tip = category_tips.get(category, "Document solution for future reference")
        
        # Customize based on specific lesson content
        if hasattr(lesson, 'problem'):
            problem_lower = lesson.problem.lower()
            if "height" in problem_lower or "container" in problem_lower:
                return "Always add explicit height constraints to container views in ScrollView hierarchies"
            elif "blank" in problem_lower:
                return "Verify view hierarchy setup and constraint relationships before debugging complex layout issues"
            elif "build" in problem_lower:
                return "Test incremental changes and verify project file integrity after adding new components"
        
        return base_tip
    
    def _generate_section_takeaway(self, lessons: List, category: str) -> str:
        """Generate the key takeaway paragraph for a lesson section."""
        
        if not lessons:
            return "**Key Takeaway**: Systematic problem-solving and documentation improves development efficiency.\n"
        
        # Count common themes
        common_themes = {
            "constraint": 0,
            "modular": 0, 
            "navigation": 0,
            "build": 0,
            "delegate": 0
        }
        
        for lesson in lessons:
            text_to_check = ""
            if hasattr(lesson, 'problem'):
                text_to_check += lesson.problem.lower() + " "
            if hasattr(lesson, 'solution'):
                text_to_check += lesson.solution.lower() + " "
            
            for theme in common_themes:
                if theme in text_to_check:
                    common_themes[theme] += 1
        
        # Generate takeaway based on dominant themes
        dominant_theme = max(common_themes.items(), key=lambda x: x[1])
        
        takeaways = {
            "constraint": "AutoLayout constraint management requires careful attention to view hierarchy timing and explicit sizing. Container views need guaranteed dimensions before child content can layout properly.",
            "modular": "Modular architecture planning from the start prevents complex refactoring later. Breaking features into focused components under 500 lines creates maintainable, debuggable code.",
            "navigation": "Navigation controller setup is foundational to app functionality. Proper embedding and configuration prevents silent failures in view presentation.",
            "build": "Build configuration issues often stem from project file references or dependency setup. Systematic verification prevents compilation problems.",
            "delegate": "Delegate patterns create clean component communication and enable reusable, testable code. Consistent delegate design scales well across complex features."
        }
        
        theme_name = dominant_theme[0]
        if dominant_theme[1] > 0:
            return f"**Key Takeaway**: {takeaways.get(theme_name, 'Systematic problem-solving and documentation improves development efficiency.')}\n"
        
        return "**Key Takeaway**: Methodical debugging approach and proper documentation prevents recurring issues and improves code maintainability.\n"
    
    def extract_existing_lesson_number(self, claude_md_content: str) -> int:
        """Extract the highest existing lesson number from CLAUDE.md."""
        # Find all numbered lessons: #### 1., #### 2., etc.
        pattern = r'#### (\d+)\.\s+\*\*'
        matches = re.findall(pattern, claude_md_content)
        
        if matches:
            return max(int(match) for match in matches)
        
        return 0
    
    def find_insertion_point(self, claude_md_content: str, category: str) -> int:
        """Find the best place to insert new lesson in CLAUDE.md."""
        lines = claude_md_content.split('\n')
        
        # Look for existing sections with similar category
        category_patterns = {
            "UI/Layout": ["layout", "constraint", "ui", "grid"],
            "Navigation": ["navigation", "controller", "view"],
            "API Integration": ["api", "service", "network", "supabase"],
            "Build/Compilation": ["build", "compilation", "xcode"],
            "Architecture": ["architecture", "pattern", "delegate", "modular"]
        }
        
        keywords = category_patterns.get(category, [])
        
        # Find best section to append to
        for i, line in enumerate(lines):
            if line.startswith("###") and any(keyword in line.lower() for keyword in keywords):
                # Find end of this section
                for j in range(i + 1, len(lines)):
                    if lines[j].startswith("###"):
                        return j  # Insert before next section
                return len(lines)  # Append at end
        
        # If no matching section found, append at end
        return len(lines)

# Usage example for agent integration
def format_lesson_for_claude_md(lesson_data: Dict, claude_md_path: str) -> str:
    """Main function for agent to format and position lessons."""
    formatter = LessonFormatter()
    
    # Read existing CLAUDE.md
    with open(claude_md_path, 'r') as f:
        content = f.read()
    
    # Get next lesson number
    next_number = formatter.extract_existing_lesson_number(content) + 1
    
    # Format the lesson
    if 'lessons' in lesson_data:
        formatted = formatter.format_lesson_section(
            lesson_data['lessons'], 
            lesson_data.get('category', 'General'),
            lesson_data.get('feature_name', 'Development')
        )
    else:
        # Single lesson formatting
        formatted = formatter._format_numbered_point(lesson_data, next_number)
    
    return formatted