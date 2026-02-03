#!/usr/bin/env python3
"""
Simple Per-File Member Variable Refactoring Tool

This script removes m_ prefix from member variables using a per-file approach.
It only renames members declared in each file, avoiding cross-file conflicts.
"""

import re
import sys
from pathlib import Path
from typing import List, Set, Tuple
import shutil
from datetime import datetime


class SimpleRefactorer:
    def __init__(self, root_dir: str, dry_run: bool = True, module: str = None):
        self.root_dir = Path(root_dir)
        self.dry_run = dry_run
        self.module = module
        self.backup_dir = self.root_dir / f'.backup-simple-refactor-{self._timestamp()}'
        self.stats = {'files_modified': 0, 'members_renamed': 0}

    @staticmethod
    def _timestamp() -> str:
        return datetime.now().strftime('%Y%m%d_%H%M%S')

    def find_java_files(self) -> List[Path]:
        """Find all Java files, optionally filtered by module"""
        all_files = [f for f in self.root_dir.rglob('*.java') 
                     if not any(part.startswith('.') for part in f.parts)]
        
        if self.module:
            # Filter files to only those in the specified module directory
            all_files = [f for f in all_files if self.module in str(f)]
        
        return all_files

    def find_members_in_file(self, content: str) -> List[Tuple[str, str]]:
        """Find member declarations with m_ prefix in file content.
        Returns list of (original_name, new_name) tuples."""
        members = []
        lines = content.split('\n')
        
        for line in lines:
            # Match: (private|protected) Type m_name
            match = re.search(
                r'^\s*(private|protected)\s+(?:static\s+)?(?:final\s+)?([\w<>\[\]]+)\s+(m_\w+)\s*[=;]',
                line
            )
            if match:
                old_name = match.group(3)
                new_name = old_name[2:]  # Remove m_ prefix
                
                # Handle Java keywords
                if new_name in ['class', 'abstract', 'assert', 'boolean', 'break', 'byte', 
                               'case', 'catch', 'char', 'const', 'continue', 'default']:
                    new_name = new_name + '_'
                
                members.append((old_name, new_name))
        
        return members

    def refactor_file(self, java_file: Path) -> bool:
        """Refactor a single file, renaming only members declared in it."""
        try:
            with open(java_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find members declared in THIS file
            members = self.find_members_in_file(content)
            if not members:
                return False
            
            modified_content = content
            
            # Rename each member (process in reverse order of name length to avoid partial matches)
            for old_name, new_name in sorted(members, key=lambda x: len(x[0]), reverse=True):
                # Simple word-boundary replacement
                pattern = rf'\b{re.escape(old_name)}\b'
                modified_content = re.sub(pattern, new_name, modified_content)
                self.stats['members_renamed'] += 1
            
            if modified_content == content:
                return False
            
            self.stats['files_modified'] += 1
            
            if not self.dry_run:
                # Create backup
                backup_path = self.backup_dir / java_file.relative_to(self.root_dir)
                backup_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(java_file, backup_path)
                
                # Write modified file
                with open(java_file, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
            
            return True
            
        except Exception as e:
            print(f"Error processing {java_file}: {e}")
            return False

    def run(self):
        """Run refactoring on all Java files"""
        java_files = self.find_java_files()
        
        print(f"Found {len(java_files)} Java files")
        print(f"Mode: {'DRY RUN' if self.dry_run else 'EXECUTE'}")
        if not self.dry_run:
            print(f"Backup: {self.backup_dir}")
        print()
        
        for i, java_file in enumerate(java_files, 1):
            if i % 100 == 0:
                print(f"Progress: {i}/{len(java_files)}...")
            
            self.refactor_file(java_file)
        
        print()
        print("=" * 60)
        print("RESULTS")
        print("=" * 60)
        print(f"Files modified: {self.stats['files_modified']}")
        print(f"Members renamed: {self.stats['members_renamed']}")
        
        if not self.dry_run:
            print(f"\n✓ Changes applied!")
            print(f"✓ Backup: {self.backup_dir}")
            print(f"\nTo restore: cp -r {self.backup_dir}/* ./")
        else:
            print("\nThis was a DRY RUN. Use --execute to apply changes.")


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Remove m_ prefix from member variables')
    parser.add_argument('directory', nargs='?', default='.', help='Root directory')
    parser.add_argument('--execute', action='store_true', help='Apply changes')
    parser.add_argument('--module', help='Only process files in this module (e.g., hitorro-util)')
    args = parser.parse_args()
    
    refactorer = SimpleRefactorer(args.directory, dry_run=not args.execute, module=args.module)
    refactorer.run()


if __name__ == '__main__':
    main()
