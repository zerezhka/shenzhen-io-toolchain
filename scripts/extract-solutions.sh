#!/bin/bash
# Extract assembly code from Shenzhen I/O solution files
# Usage: ./extract-solutions.sh <solutions-dir> <output-dir> [game-files-dir]

set -e

SOLUTIONS_DIR="${1:-third_party/solutions}"
OUTPUT_DIR="${2:-tests/extracted-solutions}"
GAME_FILES_DIR="${3:-originalgamefilessteam/Content}"

if [ ! -d "$SOLUTIONS_DIR" ]; then
    echo "Error: Solutions directory not found: $SOLUTIONS_DIR"
    echo "Clone it first with:"
    echo "  cd third_party && git clone https://github.com/sunzenshen/shenzhen-io-solutions.git solutions"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Function to map puzzle ID to game file name
# Mapping from save file puzzle ID to game message/description file base name
map_puzzle_id() {
    case "$1" in
        Sz000) echo "security-camera" ;;
        Sz001) echo "amplifier" ;;
        Sz002) echo "pulse-generator" ;;
        Sz003) echo "animated-sign" ;;
        Sz004) echo "scorekeeper" ;;
        Sz005) echo "harmonic-maximization-engine" ;;
        Sz006) echo "infrared-sensor" ;;
        Sz007) echo "virtual-reality-buzzer" ;;
        Sz008) echo "game-controller" ;;
        Sz009) echo "laser-tag" ;;
        Sz010) echo "vape-pen" ;;
        Sz011) echo "unknown-device" ;;
        Sz012) echo "token-machine" ;;
        Sz013) echo "sandwich-robot" ;;
        Sz014) echo "targeting-laser" ;;
        Sz015) echo "haunted-doll" ;;
        Sz016) echo "shoes" ;;
        Sz017) echo "remote-kill-switch" ;;
        Sz018) echo "smart-grid" ;;
        Sz019) echo "pocket-i-ching" ;;
        Sz020) echo "food-scale" ;;
        Sz021) echo "cryptocurrency" ;;
        Sz022) echo "sliding-window" ;;
        Sz023) echo "vehicle-signal" ;;
        Sz024) echo "meat-printer" ;;
        Sz025) echo "delay-module" ;;
        Sz026) echo "reactor-status" ;;
        Sz027) echo "comm-badge" ;;
        Sz028) echo "cold-storage" ;;
        Sz029) echo "chronometer" ;;
        Sz030) echo "cat-feeder" ;;
        Sz031) echo "practice-target" ;;
        Sz032) echo "harvesting-robot" ;;
        Sz033) echo "sushi-robot" ;;
        Sz034) echo "reactor-status" ;;
        Sz035) echo "computer-interface" ;;
        Sz036) echo "scaffold-printer" ;;
        Sz037) echo "logic-board" ;;
        trailer) echo "trailer" ;;
        sandwich-robot-hard) echo "sandwich-robot-hard" ;;
        harvesting-robot-hard) echo "harvesting-robot-hard" ;;
        *) echo "" ;;
    esac
}

echo "Extracting solutions from $SOLUTIONS_DIR to $OUTPUT_DIR..."

solution_count=0
chip_count=0

# Find all .txt files (solution save files)
find "$SOLUTIONS_DIR" -name "*.txt" -type f | sort | while read -r solution_file; do
    puzzle_dir=$(basename "$(dirname "$solution_file")")
    solution_name=$(basename "$solution_file" .txt)
    
    # Extract puzzle ID and solution name from save file
    puzzle_id=$(grep -m 1 "^\[puzzle\]" "$solution_file" 2>/dev/null | awk '{print $2}')
    solution_title=$(grep -m 1 "^\[name\]" "$solution_file" 2>/dev/null | sed 's/^\[name\] //')
    
    # Map to game file name if available
    game_name=""
    puzzle_title=""
    if [ -n "$puzzle_id" ]; then
        game_name=$(map_puzzle_id "$puzzle_id")
        
        # Try to get puzzle title from game message file
        if [ -n "$game_name" ] && [ -d "$GAME_FILES_DIR/messages.en" ]; then
            message_file="$GAME_FILES_DIR/messages.en/${game_name}.txt"
            if [ -f "$message_file" ]; then
                puzzle_title=$(grep -m 1 "^Subject:" "$message_file" 2>/dev/null | sed 's/^Subject: //')
            fi
        fi
    fi
    
    # Create output directory for this puzzle
    out_dir="$OUTPUT_DIR/$puzzle_dir"
    mkdir -p "$out_dir"
    
    echo "Processing: $puzzle_dir/$solution_name"
    [ -n "$puzzle_id" ] && echo "  Puzzle ID: $puzzle_id"
    [ -n "$puzzle_title" ] && echo "  Title: $puzzle_title"
    [ -n "$solution_title" ] && echo "  Solution: $solution_title"
    
    # Create a metadata file with puzzle info
    if [ -n "$puzzle_id" ] || [ -n "$puzzle_title" ]; then
        cat > "$out_dir/puzzle-info.txt" << EOF
Puzzle ID: ${puzzle_id:-unknown}
Puzzle Title: ${puzzle_title:-Unknown}
Game File: ${game_name:-unknown}
Solution Name: ${solution_title:-Untitled}
Source File: $(basename "$solution_file")
EOF
    fi
    
    # Extract chip code blocks using awk
    awk -v solution_title="$solution_title" -v puzzle_title="$puzzle_title" '
        BEGIN { 
            in_chip=0
            in_code=0
            chip_num=0
        }
        
        /^\[chip\]/ {
            # Save previous chip if any (skip NOTE chips)
            if (in_code && code != "" && chip_type != "NOTE") {
                filename=sprintf("'"$out_dir"'/chip%02d_%s_x%s_y%s.asm", chip_num, chip_type, chip_x, chip_y)
                
                # Add header comment
                header = "# Extracted from: " solution_title
                if (puzzle_title != "") {
                    header = header "\n# Puzzle: " puzzle_title
                }
                header = header "\n# Chip " chip_num ": " chip_type " @ (" chip_x ", " chip_y ")\n"
                
                print header code > filename
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
            gsub(/\r/, "", chip_type)
            next
        }
        
        in_chip && /^\[x\]/ {
            chip_x=$2
            gsub(/\r/, "", chip_x)
            next
        }
        
        in_chip && /^\[y\]/ {
            chip_y=$2
            gsub(/\r/, "", chip_y)
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
                
                # Add header comment
                header = "# Extracted from: " solution_title
                if (puzzle_title != "") {
                    header = header "\n# Puzzle: " puzzle_title
                }
                header = header "\n# Chip " chip_num ": " chip_type " @ (" chip_x ", " chip_y ")\n"
                
                print header code > filename
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
                
                # Add header comment
                header = "# Extracted from: " solution_title
                if (puzzle_title != "") {
                    header = header "\n# Puzzle: " puzzle_title
                }
                header = header "\n# Chip " chip_num ": " chip_type " @ (" chip_x ", " chip_y ")\n"
                
                print header code > filename
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
