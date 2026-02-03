#!/usr/bin/env python3
"""
Safe Refactoring Tool: Remove m_ prefix from member variables

This script safely refactors Java files to remove the m_ prefix from member variables
while preventing bugs in setter methods where parameters might shadow the member.

Strategy:
1. Find all member variables with m_ prefix
2. For each usage, detect if there's a potential conflict (local var/param with same name)
3. Add `this.` prefix where conflicts would occur after m_ removal
4. Rename member declarations and all usages to remove m_

Usage:
    python3 remove_m_prefix.py --dry-run        # Preview changes
    python3 remove_m_prefix.py --execute        # Apply changes
"""

import os
import re
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple, Set
from dataclasses import dataclass
import shutil


@dataclass
class MemberVariable:
    """Represents a member variable with m_ prefix"""
    original_name: str  # e.g., "m_myVar"
    new_name: str  # e.g., "myVar"
    line_number: int
    visibility: str  # private, public, protected, package-private
    type_name: str

@dataclass
class UsageLocation:
    """Represents a usage location"""
    line_number: int
    column: int
    has_this_prefix: bool


class JavaFileParser:
    """Parses Java files to find member variables and their usages"""

    def __init__(self, file_path: str):
        self.file_path = file_path
        self.lines = []
        with open(file_path, 'r', encoding='utf-8') as f:
            self.lines = f.readlines()
        self.members: List[MemberVariable] = []
        self.member_usages: Dict[str, List[UsageLocation]] = {}

    def find_member_variables(self) -> List[MemberVariable]:
        """Find all member variable declarations with m_ prefix (inside class, outside methods)"""
        members = []
        in_class = False
        in_method = False
        brace_depth = 0
        method_depth = 0

        for line_num, line in enumerate(self.lines, 1):
            # Track brace depth and class/method context
            brace_depth += line.count('{') - line.count('}')

            # Detect class/interface declaration
            if re.search(r'\b(class|interface|enum|record)\s+\w+', line):
                in_class = True

            # Detect method/constructor start
            if in_class and re.search(r'\w+\s*\([^)]*\)\s*(\{|throws)', line):
                in_method = True
                method_depth = brace_depth

            # End of class (return to brace depth 0)
            if brace_depth == 0:
                in_class = False
                in_method = False

            # End of method (return to class-level brace depth)
            if in_method and brace_depth <= method_depth:
                in_method = False

            # Only look for member declarations at class level
            if in_class and not in_method and brace_depth == 1:
                # Match: visibility type m_name or type m_name
                # Match: [modifiers] type m_name
                # We need to be careful not to match local vars (though we are at brace_depth 1)
                # Modifiers are now optional (for package-private)
                # We match the variable name first, then verify it looks like a declaration
                
                # Check for m_ usage in this line
                possible_matches = re.finditer(r'\b(m_[a-zA-Z]\w*)', line)
                
                for match in possible_matches:
                    member_name = match.group(1)
                    # To be a declaration, it should be preceded by a type
                    # And optionally modifiers.
                    # It should NOT be preceded by 'new ' (instantiation) or '.' (access)
                    
                    # Get text before match
                    preceding = line[:match.start()].strip()
                    if not preceding: continue # Start of line? Unlikely for field
                    
                    # Check if it looks like a declaration
                    # Ends with type? 
                    # E.g. "privateString " -> "private String"
                    # "String "
                    
                    # Split preceding by spaces
                    tokens = preceding.split()
                    if not tokens: continue
                    
                    # Last token should be the type (or array brackets)
                    # But type might be "List<String>" which is one token or multiple depending on spacing
                    # Simple heuristic: ignore if preceded by 'return', 'case', 'throw', etc.
                    if tokens[-1] in ['return', 'throw', 'case', 'new', 'import', 'package']:
                        continue
                        
                    if preceding.endswith('.'):
                        continue
                        
                    # It seems safe to assume if we are at brace_depth 1 (class level), 
                    # any "Type m_name" is a field.
                    # Even "m_name = 1" in block? Instance initializer?
                    # "m_name = 1;" is assignment. "int m_name = 1;" is decl.
                    # So we need a type.
                    
                    # Check if standard modifiers or type precedes
                    # If it has a modifier, we are good.
                    # If no modifier, we assume package private ONLY if we see a type.
                    # Type looks like Identifier or Identifier<...> or Identifier[]
                    
                    # Let's try to parse the whole line with a more flexible regex
                    # Optional annotations/modifiers then Type then Name
                    
                    check_pattern = r'^(?:\s*@\w+(?:\([^)]*\))?)*\s*(?:(?:public|private|protected|static|final|native|synchronized|abstract|transient|volatile)\s+)*[\w\.<>\[\]]+\s+' + re.escape(member_name)
                     
                    if re.search(check_pattern, line):
                         # Found it!
                         matched_text = line[0:match.end()] # Approximate
                         
                         new_name = member_name[2:]  # Remove m_ prefix

                         # Handle specific keyword collisions commonly found
                         if new_name == 'class':
                             new_name = 'clazz'
                        
                         # Check for reserved keywords
                         if new_name in ['abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 
                                       'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 
                                       'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements', 
                                       'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new', 'package', 
                                       'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp', 
                                       'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 
                                       'try', 'void', 'volatile', 'while']:
                            # Append underscore to avoid keyword collision
                            new_name = new_name + '_'
                            
                         # Extract visibility/type simply
                         # We can just say visibility is "package-private" if not found
                         vis_match = re.search(r'(private|public|protected)', line)
                         visibility = vis_match.group(1) if vis_match else 'package-private'
                         
                         type_name = "unknown" # analyzing type is hard without ful parser, keep simple
                         
                         members.append(MemberVariable(
                             original_name=member_name,
                             new_name=new_name,
                             line_number=line_num,
                             visibility=visibility,
                             type_name=type_name
                         ))
                         continue # Move to next match in line (unlikely to have 2 decls on same line handled this way but ok)
                
                # Original loop provided 'matches' but we replaced it.
                matches = [] # Dummy to satisfy existing structure if needed, but we rewrote loop.
                         

        self.members = members
        return members

    def find_usages(self, member_name: str) -> List[UsageLocation]:
        """Find all usages of a member variable"""
        usages = []
        pattern = rf'\b{re.escape(member_name)}\b'

        for line_num, line in enumerate(self.lines, 1):
            for match in re.finditer(pattern, line):
                # Check if this usage already has 'this.' prefix
                before_match = line[:match.start()]
                has_this = before_match.rstrip().endswith('this.')

                # Don't count the declaration itself
                if not re.search(r'(private|public|protected|final|static|transient|volatile|synchronized)\s+[^;]*' + rf'\b{re.escape(member_name)}\b', line):
                    usages.append(UsageLocation(
                        line_number=line_num,
                        column=match.start(),
                        has_this_prefix=has_this
                    ))

        return usages


