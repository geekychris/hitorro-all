#!/bin/bash
# Build and deploy all Hitorro modules to local Maven repository
# Usage: ./build-and-deploy.sh [options]
#
# Options:
#   -s, --skip-tests    Skip running tests
#   -c, --clean         Run clean before build
#   -h, --help          Show this help message

set -e

SKIP_TESTS=""
CLEAN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-tests)
            SKIP_TESTS="-DskipTests"
            shift
            ;;
        -c|--clean)
            CLEAN="clean"
            shift
            ;;
        -h|--help)
            echo "Build and deploy all Hitorro modules to local Maven repository"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -s, --skip-tests    Skip running tests"
            echo "  -c, --clean         Run clean before build"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Build the command
MVN_CMD="mvn"
if [ -n "$CLEAN" ]; then
    MVN_CMD="$MVN_CMD $CLEAN"
fi
MVN_CMD="$MVN_CMD deploy"
if [ -n "$SKIP_TESTS" ]; then
    MVN_CMD="$MVN_CMD $SKIP_TESTS"
fi

echo "========================================="
echo "Building and deploying Hitorro modules"
echo "========================================="
echo "Command: $MVN_CMD"
echo ""

# Execute the Maven command
$MVN_CMD

echo ""
echo "========================================="
echo "Deployment complete!"
echo "========================================="
echo "Artifacts deployed to: /Users/chris/code/hitorro-maven"
echo ""
echo "To use these artifacts in another project, add this to your pom.xml:"
echo ""
echo "<repositories>"
echo "    <repository>"
echo "        <id>hitorro-local</id>"
echo "        <url>file:///Users/chris/code/hitorro-maven</url>"
echo "    </repository>"
echo "</repositories>"
