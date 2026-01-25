#!/bin/bash
# Bump minor version for all Hitorro modules
# Usage: ./bump-minor-version.sh

set -e

echo "Bumping minor version..."
mvn versions:set -DnextMinorVersion=true -DprocessAllModules=true

echo "Getting new version..."
NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

echo "Version updated to: $NEW_VERSION"
echo ""
echo "To deploy to local repository, run:"
echo "  mvn clean deploy"