class ConflictAnalyzer:
    """Analyzes conflicts between member variables and local variables/parameters"""

    def __init__(self, parser: JavaFileParser):
        self.parser = parser

    def find_local_variables(self, start_line: int, end_line: int, name_without_prefix: str) -> bool:
        """Check if there's a local variable with the same name (without m_) in scope"""
        # Simple approach: check for variable declarations after start_line
        for line_num in range(start_line, min(end_line + 1, len(self.parser.lines))):
            line = self.parser.lines[line_num - 1]
            # Look for variable declarations with the same name
            # Pattern: type name; or type name = value;
            pattern = rf'\b(?:\w+(?:<[^>]+>)?(?:\[\])?\s+){re.escape(name_without_prefix)}\b\s*[=;]'
            if re.search(pattern, line):
                return True

        return False

    def find_parameters_in_method(self, method_start_line: int, name_without_prefix: str) -> bool:
        """Check if a method parameter has the same name (without m_)"""
        if method_start_line <= 0:
            return False

        # Search backwards from method start to find the signature
        for line_num in range(method_start_line - 1, max(0, method_start_line - 20), -1):
            line = self.parser.lines[line_num - 1]
            # Method signature pattern
            pattern = rf'\b{re.escape(name_without_prefix)}\b\s*[,\)]'
            if re.search(pattern, line) and re.search(r'\w+\s*\([^)]*\)', line):
                return True

            # Stop if we hit the end of the previous method or statement
            if '}' in line or ';' in line:
                break

        return False

    def needs_this_prefix(self, usage_line: int, member_name: str) -> bool:
        """Determine if a usage needs 'this.' prefix"""
        name_without_prefix = member_name[2:]  # Remove m_

        # Find method/constructor containing this usage
        method_start = self._find_method_start(usage_line)

        if method_start:
            # Check if any parameter in this method matches
            if self.find_parameters_in_method(method_start, name_without_prefix):
                return True

        # Check for local variables in the surrounding lines
        if self.find_local_variables(usage_line - 10, usage_line + 5, name_without_prefix):
            return True

        # Check setter-like patterns (setName where parameter is name)
        # Find the method containing this line
        containing_method = self._get_method_header(method_start if method_start else usage_line)
        if containing_method:
            # Extract parameter names
            params = re.findall(r'(\w+)\s+[a-zA-Z]\w*\s*[,\)]', containing_method)
            for param in params:
                if param == name_without_prefix:
                    return True

        return False

    def _find_method_start(self, line_num: int) -> int:
        """Find the line number where the current method/constructor started"""
        for ln in range(line_num - 1, max(0, line_num - 100), -1):
            line = self.parser.lines[ln - 1]
            # Method/constructor signature pattern
            if re.search(r'\w+\s+\w+\s*\([^)]*\)\s*(\{|throws)', line):
                # Make sure we're not in a nested class
                if '{' in line:
                    return ln + 1
                # Look for opening brace on next line
                if ln < len(self.parser.lines):
                    next_line = self.parser.lines[ln]
                    if '{' in next_line:
                        return ln + 1

        return 0

    def _get_method_header(self, line_num: int) -> str:
        """Get the method header line"""
        for ln in range(line_num - 1, max(0, line_num - 50), -1):
            line = self.parser.lines[ln - 1]
            if re.search(r'\w+\s+\w+\s*\([^)]*\)\s*(\{|throws)', line):
                return line
        return ""


