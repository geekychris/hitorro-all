#!/bin/bash
# Set a specific version for all Hitorro modules
# Usage: ./set-version.sh <version>

set -e

if [ -z "$1" ]; then
    echo "Error: Version number required"
    echo "Usage: $0 <version>"
    echo "Example: $0 3.1.0"
    exit 1
fi

VERSION=$1

echo "Setting version to $VERSION..."
mvn versions:set -DnewVersion=$VERSION -DprocessAllModules=true

echo "Version updated to: $VERSION"
echo ""
echo "To deploy to local repository, run:"
echo "  mvn clean deploy"
