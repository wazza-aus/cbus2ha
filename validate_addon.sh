#!/bin/bash
# Validation script for Home Assistant Add-on
# Run this to check if all required files are present

echo "==================================="
echo "Home Assistant Add-on Validator"
echo "==================================="
echo ""

REQUIRED_FILES=("config.yaml" "Dockerfile" "run.sh" "DOCS.md" "build.yaml")
MISSING_FILES=()

echo "Checking required files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file MISSING"
        MISSING_FILES+=("$file")
    fi
done

echo ""
echo "Checking permissions..."
if [ -x "run.sh" ]; then
    echo "✓ run.sh is executable"
else
    echo "✗ run.sh is NOT executable"
    echo "  Fix with: chmod +x run.sh"
fi

echo ""
echo "Checking directory structure..."
if [ -d "cbus" ]; then
    echo "✓ cbus/ directory exists"
else
    echo "✗ cbus/ directory MISSING"
    MISSING_FILES+=("cbus/")
fi

echo ""
echo "Checking key Python files..."
if [ -f "cbus/daemon/cmqttd.py" ]; then
    echo "✓ cbus/daemon/cmqttd.py exists"
else
    echo "✗ cbus/daemon/cmqttd.py MISSING"
fi

if [ -f "setup.py" ]; then
    echo "✓ setup.py exists"
else
    echo "✗ setup.py MISSING"
fi

echo ""
echo "==================================="
if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✓ All required files present!"
    echo ""
    echo "Your addon directory is ready."
    echo ""
    echo "Copy this directory to Home Assistant:"
    echo "  scp -r . root@homeassistant:/addon/cbus2ha/"
    echo ""
    echo "Then in Home Assistant:"
    echo "  Settings → Add-ons → Add-on Store"
    echo "  Click ⋮ → Repositories → Add: /addon"
else
    echo "✗ Missing files detected!"
    echo ""
    echo "Missing: ${MISSING_FILES[*]}"
    echo ""
    echo "Run this script from the addon root directory."
fi
echo "==================================="






