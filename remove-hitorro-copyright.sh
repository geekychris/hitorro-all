#!/bin/bash

# Script to remove HiTorro copyright lines from all Java files
# This removes lines containing "HiTorro All rights reserved" while keeping
# the main copyright notice (Copyright (c) 2006-2025 Chris Collins) intact

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BACKUP_DIR="./.backup-java-files-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Count total files to process
TOTAL_FILES=$(find . -name "*.java" -type f -exec grep -l "HiTorro All rights reserved" {} \; | wc -l | tr -d ' ')

echo "Starting removal of HiTorro copyright lines from Java files..."
echo "Backup directory: $BACKUP_DIR"
echo "Total files to process: $TOTAL_FILES"
echo ""

FILES_MODIFIED=0

# Create temp file list
TMPFILE=$(mktemp)
find . -name "*.java" -type f > "$TMPFILE"

# Process each file
while IFS= read -r file; do
    if [ -f "$file" ] && grep -q "HiTorro All rights reserved" "$file"; then
        # Create backup
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$file" "$BACKUP_DIR/$file"

        # Remove lines containing "HiTorro All rights reserved"
        sed -i.bak '/HiTorro All rights reserved/d' "$file"
        rm "${file}.bak"

        FILES_MODIFIED=$((FILES_MODIFIED + 1))

        if [ $((FILES_MODIFIED % 50)) -eq 0 ]; then
            REMAINING=$((TOTAL_FILES - FILES_MODIFIED))
            echo "Progress: $FILES_MODIFIED/$TOTAL_FILES files processed ($REMAINING remaining)..."
        fi
    fi
done < "$TMPFILE"

rm "$TMPFILE"

# Verify all files have been processed (exclude backup directories)
REMAINING=$(find . -name "*.java" -type f -not -path "./.backup-java-files*/*" | xargs grep -l "HiTorro All rights reserved" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "========================================="
echo "Done!"
echo "Files modified: $FILES_MODIFIED"
echo "Files remaining with HiTorro copyright: $REMAINING"
echo "Backup created at: $BACKUP_DIR"
echo "========================================="
echo ""
echo "To restore from backup if needed:"
echo "  cp -r $BACKUP_DIR/* ./"
echo ""
echo "To verify changes, you can run:"
echo "  diff -r hitorro-text-persistence $BACKUP_DIR/hitorro-text-persistence | head -50"