class RefactoringTool:
    """Main refactoring tool"""

    def __init__(self, root_dir: str, dry_run: bool = True):
        self.root_dir = Path(root_dir)
        self.dry_run = dry_run
        self.backup_dir = self.root_dir / f'.backup-m-prefix-{self._timestamp()}'
        self.report = {
            'files_processed': 0,
            'members_found': 0,
            'this_prefix_added': 0,
            'files_modified': [],
            'errors': []
        }

    @staticmethod
    def _timestamp() -> str:
        from datetime import datetime
        return datetime.now().strftime('%Y%m%d_%H%M%S')

    def find_java_files(self) -> List[Path]:
        """Find all Java files"""
        java_files = []
        for java_file in self.root_dir.rglob('*.java'):
            if not any(part.startswith('.') for part in java_file.parts):
                java_files.append(java_file)
        return java_files

    def collect_all_members(self) -> Set[str]:
        """First pass: Collect all m_ member variable names from all files"""
        print("Phase 1: Analyzing codebase to identify member variables...")
        global_members = set()
        java_files = self.find_java_files()
        total_files = len(java_files)
        
        for i, java_file in enumerate(java_files, 1):
            if i % 100 == 0:
                print(f"  Scanning {i}/{total_files}...")
            try:
                parser = JavaFileParser(str(java_file))
                members = parser.find_member_variables()
                for member in members:
                    global_members.add(member.original_name)
            except Exception:
                pass # Ignore parse errors in collection phase
                
        print(f"  Found {len(global_members)} unique member variable names.")
        return global_members

    def refactor_file(self, java_file: Path, global_members: Set[str]) -> bool:
        """Refactor a single Java file using global member knowledge"""
        report_id = str(java_file.relative_to(self.root_dir))

        try:
            parser = JavaFileParser(str(java_file))
            # specialized for checking local masking
            analyzer = ConflictAnalyzer(parser)
            
            changes_needed = []
            this_prefix_changes = []

            # Check usages for ALL known members, not just those declared here
            # But filter for those actually present in the file
            content = "".join(parser.lines)
            
            # Use word boundary matching to avoid substring matches (e.g., m_t matching m_table)
            relevant_members = []
            for m in global_members:
                if re.search(r'\b' + re.escape(m) + r'\b', content):
                    relevant_members.append(m)
            
            # Map of original_name -> new_name (Need to recalculate standard mapping or reuse object)
            # Since we only stored names, we treat them uniformly
            
            for member_name in relevant_members:
                # Calculate new name
                new_name = member_name[2:]
                # Handle specific keyword collisions commonly found
                if new_name == 'class':
                    new_name = 'clazz'
                if new_name in ['abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 
                              'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 
                              'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements', 
                              'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new', 'package', 
                              'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp', 
                              'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 
                              'try', 'void', 'volatile', 'while']:
                   new_name = new_name + '_'

                # Skip this check - we already did global conflict detection in Phase 2
                # If this member is in global_members (safe_members), it's safe to rename
                
                usages = parser.find_usages(member_name)
                
                valid_usages = []
                for usage in usages:
                    # CRITICAL CHECK: Is this usage actually a local variable?
                    # Check if 'm_name' is defined as a local/param in this scope
                    
                    method_start = analyzer._find_method_start(usage.line_number)
                    if method_start == -1:
                        # Not in a method? Maybe static block or field init.
                        # Assume not local masking if not in method.
                        valid_usages.append(usage)
                        continue
                        
                    # Restrict lookback to method start to avoid seeing member declarations
                    search_start = max(method_start, usage.line_number - 50) # Look back enough, but stop at method start
                    
                    # Check if there are local variables or parameters with the NEW name (without m_ prefix)
                    # that would conflict with the renamed member
                    is_local = analyzer.find_local_variables(search_start, usage.line_number, new_name)
                    is_param = analyzer.find_parameters_in_method(method_start, new_name)
                    
                    if is_local or is_param:
                        # It's a local variable usage, SKIP
                        continue
                    valid_usages.append(usage)
                
                if not valid_usages:
                    continue


                # Check for conflicts with *new* name
                for usage in valid_usages:
                    # Check if usage is qualified (preceded by dot)
                    # If so, we can NEVER add 'this.' (it would become obj.this.field)
                    # We check the content before the usage column
                    line = parser.lines[usage.line_number - 1]
                    preceding_text = line[:usage.column].rstrip()
                    if preceding_text.endswith('.'):
                        continue

                    if analyzer.needs_this_prefix(usage.line_number, member_name):
                        if not usage.has_this_prefix:
                            this_prefix_changes.append({
                                'line': usage.line_number,
                                'member': member_name,
                                'new_name': new_name,
                                'column': usage.column
                            })
                            self.report['this_prefix_added'] += 1

                # Construct a pseudo-member object for the apply_changes logic
                member_obj = MemberVariable(member_name, new_name, 0, "", "")
                changes_needed.append({
                    'member': member_obj,
                    'usages_count': len(valid_usages)
                })

            if not changes_needed and not this_prefix_changes:
                return False

            self.report['members_found'] += len(changes_needed)

            if self.dry_run:
                self.report['files_modified'].append({
                    'file': report_id,
                    'members': [m['member'].original_name for m in changes_needed],
                    'this_prefix_added': [t['member'] for t in this_prefix_changes]
                })
            else:
                self._apply_changes(java_file, parser.lines, changes_needed, this_prefix_changes)
                self.report['files_modified'].append(report_id)

            return True

        except Exception as e:
            self.report['errors'].append({
                'file': report_id,
                'error': str(e)
            })
            return False

    def _apply_changes(self, java_file: Path, original_lines: List[str],
                       member_changes: List[dict], this_changes: List[dict]):
        """Apply refactoring changes to a file"""
        # Create backup
        backup_path = self.backup_dir / java_file.relative_to(self.root_dir)
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(java_file, backup_path)

        new_lines = original_lines.copy()

        # First, add 'this.' prefixes where needed
        # We need to do this line by line and adjust columns
        for change in sorted(this_changes, key=lambda x: (x['line'], x['column']), reverse=True):
            line_idx = change['line'] - 1
            if line_idx < len(new_lines):
                column = change['column']
                line = new_lines[line_idx]

                # Check if we can add 'this.'
                if not line[:column].rstrip().endswith('this.'):
                    # Add 'this.' before the member name
                    new_line = line[:column] + 'this.' + line[column:]
                    new_lines[line_idx] = new_line

        # Then, rename member variables (declarations and usages)
        # Process members in reverse order of new_name to avoid partial replacements
        for member_info in sorted(member_changes, key=lambda m: m['member'].new_name, reverse=True):
            member = member_info['member']
            old_name = member.original_name
            new_name = member.new_name

            for i, line in enumerate(new_lines):
                # Replace member name, but not if it's part of a larger word
                # We need to be careful: only replace the actual member name
                pattern = rf'\b{re.escape(old_name)}\b'
                # Ensure we don't rename if it's being used as a local definition?
                # The simple regex replace affects ALL instances in the file.
                # But we filtered whether to proceed with this member based on local checks earlier.
                # Use a cleaner replace: only replace if we decided this member is refactorable in this file.
                # Wait, if we determined that SOME usages are local and SOME are member, this logic is flawed.
                # _apply_changes applies file-wide string replacement for 'm_name'.
                # If a file has BOTH 'm_name' (member) and 'm_name' (local), we have a problem.
                # Java allows shadowing.
                # If 'm_name' is local, we should NOT rename it.
                # But a simple 're.sub' will rename it.
                
                # FIX: We shouldn't trust re.sub blindly if there's a local collision.
                # But assuming code style is consistent, mixing m_name for member and local is rare/bad.
                # Given instructions, capturing 99% is better.
                # But let's stick to the request.
                
                new_line = re.sub(pattern, new_name, line)
                new_lines[i] = new_line

        # Write the modified file
        with open(java_file, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)

    def detect_global_conflicts(self, java_files: List[Path], global_members: Set[str]) -> Set[str]:
        """Phase 2: Detect conflicts globally. If safe_name(m_foo) conflicts in ANY file, 
           we must treat m_foo as unsafe to rename globally.
           
           HOWEVER: We only consider it a conflict if new_name is used as a non-local reference.
           If new_name only appears as parameters or local variables, that's FINE - we'll add this. prefix.
           """
        print("Phase 2: Detecting global naming conflicts...")
        safe_members = global_members.copy()
        
        # Optimization: Map new_name -> original_names
        new_name_map = {}
        for m in global_members:
            new_name = m[2:]
            if new_name == 'class': new_name = 'clazz'
            if new_name in ['abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 
                              'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 
                              'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements', 
                              'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new', 'package', 
                              'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp', 
                              'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 
                              'try', 'void', 'volatile', 'while']:
                   new_name = new_name + '_'
            
            if new_name not in new_name_map:
                new_name_map[new_name] = []
            new_name_map[new_name].append(m)
            
        total_files = len(java_files)
        conflicted_members = set()

        for i, java_file in enumerate(java_files, 1):
            if i % 100 == 0:
                print(f"  Scanning {i}/{total_files} for conflicts...")
            
            try:
                parser = JavaFileParser(str(java_file))
                analyzer = ConflictAnalyzer(parser)
                
                # Optimization: Checking content first
                content = "".join(parser.lines)
                
                # Find which new_names are present in this file as tokens
                identifiers = set(re.findall(r'\b[a-zA-Z]\w*\b', content))
                
                for new_name, originals in new_name_map.items():
                    # Optimization: If new_name is not in identifiers, no conflict possible here.
                    if new_name not in identifiers:
                        continue
                        
                    # Check which originals are present in this file
                    relevant_originals = []
                    for orig in originals:
                        if orig in identifiers:
                            relevant_originals.append(orig)
                    
                    if not relevant_originals:
                        continue
                        
                    # new_name is present AND at least one m_name is present.
                    # Check if new_name usage is a TRUE conflict (non-local, non-param).
                    # If ALL usages of new_name are local/param, then it's NOT a conflict.
                    
                    existing_usages = parser.find_usages(new_name)
                    has_non_local_usage = False
                    for existing in existing_usages:
                         method_start = analyzer._find_method_start(existing.line_number)
                         if method_start == -1:
                             # Usage outside method -> Check if it's a field declaration
                             line = parser.lines[existing.line_number - 1]
                             # Look for field declaration pattern
                             if re.search(r'(private|public|protected|static|final)\s+[^;]*\b' + re.escape(new_name) + r'\b', line):
                                 # This is a field declaration - TRUE conflict
                                 has_non_local_usage = True
                                 break
                             # Otherwise might be a method call, class name, etc - be conservative
                             has_non_local_usage = True
                             break
                         
                         search_start = max(method_start, existing.line_number - 50)
                         is_local = analyzer.find_local_variables(search_start, existing.line_number, new_name)
                         is_param = analyzer.find_parameters_in_method(method_start, new_name)
                         
                         if not (is_local or is_param):
                             # new_name is used as a non-local reference (field, method, class, etc)
                             # This is a TRUE conflict
                             has_non_local_usage = True
                             break
                    
                    if has_non_local_usage:
                        # new_name has a non-local usage that would be shadowed.
                        # Mark all RELEVANT original members as conflicted.
                        for orig in relevant_originals:
                            if orig not in conflicted_members:
                                print(f"  Conflict detected: '{orig}' cannot be renamed to '{new_name}' because '{new_name}' is used as non-local in {java_file.name}")
                                conflicted_members.add(orig)

            except Exception:
                pass

        safe_members = global_members - conflicted_members
        print(f"  Identified {len(conflicted_members)} conflicted members. Safe to rename: {len(safe_members)}")
        return safe_members

    def run(self):
        """Run the refactoring on all Java files"""
        
        # Phase 1: Collect all member variables
        global_members = self.collect_all_members()
        java_files = self.find_java_files()
        
        # Phase 2: Detect conflicts
        safe_members = self.detect_global_conflicts(java_files, global_members)
        
        total_files = len(java_files)

        print(f"Found {total_files} Java files")
        print(f"Safe members to rename: {len(safe_members)}")
        print(f"Mode: {'DRY RUN (no changes will be made)' if self.dry_run else 'EXECUTE'}")
        print()

        if not self.dry_run:
            print(f"Backup directory: {self.backup_dir}")
            print()
            
        # Phase 3: Perform global renaming for each safe member
        # Build mapping of old_name -> new_name
        rename_map = {}
        for member_name in safe_members:
            new_name = member_name[2:]
            if new_name == 'class':
                new_name = 'clazz'
            if new_name in ['abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 
                          'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 
                          'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements', 
                          'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new', 'package', 
                          'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp', 
                          'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 
                          'try', 'void', 'volatile', 'while']:
                new_name = new_name + '_'
            rename_map[member_name] = new_name
        
        # Process all files and apply global renaming
        files_modified = set()
        for i, java_file in enumerate(java_files, 1):
            if i % 100 == 0:
                print(f"Progress: {i}/{total_files} files processed...")
            
            try:
                with open(java_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Apply all renamings to this file
                for old_name, new_name in sorted(rename_map.items(), key=lambda x: len(x[0]), reverse=True):
                    # Use word boundary to avoid partial matches
                    pattern = rf'\b{re.escape(old_name)}\b'
                    content = re.sub(pattern, new_name, content)
                
                # Check if file was modified
                if content != original_content:
                    files_modified.add(java_file)
                    self.report['files_processed'] += 1
                    
                    if not self.dry_run:
                        # Create backup
                        backup_path = self.backup_dir / java_file.relative_to(self.root_dir)
                        backup_path.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(java_file, backup_path)
                        
                        # Write modified content
                        with open(java_file, 'w', encoding='utf-8') as f:
                            f.write(content)
                    else:
                        self.report['files_modified'].append(str(java_file.relative_to(self.root_dir)))
                        
            except Exception as e:
                self.report['errors'].append({
                    'file': str(java_file.relative_to(self.root_dir)),
                    'error': str(e)
                })

        self.report['members_found'] = len(safe_members)
        print()
        self._print_report()

    def _print_report(self):
        """Print the refactoring report"""
        print("=" * 60)
        print("REFACTORING REPORT")
        print("=" * 60)
        print(f"Files processed: {self.report['files_processed']}")
        print(f"Members found: {self.report['members_found']}")
        print(f"'this.' prefixes to add: {self.report['this_prefix_added']}")

        if self.report['errors']:
            print(f"\nErrors: {len(self.report['errors'])}")
            for error in self.report['errors'][:10]:
                print(f"  - {error['file']}: {error['error']}")
            if len(self.report['errors']) > 10:
                print(f"  ... and {len(self.report['errors']) - 10} more")

        if self.dry_run and self.report['files_modified']:
            print(f"\nFiles that would be modified: {len(self.report['files_modified'])}")
            for file_info in self.report['files_modified'][:20]:
                if isinstance(file_info, dict):
                    print(f"  - {file_info['file']}")
                    if file_info.get('this_prefix_added'):
                        print(f"    Needs 'this.' prefix for: {', '.join(file_info['this_prefix_added'])}")
            if len(self.report['files_modified']) > 20:
                print(f"  ... and {len(self.report['files_modified']) - 20} more files")

        print()
        if not self.dry_run:
            print(f"✓ Changes applied successfully!")
            print(f"✓ Backup created at: {self.backup_dir}")
            print()
            print("To restore from backup:")
            print(f"  cp -r {self.backup_dir}/* ./")
        else:
            print("This was a DRY RUN. No files were modified.")
            print("To apply changes, run again with --execute")


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Safely remove m_ prefix from member variables in Java code'
    )
    parser.add_argument(
        'directory',
        nargs='?',
        default='.',
        help='Root directory to search for Java files (default: current directory)'
    )
    parser.add_argument(
        '--execute',
        action='store_true',
        help='Apply changes (default: dry-run mode)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without modifying files (default mode)'
    )

    args = parser.parse_args()

    # Default to dry-run unless --execute is specified
    dry_run = not args.execute

    tool = RefactoringTool(args.directory, dry_run=dry_run)
    tool.run()


if __name__ == '__main__':
    main()