#!/usr/bin/env python3
"""
Fix Self-Assignment Bug

This script fixes statements like `name = name;` to `this.name = name;`
These are bugs introduced when m_ prefix was removed where parameters shadow members.

Usage:
    python3 fix_self_assignments.py --dry-run        # Preview changes
    python3 fix_self_assignments.py --execute        # Apply changes
"""

import re
import shutil
from pathlib import Path
from datetime import datetime
import argparse


def find_self_assignments(content):
    """Find all self-assignment patterns in content"""
    pattern = re.compile(r'^\s*([a-zA-Z_]\w*)\s*=\s*\1\s*;', re.MULTILINE)
    matches = []
    
    for match in pattern.finditer(content):
        matches.append({
            'start': match.start(),
            'end': match.end(),
            'var_name': match.group(1),
            'full_match': match.group(0)
        })
    
    return matches


def fix_self_assignments(content):
    """Fix self-assignments by adding this. prefix"""
    pattern = re.compile(r'^(\s*)([a-zA-Z_]\w*)\s*=\s*\2\s*;', re.MULTILINE)
    
    def replacement(match):
        indent = match.group(1)
        var_name = match.group(2)
        return f'{indent}this.{var_name} = {var_name};'
    
    return pattern.sub(replacement, content)


def process_file(file_path, dry_run=True):
    """Process a single file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
    
    # Find issues
    issues = find_self_assignments(original_content)
    
    if not issues:
        return None
    
    if dry_run:
        return {
            'file': file_path,
            'issues': issues
        }
    else:
        # Fix the content
        fixed_content = fix_self_assignments(original_content)
        
        # Write fixed content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        return {
            'file': file_path,
            'issues': issues
        }


def main():
    parser = argparse.ArgumentParser(
        description='Fix self-assignment bugs (var = var; -> this.var = var;)'
    )
    parser.add_argument(
        '--execute',
        action='store_true',
        help='Apply changes (default: dry-run mode)'
    )
    parser.add_argument(
        '--module',
        default='hitorro-util',
        help='Module to process (default: hitorro-util)'
    )
    
    args = parser.parse_args()
    dry_run = not args.execute
    
    module_path = Path(args.module)
    if not module_path.exists():
        print(f"Error: Module directory '{args.module}' not found")
        return 1
    
    # Create backup if executing
    backup_dir = None
    if not dry_run:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_dir = Path(f'.backup-self-assign-{timestamp}')
        backup_dir.mkdir(exist_ok=True)
        print(f"Backup directory: {backup_dir}")
        print()
    
    # Find all Java files
    java_files = list(module_path.rglob('*.java'))
    # Exclude backup directories
    java_files = [f for f in java_files if '.backup-' not in str(f)]
    
    print(f"Scanning {len(java_files)} Java files in {args.module}...")
    print(f"Mode: {'EXECUTE' if not dry_run else 'DRY RUN'}")
    print()
    
    results = []
    files_with_issues = 0
    total_issues = 0
    
    for java_file in java_files:
        # Create backup BEFORE processing if executing
        if not dry_run:
            with open(java_file, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            # Check if file has issues first
            issues = find_self_assignments(original_content)
            if issues:
                # Create backup of original
                rel_path = java_file.relative_to(module_path)
                backup_file = backup_dir / args.module / rel_path
                backup_file.parent.mkdir(parents=True, exist_ok=True)
                with open(backup_file, 'w', encoding='utf-8') as f:
                    f.write(original_content)
        
        result = process_file(java_file, dry_run)
        if result:
            results.append(result)
            files_with_issues += 1
            total_issues += len(result['issues'])
    
    # Print summary
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Files with self-assignments: {files_with_issues}")
    print(f"Total self-assignments: {total_issues}")
    print()
    
    if dry_run and results:
        print("Sample issues found:")
        for result in results[:10]:
            rel_path = result['file'].relative_to(module_path) if module_path in result['file'].parents else result['file']
            print(f"\n{rel_path}:")
            for issue in result['issues'][:3]:
                print(f"  {issue['full_match'].strip()}")
            if len(result['issues']) > 3:
                print(f"  ... and {len(result['issues']) - 3} more")
        
        if len(results) > 10:
            print(f"\n... and {len(results) - 10} more files")
        
        print()
        print("To apply fixes, run with --execute")
    elif not dry_run:
        print(f"✓ Fixed {total_issues} self-assignments in {files_with_issues} files")
        print(f"✓ Backup created at: {backup_dir}")
        print()
        print("To restore from backup:")
        print(f"  cp -r {backup_dir}/{args.module}/* {args.module}/")
    
    return 0


if __name__ == '__main__':
    exit(main())
