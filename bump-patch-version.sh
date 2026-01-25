#!/bin/bash
# Bump patch/incremental version for all Hitorro modules
# Usage: ./bump-patch-version.sh

set -e

echo "Bumping patch version..."
mvn versions:set -DnextSnapshot=false -DprocessAllModules=true

echo "Getting new version..."
NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

echo "Version updated to: $NEW_VERSION"
echo ""
echo "To deploy to local repository, run:"
echo "  mvn clean deploy"
