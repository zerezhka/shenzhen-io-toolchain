#!/bin/bash
# Quick test script for the assembler
# Run this after building the project

set -e

echo "=== Testing Shenzhen I/O Assembler ==="
echo ""

# Build the project first
echo "1. Building project..."
cd src
dotnet restore 2>&1 | grep -v "warning\|info" || true
dotnet build 2>&1 | grep -E "(error|warning|succeeded|failed)" || true
cd ..

# Test the example
echo ""
echo "2. Testing example assembly..."
TEST_OUTPUT="/tmp/test-output.asm"
dotnet run --project src/Sio.Cli/Sio.Cli.csproj -- assemble examples/us1/extended/main.asm -o "$TEST_OUTPUT"

echo ""
echo "3. Output generated:"
cat "$TEST_OUTPUT"

echo ""
echo "4. Comparing with expected output..."
if diff -u examples/us1/expected/main.asm "$TEST_OUTPUT" > /tmp/diff.txt; then
    echo "✅ Output matches expected!"
else
    echo "❌ Output differs from expected:"
    cat /tmp/diff.txt
    exit 1
fi

echo ""
echo "=== All tests passed! ==="

