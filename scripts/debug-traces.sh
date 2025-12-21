#!/bin/bash
# Debug script to parse a save file and show what connections are found

set -e

SAVE_FILE="${1:-third_party/solutions/000-fake-surveillance-camera/fake-surveillance-camera-0.txt}"

if [ ! -f "$SAVE_FILE" ]; then
    echo "Error: Save file not found: $SAVE_FILE"
    exit 1
fi

echo "Parsing save file: $SAVE_FILE"
echo ""

# Create a simple C# program to test the parser
cat > /tmp/test_parser.cs << 'EOF'
using System;
using System.Linq;
using Sio.TestRunner.IO;

class Program
{
    static void Main(string[] args)
    {
        var saveFilePath = args[0];
        
        // Parse save file
        var saveFileParser = new SaveFileParser();
        var saveFile = saveFileParser.Parse(saveFilePath);
        
        Console.WriteLine($"=== Save File: {saveFile.Name} ===");
        Console.WriteLine($"Puzzle ID: {saveFile.PuzzleId}");
        Console.WriteLine($"Chips: {saveFile.Chips.Count}");
        Console.WriteLine($"Trace lines: {saveFile.TraceLines.Count}");
        Console.WriteLine();
        
        // Show chips
        Console.WriteLine("=== Chips ===");
        foreach (var chip in saveFile.Chips)
        {
            var simType = chip.GetSimulatorType();
            var status = chip.IsPuzzleProvided ? " (puzzle-provided)" : "";
            status += simType == null ? " (non-programmable)" : "";
            Console.WriteLine($"  {chip.Id}: {chip.Type} at ({chip.X}, {chip.Y}){status}");
            if (chip.CodeLines.Count > 0)
            {
                Console.WriteLine($"    Code: {chip.CodeLines.Count} lines");
            }
        }
        Console.WriteLine();
        
        // Parse traces
        var tracesParser = new TracesParser();
        var grid = tracesParser.Parse(saveFile.TraceLines);
        Console.WriteLine($"=== Trace Grid: {grid.Width}x{grid.Height} ===");
        
        // Resolve connections
        var connectionResolver = new ConnectionResolver();
        var connections = connectionResolver.Resolve(saveFile);
        
        Console.WriteLine($"=== Connections Found: {connections.Count} ===");
        foreach (var conn in connections)
        {
            Console.WriteLine($"  {conn.FromChipId}.{conn.FromPort} -> {conn.ToChipId}.{conn.ToPort} ({conn.Type})");
        }
        
        if (connections.Count == 0)
        {
            Console.WriteLine("  (No connections found - chips may be isolated or using external I/O)");
        }
    }
}
EOF

# Compile and run
cd "$(dirname "$0")/.."
msbuild /t:Build /p:Configuration=Debug src/Sio.TestRunner/Sio.TestRunner.csproj > /dev/null 2>&1

csc /r:src/Sio.TestRunner/bin/Debug/net472/Sio.TestRunner.dll \
    /r:src/Sio.Simulator/bin/Debug/net472/Sio.Simulator.dll \
    /tmp/test_parser.cs \
    -out:/tmp/test_parser.exe > /dev/null 2>&1

mono /tmp/test_parser.exe "$SAVE_FILE"

# Cleanup
rm -f /tmp/test_parser.cs /tmp/test_parser.exe

