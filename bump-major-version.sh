#!/bin/bash
# Bump major version for all Hitorro modules
# Usage: ./bump-major-version.sh

set -e

echo "Bumping major version..."
mvn versions:set -DnextMajorVersion=true -DprocessAllModules=true

echo "Getting new version..."
NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

echo "Version updated to: $NEW_VERSION"
echo ""
echo "To deploy to local repository, run:"
echo "  mvn clean deploy"
