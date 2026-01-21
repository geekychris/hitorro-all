#!/bin/bash

echo "Starting Hitorro Spring Boot Application..."
echo "=============================================="
echo ""

cd /Users/chris/hitorro/hitorro-example-springboot

# Kill any existing process on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Start the application
echo "Running: mvn spring-boot:run"
echo ""
mvn spring-boot:run
