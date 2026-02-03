#!/usr/bin/env python3
"""
Normalization Tool: Add m_ prefix to member variables that don't have it

This script adds m_ prefix to private/protected member variables that are missing it,
to normalize the codebase before removing all m_ prefixes.

Usage:
    python3 add_m_prefix.py --dry-run        # Preview changes
    python3 add_m_prefix.py --execute        # Apply changes
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Set
import shutil
from datetime import datetime


class MemberNormalizer:
    """Normalizes member variable naming by adding m_ prefix where missing"""

    def __init__(self, root_dir: str, dry_run: bool = True):
        self.root_dir = Path(root_dir)
        self.dry_run = dry_run
        self.backup_dir = self.root_dir / f'.backup-add-m-prefix-{self._timestamp()}'
        self.report = {
            'files_processed': 0,
            'members_normalized': 0,
            'files_modified': [],
            'errors': []
        }

    @staticmethod
    def _timestamp() -> str:
        return datetime.now().strftime('%Y%m%d_%H%M%S')

    def find_java_files(self) -> List[Path]:
        """Find all Java files"""
        java_files = []
        for java_file in self.root_dir.rglob('*.java'):
            if not any(part.startswith('.') for part in java_file.parts):
                java_files.append(java_file)
        return java_files

    def normalize_file(self, java_file: Path) -> bool:
        """Add m_ prefix to member variables missing it"""
        try:
            with open(java_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            new_lines = lines.copy()
            modified = False
            in_class = False
            brace_depth = 0

            for i, line in enumerate(lines):
                # Track brace depth and class context
                brace_depth += line.count('{') - line.count('}')

                # Detect class/interface declaration
                if re.search(r'\b(class|interface|enum|record)\s+\w+', line):
                    in_class = True

                # End of class
                if brace_depth == 0:
                    in_class = False

                # Only look for member declarations at class level (brace_depth == 1)
                if in_class and brace_depth == 1:
                    # Match private/protected field declarations without m_ prefix
                    # Pattern: (private|protected) Type fieldName
                    match = re.search(
                        r'^(\s*)(private|protected)(\s+(?:static\s+)?(?:final\s+)?)([\w<>\[\]]+)\s+([a-z][a-zA-Z0-9_]*)\s*[=;]',
                        line
                    )
                    
                    if match:
                        indent = match.group(1)
                        visibility = match.group(2)
                        modifiers = match.group(3)
                        type_name = match.group(4)
                        field_name = match.group(5)
                        
                        # Skip if already has m_ prefix
                        if field_name.startswith('m_'):
                            continue
                        
                        # Skip common non-member patterns
                        if field_name in ['serialVersionUID', 'logger', 'log', 'LOGGER', 'LOG']:
                            continue
                        
                        # Add m_ prefix
                        new_field_name = f'm_{field_name}'
                        
                        # Replace in this line
                        new_line = line.replace(f' {field_name} ', f' {new_field_name} ', 1)
                        new_line = new_line.replace(f' {field_name}=', f' {new_field_name}=', 1)
                        new_line = new_line.replace(f' {field_name};', f' {new_field_name};', 1)
                        
                        if new_line != line:
                            new_lines[i] = new_line
                            modified = True
                            
                            # Now replace all usages in the file
                            pattern = rf'\b{re.escape(field_name)}\b'
                            for j in range(len(new_lines)):
                                if j != i:  # Don't re-process the declaration line
                                    # Only replace if not already prefixed and not in comments
                                    if not re.search(r'^\s*//', new_lines[j]):  # Skip comment lines
                                        new_lines[j] = re.sub(pattern, new_field_name, new_lines[j])

            if modified:
                self.report['files_processed'] += 1
                self.report['members_normalized'] += 1
                
                if not self.dry_run:
                    # Create backup
                    backup_path = self.backup_dir / java_file.relative_to(self.root_dir)
                    backup_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(java_file, backup_path)
                    
                    # Write modified file
                    with open(java_file, 'w', encoding='utf-8') as f:
                        f.writelines(new_lines)
                else:
                    self.report['files_modified'].append(str(java_file.relative_to(self.root_dir)))

            return modified

        except Exception as e:
            self.report['errors'].append({
                'file': str(java_file.relative_to(self.root_dir)),
                'error': str(e)
            })
            return False

    def run(self):
        """Run normalization on all Java files"""
        java_files = self.find_java_files()
        total_files = len(java_files)

        print(f"Found {total_files} Java files")
        print(f"Mode: {'DRY RUN (no changes will be made)' if self.dry_run else 'EXECUTE'}")
        print()

        if not self.dry_run:
            print(f"Backup directory: {self.backup_dir}")
            print()

        for i, java_file in enumerate(java_files, 1):
            if i % 100 == 0:
                print(f"Progress: {i}/{total_files} files processed...")

            self.normalize_file(java_file)

        print()
        self._print_report()

    def _print_report(self):
        """Print the normalization report"""
        print("=" * 60)
        print("NORMALIZATION REPORT")
        print("=" * 60)
        print(f"Files modified: {self.report['files_processed']}")
        print(f"Members normalized: {self.report['members_normalized']}")

        if self.report['errors']:
            print(f"\nErrors: {len(self.report['errors'])}")
            for error in self.report['errors'][:10]:
                print(f"  - {error['file']}: {error['error']}")

        if self.dry_run and self.report['files_modified']:
            print(f"\nFiles that would be modified: {len(self.report['files_modified'])}")
            for file_path in self.report['files_modified'][:20]:
                print(f"  - {file_path}")
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
        description='Add m_ prefix to member variables that are missing it'
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

    normalizer = MemberNormalizer(args.directory, dry_run=dry_run)
    normalizer.run()


if __name__ == '__main__':
    main()
