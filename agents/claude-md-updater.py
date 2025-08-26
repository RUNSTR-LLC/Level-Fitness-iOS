#!/usr/bin/env python3
"""
CLAUDE.md Updater for Lessons Learned Tracker
Handles updating CLAUDE.md with new lessons while maintaining existing structure and formatting.
"""

import re
import os
from datetime import datetime
from typing import Dict, List, Optional, Tuple

class ClaudeMdUpdater:
    """Updates CLAUDE.md with new lessons while preserving structure."""
    
    def __init__(self, claude_md_path: str):
        self.claude_md_path = claude_md_path
        self.backup_path = claude_md_path + ".backup"
    
    def add_lesson_to_section(self, lesson_content: str, category: str, feature_name: str) -> bool:
        """Add a new lesson section to CLAUDE.md."""
        try:
            # Create backup
            self._create_backup()
            
            # Read current content
            with open(self.claude_md_path, 'r') as f:
                content = f.read()
            
            # Find insertion point
            insertion_point = self._find_section_insertion_point(content, category)
            
            # Insert new section
            updated_content = self._insert_lesson_section(content, lesson_content, insertion_point)
            
            # Write updated content
            with open(self.claude_md_path, 'w') as f:
                f.write(updated_content)
            
            print(f"✅ Added {feature_name} lesson to CLAUDE.md")
            return True
            
        except Exception as e:
            print(f"❌ Error updating CLAUDE.md: {e}")
            self._restore_backup()
            return False
    
    def add_lesson_points_to_existing_section(self, section_name: str, new_points: List[str]) -> bool:
        """Add new numbered points to an existing lesson section."""
        try:
            self._create_backup()
            
            with open(self.claude_md_path, 'r') as f:
                content = f.read()
            
            # Find the section
            section_start, section_end = self._find_existing_section(content, section_name)
            
            if section_start == -1:
                print(f"❌ Section '{section_name}' not found")
                return False
            
            # Extract current highest number in section
            section_content = content[section_start:section_end]
            highest_number = self._extract_highest_lesson_number(section_content)
            
            # Format new points
            formatted_points = ""
            for i, point in enumerate(new_points, highest_number + 1):
                formatted_points += f"#### {i}. **{point['title']}**\n"
                for bullet in point['bullets']:
                    formatted_points += f"- {bullet}\n"
                formatted_points += "\n"
            
            # Insert before key takeaway
            takeaway_pos = content.find("**Key Takeaway**", section_start)
            if takeaway_pos != -1:
                insert_pos = takeaway_pos
            else:
                insert_pos = section_end
            
            updated_content = content[:insert_pos] + formatted_points + content[insert_pos:]
            
            with open(self.claude_md_path, 'w') as f:
                f.write(updated_content)
            
            print(f"✅ Added {len(new_points)} points to {section_name}")
            return True
            
        except Exception as e:
            print(f"❌ Error updating section: {e}")
            self._restore_backup()
            return False
    
    def update_section_takeaway(self, section_name: str, new_takeaway: str) -> bool:
        """Update the key takeaway for an existing section."""
        try:
            self._create_backup()
            
            with open(self.claude_md_path, 'r') as f:
                content = f.read()
            
            # Find existing takeaway
            takeaway_pattern = r'(\*\*Key Takeaway\*\*:.*?)(?=\n###|\n\n###|$)'
            section_start, _ = self._find_existing_section(content, section_name)
            
            if section_start == -1:
                return False
            
            # Find takeaway in section
            section_content = content[section_start:]
            match = re.search(takeaway_pattern, section_content, re.DOTALL)
            
            if match:
                old_takeaway = match.group(1)
                updated_section = section_content.replace(old_takeaway, f"**Key Takeaway**: {new_takeaway}")
                updated_content = content[:section_start] + updated_section
                
                with open(self.claude_md_path, 'w') as f:
                    f.write(updated_content)
                
                print(f"✅ Updated takeaway for {section_name}")
                return True
            
        except Exception as e:
            print(f"❌ Error updating takeaway: {e}")
            self._restore_backup()
            
        return False
    
    def _create_backup(self):
        """Create backup of CLAUDE.md before modification."""
        if os.path.exists(self.claude_md_path):
            with open(self.claude_md_path, 'r') as src:
                content = src.read()
            with open(self.backup_path, 'w') as dst:
                dst.write(content)
    
    def _restore_backup(self):
        """Restore CLAUDE.md from backup if update fails."""
        if os.path.exists(self.backup_path):
            with open(self.backup_path, 'r') as src:
                content = src.read()
            with open(self.claude_md_path, 'w') as dst:
                dst.write(content)
            print("🔄 Restored CLAUDE.md from backup")
    
    def _find_section_insertion_point(self, content: str, category: str) -> int:
        """Find where to insert a new lesson section."""
        lines = content.split('\n')
        
        # Category keywords for finding similar sections
        category_keywords = {
            "UI/Layout": ["layout", "constraint", "ui", "grid", "view"],
            "Navigation": ["navigation", "controller", "flow", "presentation"],
            "API Integration": ["api", "service", "network", "supabase", "integration"],
            "Build/Compilation": ["build", "compilation", "xcode", "project"],
            "Architecture": ["architecture", "pattern", "delegate", "modular", "component"]
        }
        
        keywords = category_keywords.get(category, [])
        
        # Find last section with similar keywords
        last_similar_section = -1
        for i, line in enumerate(lines):
            if line.startswith("###") and any(keyword in line.lower() for keyword in keywords):
                last_similar_section = i
        
        if last_similar_section != -1:
            # Find end of that section
            for i in range(last_similar_section + 1, len(lines)):
                if lines[i].startswith("###"):
                    return i  # Insert before next section
            return len(lines)  # Append at end
        
        # No similar section - find "Development Lessons Learned" or append at end
        for i, line in enumerate(lines):
            if "Development Lessons" in line or "Key Lessons" in line:
                # Insert after this header
                return i + 2
        
        # Find "## Notes for Development" section to insert before it
        for i, line in enumerate(lines):
            if line.startswith("## Notes for Development"):
                return i
        
        return len(lines)
    
    def _find_existing_section(self, content: str, section_name: str) -> Tuple[int, int]:
        """Find start and end positions of an existing section."""
        lines = content.split('\n')
        section_start = -1
        section_end = len(content)
        
        for i, line in enumerate(lines):
            if section_name.lower() in line.lower() and line.startswith("###"):
                section_start = content.find(line)
                
                # Find next section start
                for j in range(i + 1, len(lines)):
                    if lines[j].startswith("###"):
                        section_end = content.find(lines[j])
                        break
                break
        
        return section_start, section_end
    
    def _extract_highest_lesson_number(self, section_content: str) -> int:
        """Extract highest numbered lesson point in a section."""
        pattern = r'#### (\d+)\.\s+\*\*'
        matches = re.findall(pattern, section_content)
        
        if matches:
            return max(int(match) for match in matches)
        
        return 0
    
    def _insert_lesson_section(self, content: str, lesson_section: str, insertion_point: int) -> str:
        """Insert new lesson section at specified point."""
        if insertion_point >= len(content):
            return content + "\n\n" + lesson_section
        
        lines = content.split('\n')
        
        # Convert character position to line position if needed
        if insertion_point > len(lines):
            insertion_line = len(lines)
        else:
            insertion_line = insertion_point
        
        # Insert with proper spacing
        lines.insert(insertion_line, "")
        lines.insert(insertion_line + 1, lesson_section.strip())
        lines.insert(insertion_line + 2, "")
        
        return '\n'.join(lines)
    
    def get_lesson_statistics(self) -> Dict[str, int]:
        """Get statistics about lessons in CLAUDE.md."""
        try:
            with open(self.claude_md_path, 'r') as f:
                content = f.read()
            
            # Count sections
            section_count = len(re.findall(r'^### .* - Key Learnings', content, re.MULTILINE))
            
            # Count numbered points
            point_count = len(re.findall(r'#### \d+\.\s+\*\*', content))
            
            # Count by category
            categories = {
                "UI/Layout": len(re.findall(r'(?i)layout.*key learnings', content)),
                "Navigation": len(re.findall(r'(?i)navigation.*key learnings', content)),
                "API": len(re.findall(r'(?i)(api|integration).*key learnings', content)),
                "Build": len(re.findall(r'(?i)(build|compilation).*key learnings', content)),
                "Architecture": len(re.findall(r'(?i)(architecture|implementation).*key learnings', content))
            }
            
            return {
                "total_sections": section_count,
                "total_points": point_count,
                "categories": categories,
                "last_updated": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"error": str(e)}

# Example usage for the agent
if __name__ == "__main__":
    updater = ClaudeMdUpdater("/Users/dakotabrown/LevelFitness-IOS/CLAUDE.md")
    stats = updater.get_lesson_statistics()
    print(f"Current CLAUDE.md statistics: {stats}")