#!/bin/bash
# Manual test script - run this in your terminal

echo "=== Manual Testing Instructions ==="
echo ""
echo "1. First, restore and build the project:"
echo "   cd src"
echo "   dotnet restore"
echo "   dotnet build"
echo ""
echo "2. Run unit tests:"
echo "   cd ../tests/Sio.UnitTests"
echo "   dotnet test"
echo ""
echo "3. Test the assemble command with the example:"
echo "   cd ../.."
echo "   dotnet run --project src/Sio.Cli/Sio.Cli.csproj -- assemble examples/us1/extended/main.asm -o /tmp/test-output.asm"
echo ""
echo "4. Check the output:"
echo "   cat /tmp/test-output.asm"
echo ""
echo "5. Compare with expected:"
echo "   diff examples/us1/expected/main.asm /tmp/test-output.asm"
echo ""
echo "=== Quick Test (copy-paste these commands) ==="
echo ""
cat << 'CMDS'
cd /Users/zerezhka/Projects/shenzhen-simulator-io/src && \
dotnet restore && \
dotnet build && \
cd ../tests/Sio.UnitTests && \
dotnet test && \
cd ../.. && \
dotnet run --project src/Sio.Cli/Sio.Cli.csproj -- assemble examples/us1/extended/main.asm -o /tmp/test-output.asm && \
echo "=== Generated Output ===" && \
cat /tmp/test-output.asm && \
echo "" && \
echo "=== Comparing with expected ===" && \
diff -u examples/us1/expected/main.asm /tmp/test-output.asm || echo "Differences found (see above)"
CMDS

