#!/bin/bash
# Create a YAML test case template for a Shenzhen I/O puzzle
# Usage: ./scripts/create-test-template.sh <puzzle-name> <program-path>

set -e

PUZZLE_NAME="${1}"
PROGRAM_PATH="${2}"
OUTPUT_DIR="${3:-examples/tests}"

if [ -z "$PUZZLE_NAME" ] || [ -z "$PROGRAM_PATH" ]; then
    echo "Usage: $0 <puzzle-name> <program-path> [output-dir]"
    echo ""
    echo "Example:"
    echo "  $0 'Fake Surveillance Camera' '../extracted-solutions/000-fake-surveillance-camera/chip01_MC4000_x1_y2.asm' examples/tests"
    echo ""
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Sanitize puzzle name for filename
SAFE_NAME=$(echo "$PUZZLE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
OUTPUT_FILE="$OUTPUT_DIR/${SAFE_NAME}-test.yaml"

if [ -f "$OUTPUT_FILE" ]; then
    echo "Error: Test file already exists: $OUTPUT_FILE"
    echo "Delete it first or choose a different name."
    exit 1
fi

cat > "$OUTPUT_FILE" <<EOF
# Test case for: $PUZZLE_NAME
# Generated with: scripts/create-test-template.sh
#
# Instructions:
# 1. Open the game and run the puzzle
# 2. Note the input values from the verification tab
# 3. Note the expected output values
# 4. Fill in the values below
# 5. Adjust port mappings to match your circuit
# 6. Set an appropriate cycle limit

formatVersion: 1
name: "$PUZZLE_NAME - Test Case"
program: "$PROGRAM_PATH"

# Port mappings - update these to match your circuit
ports:
  inputs:
    p0: "input1"  # Replace with actual input name from game
    # p1: "input2"  # Uncomment and add more inputs as needed
  outputs:
    p2: "output1"  # Replace with actual output name from game
    # p3: "output2"  # Uncomment and add more outputs as needed

# Input values - read from verification tab timing diagram
inputs:
  p0: [0, 1, 2, 3]  # Replace with actual values
  # p1: [10, 20, 30, 40]  # Uncomment for additional inputs

# Expected outputs - read from verification tab or compute from puzzle description
expectedOutputs:
  - port: p2
    mode: order-only  # Use "cycle-exact" if you know the exact cycles
    values: [0, 1, 2, 3]  # Replace with actual expected values
  # - port: p3
  #   mode: order-only
  #   values: [10, 20, 30, 40]

# Cycle limit - increase if your solution is complex or slow
cycleLimit: 1000

# Notes (optional):
# - Add any observations about the puzzle
# - Note any edge cases or special behaviors
# - Document assumptions about timing
EOF

echo "Created test template: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "1. Open $OUTPUT_FILE in your editor"
echo "2. Fill in the input/output values from the game"
echo "3. Update port mappings to match your circuit"
echo "4. Run the test: ./sio test $OUTPUT_FILE"
echo ""
echo "Tip: Use screenshots from third_party/solutions* for reference"

