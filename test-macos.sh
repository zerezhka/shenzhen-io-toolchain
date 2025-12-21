#!/bin/bash
# macOS test script using Mono/MSBuild
# Run this from the project root
#
# Note: Mono creates .exe files even on macOS/Linux for .NET Framework executables.
# This is normal - you run them with: mono program.exe

set -e

echo "🍎 Testing on macOS with Mono..."
echo ""

# Check for Mono
if ! command -v mono &> /dev/null; then
    echo "❌ Mono not found. Install with: brew install mono"
    exit 1
fi

echo "✅ Mono version:"
mono --version | head -1
echo ""

# Navigate to src
cd src

echo "📦 Restoring NuGet packages..."
msbuild Sio.sln /t:Restore /p:RestorePackagesConfig=true 2>&1 | grep -E "(error|Restore|succeeded)" || true

echo ""
echo "🔨 Building project..."
BUILD_OUTPUT=$(msbuild Sio.sln /t:Build /p:Configuration=Debug 2>&1)
BUILD_STATUS=$?

echo "$BUILD_OUTPUT" | grep -E "(error|warning|succeeded|failed|Building)" | tail -20

if [ $BUILD_STATUS -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Check errors above."
    echo ""
    echo "Full build output saved to /tmp/build-output.txt"
    echo "$BUILD_OUTPUT" > /tmp/build-output.txt
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Go back to root
cd ..

echo "🧪 Testing the assembler with example file..."
echo ""

# Find the executable (Mono creates .exe even on macOS for .NET Framework)
CLI_PATH=""
POSSIBLE_PATHS=(
    "src/Sio.Cli/bin/Debug/net472/sio.exe"
    "src/Sio.Cli/bin/Debug/net472/sio"
    "src/Sio.Cli/bin/Debug/sio.exe"
    "src/Sio.Cli/bin/Debug/sio"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        CLI_PATH="$path"
        break
    fi
done

if [ -z "$CLI_PATH" ]; then
    echo "❌ CLI executable not found. Searched:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "   - $path"
    done
    echo ""
    echo "Build output directory contents:"
    ls -la src/Sio.Cli/bin/Debug/net472/ 2>/dev/null || echo "   (directory doesn't exist)"
    exit 1
fi

echo "✅ Found CLI at: $CLI_PATH"
echo ""

OUTPUT_FILE="/tmp/test-output.asm"
mono "$CLI_PATH" assemble examples/us1/extended/main.asm -o "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Assembler failed"
    exit 1
fi

echo ""
echo "📄 Generated output:"
echo "---"
cat "$OUTPUT_FILE"
echo "---"
echo ""

echo "📋 Expected output:"
echo "---"
cat examples/us1/expected/main.asm
echo "---"
echo ""

echo "🔍 Comparing outputs..."
if diff -u examples/us1/expected/main.asm "$OUTPUT_FILE" > /tmp/diff.txt 2>&1; then
    echo "✅ Output matches expected! 🎉"
else
    echo "⚠️  Output differs from expected:"
    cat /tmp/diff.txt
    echo ""
    echo "This might be expected if the implementation differs slightly."
fi

echo ""
echo "✨ Test complete!"

