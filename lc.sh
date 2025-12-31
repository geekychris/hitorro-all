#!/bin/bash

# Loop through all immediate subdirectories
for dir in */; do
    if [ -d "$dir" ]; then
        # Use find to list all .java files in the subdirectory and its subfolders
        # Use xargs to pass the list of files to wc -l to count lines
        # The output of wc -l will be piped to awk to sum the lines
        line_count=$(find "$dir" -type f -name '*.java' -print0 | xargs -0 wc -l | awk '{total += $1} END {print total}')
        
        # Print the results for the directory
        echo "$dir: ${line_count:-0} lines"
    fi
done

# Calculate and print the total for all java files
total_lines=$(find . -type f -name '*.java' -print0 | xargs -0 wc -l | awk '{total += $1} END {print total}')
echo "Total Java lines: ${total_lines:-0}"
