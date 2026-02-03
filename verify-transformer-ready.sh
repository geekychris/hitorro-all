#!/bin/bash
# Verify transformer is ready to work

echo "========================================="
echo "Transformer Readiness Check"
echo "========================================="
echo ""

# Check 1: Tools installed
echo "1. Checking transformation tools..."
HAS_PDFTOPPM=$(which pdftoppm 2>/dev/null && echo "✓" || echo "✗")
HAS_SOFFICE=$(which soffice 2>/dev/null && echo "✓" || echo "✗")
HAS_CONVERT=$(which convert 2>/dev/null && echo "✓" || echo "✗")

echo "   pdftoppm:  $HAS_PDFTOPPM"
echo "   soffice:   $HAS_SOFFICE"
echo "   convert:   $HAS_CONVERT"
echo ""

# Check 2: Spring Boot autoconfiguration
echo "2. Checking Spring Boot configuration..."
if [ -f "/Users/chris/hitorro/hitorro-spring-boot/hitorro-spring-boot-autoconfigure/target/classes/META-INF/spring.factories" ]; then
    if grep -q "TransformerAutoConfiguration" /Users/chris/hitorro/hitorro-spring-boot/hitorro-spring-boot-autoconfigure/target/classes/META-INF/spring.factories; then
        echo "   spring.factories: ✓ (TransformerAutoConfiguration registered)"
    else
        echo "   spring.factories: ✗ (TransformerAutoConfiguration NOT found)"
    fi
else
    echo "   spring.factories: ✗ (file not found)"
fi
echo ""

# Check 3: Compiled classes
echo "3. Checking compiled classes..."
if [ -f "/Users/chris/hitorro/hitorro-spring-boot/hitorro-spring-boot-autoconfigure/target/classes/com/hitorro/spring/autoconfigure/transformer/TransformerAutoConfiguration.class" ]; then
    echo "   TransformerAutoConfiguration.class: ✓"
else
    echo "   TransformerAutoConfiguration.class: ✗"
fi

if [ -f "/Users/chris/hitorro/hitorro-spring-boot/hitorro-spring-boot-autoconfigure/target/classes/com/hitorro/spring/autoconfigure/transformer/RenditionTransformationController.class" ]; then
    echo "   RenditionTransformationController.class: ✓"
else
    echo "   RenditionTransformationController.class: ✗"
fi
echo ""

# Check 4: Backend status
echo "4. Checking backend..."
if curl -s "http://localhost:8080/actuator/health" > /dev/null 2>&1; then
    echo "   Backend: ✓ Running"
    
    # Check API
    echo ""
    echo "5. Checking Transformer API..."
    RESPONSE=$(curl -s "http://localhost:8080/api/transformer/transformations?sourceMimeType=application/pdf" 2>&1)
    
    if echo "$RESPONSE" | grep -q '"status":404'; then
        echo "   API Status: ✗ 404 Not Found"
        echo ""
        echo "   ⚠️  BACKEND NEEDS RESTART!"
        echo "   The TransformerAutoConfiguration is not loaded yet."
        echo ""
        echo "   In IntelliJ:"
        echo "   1. Click the red 'Stop' button"
        echo "   2. Click the green 'Run' button"
        echo ""
    elif echo "$RESPONSE" | grep -q '"transformations"'; then
        COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d: -f2)
        echo "   API Status: ✓ Working! ($COUNT transformations available)"
        echo ""
        echo "   🎉 READY TO USE!"
        echo "   Open http://localhost:3000 and try transforming a PDF!"
    else
        echo "   API Status: ? Unexpected response"
        echo "   Response: $RESPONSE"
    fi
else
    echo "   Backend: ✗ Not running"
    echo ""
    echo "   Start the backend first:"
    echo "   cd /Users/chris/hitorro/hitorro-example-springboot"
    echo "   ./mvnw spring-boot:run"
fi

echo ""
echo "========================================="
