#!/bin/bash
# Extract assembly code from Shenzhen I/O solution files
# Usage: ./extract-solutions.sh <solutions-dir> <output-dir>

set -e

SOLUTIONS_DIR="${1:-third_party/solutions}"
OUTPUT_DIR="${2:-tests/extracted-solutions}"

if [ ! -d "$SOLUTIONS_DIR" ]; then
    echo "Error: Solutions directory not found: $SOLUTIONS_DIR"
    echo "Clone it first with:"
    echo "  cd third_party && git clone https://github.com/sunzenshen/shenzhen-io-solutions.git solutions"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Extracting solutions from $SOLUTIONS_DIR to $OUTPUT_DIR..."

solution_count=0
chip_count=0

# Find all .txt files (solution save files)
find "$SOLUTIONS_DIR" -name "*.txt" -type f | sort | while read -r solution_file; do
    puzzle_dir=$(basename "$(dirname "$solution_file")")
    solution_name=$(basename "$solution_file" .txt)
    
    # Create output directory for this puzzle
    out_dir="$OUTPUT_DIR/$puzzle_dir"
    mkdir -p "$out_dir"
    
    echo "Processing: $puzzle_dir/$solution_name"
    
    # Extract chip code blocks using awk
    awk '
        BEGIN { 
            in_chip=0
            in_code=0
            chip_num=0
        }
        
        /^\[chip\]/ {
            # Save previous chip if any (skip NOTE chips)
            if (in_code && code != "" && chip_type != "NOTE") {
                filename=sprintf("'"$out_dir"'/chip%02d_%s_x%s_y%s.asm", chip_num, chip_type, chip_x, chip_y)
                print code > filename
                close(filename)
            }
            
            in_chip=1
            in_code=0
            chip_num++
            chip_type=""
            chip_x=""
            chip_y=""
            code=""
            next
        }
        
        in_chip && /^\[type\]/ {
            chip_type=$2
            next
        }
        
        in_chip && /^\[x\]/ {
            chip_x=$2
            next
        }
        
        in_chip && /^\[y\]/ {
            chip_y=$2
            next
        }
        
        in_chip && /^\[code\]/ {
            in_code=1
            code=""
            next
        }
        
        in_chip && in_code && /^\[/ {
            # Hit another section tag - save and end code block (skip NOTE chips)
            if (code != "" && chip_type != "NOTE") {
                filename=sprintf("'"$out_dir"'/chip%02d_%s_x%s_y%s.asm", chip_num, chip_type, chip_x, chip_y)
                print code > filename
                close(filename)
            }
            in_code=0
            code=""
            
            # Check if this is still chip-related
            if ($0 !~ /^\[(type|x|y|is-puzzle-provided|comment|rom)\]/) {
                in_chip=0
            }
            next
        }
        
        in_chip && in_code {
            # Accumulate code lines (strip leading spaces and line numbers)
            line=$0
            sub(/^  /, "", line)
            # Strip line number prefixes (e.g., "1:", "12:", etc.)
            sub(/^[0-9]+:/, "", line)
            
            # Skip empty lines at start
            if (code == "" && line == "") {
                next
            }
            
            if (code == "") {
                code = line
            } else {
                code = code "\n" line
            }
        }
        
        END {
            # Save final chip if any
            if (in_code && code != "" && chip_type != "NOTE") {
                filename=sprintf("'"$out_dir"'/chip%02d_%s_x%s_y%s.asm", chip_num, chip_type, chip_x, chip_y)
                print code > filename
                close(filename)
            }
        }
    ' "$solution_file"
    
    solution_count=$((solution_count + 1))
    
    # Count extracted chips
    chip_count=$(find "$out_dir" -name "*.asm" -type f | wc -l | tr -d ' ')
done

total_chips=$(find "$OUTPUT_DIR" -name "*.asm" -type f | wc -l | tr -d ' ')

echo ""
echo "Extraction complete!"
echo "Solutions processed: $solution_count"
echo "Total chips extracted: $total_chips"
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "To test assembly on all extracted files:"
echo "  find $OUTPUT_DIR -name '*.asm' | while read f; do"
echo "    echo \"Testing \$f...\""
echo "    mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble \"\$f\" -o /tmp/test.out || echo \"FAILED: \$f\""
echo "  done"
