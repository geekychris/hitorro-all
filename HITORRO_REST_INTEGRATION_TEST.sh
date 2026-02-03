#!/bin/bash

# Hitorro REST Integration Test Script
# This script tests the REST endpoints against a running Hitorro instance

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8080/api/rest"
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to print test results
print_test() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

echo "============================================"
echo "Hitorro REST Integration Tests"
echo "============================================"
echo ""
echo "Testing against: $BASE_URL"
echo ""

# Test 1: Discovery Endpoint
echo "Test 1: Discovery endpoint lists REST commands"
RESPONSE=$(curl -s "$BASE_URL")
if echo "$RESPONSE" | grep -q "totalEndpoints"; then
    ENDPOINT_COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['totalEndpoints'])")
    print_test "Discovery endpoint returns JSON with totalEndpoints=$ENDPOINT_COUNT" "PASS"
else
    print_test "Discovery endpoint returns JSON with totalEndpoints" "FAIL"
fi

# Test 2: Simple GET command
echo ""
echo "Test 2: Execute simple GET command (demo.echo)"
RESPONSE=$(curl -s "$BASE_URL/demo.echo?message=HelloWorld")
if echo "$RESPONSE" | grep -q "HelloWorld"; then
    print_test "demo.echo returns 'HelloWorld'" "PASS"
else
    print_test "demo.echo returns 'HelloWorld'" "FAIL"
fi

# Test 3: Command with multiple parameters
echo ""
echo "Test 3: Command with multiple parameters (demo.add)"
RESPONSE=$(curl -s "$BASE_URL/demo.add?a=15&b=27")
if echo "$RESPONSE" | grep -q "42"; then
    print_test "demo.add(15, 27) returns 42" "PASS"
else
    print_test "demo.add(15, 27) returns 42" "FAIL"
fi

# Test 4: Command with dots in name
echo ""
echo "Test 4: Command with dots in name (env.hostip)"
RESPONSE=$(curl -s "$BASE_URL/env.hostip")
if echo "$RESPONSE" | grep -q "success.*true"; then
    IP=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 'N/A'))" 2>/dev/null || echo "N/A")
    print_test "env.hostip returns IP: $IP" "PASS"
else
    print_test "env.hostip returns success" "FAIL"
fi

# Test 5: Non-existent command returns 404
echo ""
echo "Test 5: Non-existent command returns 404"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/nonexistent.command")
if [ "$HTTP_CODE" = "404" ]; then
    print_test "Non-existent command returns HTTP 404" "PASS"
else
    print_test "Non-existent command returns HTTP 404 (got $HTTP_CODE)" "FAIL"
fi

# Test 6: Unsupported HTTP method returns 405
echo ""
echo "Test 6: Unsupported HTTP method returns 405"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/demo.echo")
if [ "$HTTP_CODE" = "405" ]; then
    print_test "DELETE on GET-only command returns HTTP 405" "PASS"
else
    print_test "DELETE on GET-only command returns HTTP 405 (got $HTTP_CODE)" "FAIL"
fi

# Test 7: Response structure validation
echo ""
echo "Test 7: Response structure validation"
RESPONSE=$(curl -s "$BASE_URL/demo.echo?message=test")
HAS_SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys, json; print('success' in json.load(sys.stdin))" 2>/dev/null)
HAS_COMMAND=$(echo "$RESPONSE" | python3 -c "import sys, json; print('command' in json.load(sys.stdin))" 2>/dev/null)
HAS_RESULT=$(echo "$RESPONSE" | python3 -c "import sys, json; print('result' in json.load(sys.stdin))" 2>/dev/null)
HAS_TIME=$(echo "$RESPONSE" | python3 -c "import sys, json; print('executionTimeMs' in json.load(sys.stdin))" 2>/dev/null)

if [ "$HAS_SUCCESS" = "True" ] && [ "$HAS_COMMAND" = "True" ] && [ "$HAS_RESULT" = "True" ] && [ "$HAS_TIME" = "True" ]; then
    print_test "Response contains success, command, result, executionTimeMs" "PASS"
else
    print_test "Response contains all required fields" "FAIL"
fi

# Test 8: POST with JSON body
echo ""
echo "Test 8: POST with JSON body (demo.add)"
RESPONSE=$(curl -s -X POST "$BASE_URL/demo.add" \
    -H "Content-Type: application/json" \
    -d '{"a": 100, "b": 200}')
if echo "$RESPONSE" | grep -q "300"; then
    print_test "POST demo.add with JSON body returns 300" "PASS"
else
    print_test "POST demo.add with JSON body returns 300" "FAIL"
fi

# Test 9: Command with no parameters
echo ""
echo "Test 9: Command with no parameters (demo.sysinfo)"
RESPONSE=$(curl -s "$BASE_URL/demo.sysinfo")
if echo "$RESPONSE" | grep -q "success.*true"; then
    PROP_COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('result', [])))" 2>/dev/null || echo "0")
    print_test "demo.sysinfo returns $PROP_COUNT properties" "PASS"
else
    print_test "demo.sysinfo returns success" "FAIL"
fi

# Test 10: Execution time is present and reasonable
echo ""
echo "Test 10: Execution time measurement"
RESPONSE=$(curl -s "$BASE_URL/demo.echo?message=timing")
EXEC_TIME=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('executionTimeMs', -1))" 2>/dev/null || echo "-1")
if [ "$EXEC_TIME" != "-1" ] && [ "$EXEC_TIME" -ge "0" ] && [ "$EXEC_TIME" -lt "1000" ]; then
    print_test "Execution time ${EXEC_TIME}ms is reasonable" "PASS"
else
    print_test "Execution time ${EXEC_TIME}ms is reasonable" "FAIL"
fi

# Summary
echo ""
echo "============================================"
echo "Test Summary"
echo "============================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed ✗${NC}"
    exit 1
fi
