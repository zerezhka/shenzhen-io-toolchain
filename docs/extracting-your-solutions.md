# Extracting Your Shenzhen I/O Solutions

This guide explains how to extract your personal Shenzhen I/O solutions from the game's save files and convert them to individual assembly files for use with this toolchain.

## Quick Start

### macOS / Linux (Bash)

```bash
# Use the extraction script
bash scripts/extract-solutions.sh <save-directory> <output-directory> [game-files-directory]
```

### Windows (PowerShell)

```powershell
# Use the PowerShell script
.\scripts\extract-solutions.ps1 <save-directory> <output-directory> [game-files-directory]

# Or let it auto-detect your save directory:
.\scripts\extract-solutions.ps1 -OutputDir examples\my-solutions
```

## Platform-Specific Locations

### macOS

**Save Directory Location:**
```
~/Library/Application Support/SHENZHEN IO/<steam-id>/
```

**Example:**
```bash
# Find your Steam ID directory
ls ~/Library/Application\ Support/SHENZHEN\ IO/

# Extract all solutions
cd /path/to/shenzhen-simulator-io
bash scripts/extract-solutions.sh \
  ~/Library/Application\ Support/SHENZHEN\ IO/76561198053458113 \
  examples/my-solutions
```

### Linux

**Save Directory Location:**
```
~/.local/share/SHENZHEN IO/<steam-id>/
```

**Example:**
```bash
# Find your Steam ID directory
ls ~/.local/share/SHENZHEN\ IO/

# Extract all solutions
cd /path/to/shenzhen-simulator-io
bash scripts/extract-solutions.sh \
  ~/.local/share/SHENZHEN\ IO/76561198053458113 \
  examples/my-solutions
```

### Windows

**Save Directory Location:**
```
C:\Users\<YourUsername>\Documents\My Games\SHENZHEN IO\<steam-id>\
```

**Using Git Bash or WSL:**
```bash
# Find your Steam ID directory (Git Bash)
ls "/c/Users/$USERNAME/Documents/My Games/SHENZHEN IO/"

# Extract all solutions (Git Bash)
cd /c/path/to/shenzhen-simulator-io
bash scripts/extract-solutions.sh \
  "/c/Users/$USERNAME/Documents/My Games/SHENZHEN IO/76561198053458113" \
  examples/my-solutions \
  originalgamefilessteam/Content
```

**Using PowerShell (Recommended):**
```powershell
# Auto-detect save directory (easiest!)
.\scripts\extract-solutions.ps1 -OutputDir examples\my-solutions

# Or specify manually
.\scripts\extract-solutions.ps1 `
  "$env:USERPROFILE\Documents\My Games\SHENZHEN IO\76561198053458113" `
  examples\my-solutions `
  originalgamefilessteam\Content

# Without game files
.\scripts\extract-solutions.ps1 `
  "$env:USERPROFILE\Documents\My Games\SHENZHEN IO\76561198053458113" `
  examples\my-solutions
```

**Using Command Prompt:**
```cmd
# Find your Steam ID directory
dir "%USERPROFILE%\Documents\My Games\SHENZHEN IO\"

# Extract all solutions (requires Git Bash)
cd C:\path\to\shenzhen-simulator-io
bash scripts\extract-solutions.sh ^
  "%USERPROFILE%\Documents\My Games\SHENZHEN IO\76561198053458113" ^
  examples\my-solutions ^
  originalgamefilessteam\Content
```

### PowerShell Features

The PowerShell script (`extract-solutions.ps1`) includes Windows-specific features:

- **Auto-detection**: Automatically finds your SHENZHEN IO save directory
- **Steam ID discovery**: If only one Steam ID exists, it's selected automatically  
- **Colored output**: Better readability with color-coded messages
- **Native Windows paths**: Works with backslashes and spaces in paths
- **UTF-8 encoding**: Ensures compatibility with all characters

**Example with auto-detection:**
```powershell
# Simplest usage - auto-detects everything!
cd C:\path\to\shenzhen-simulator-io
.\scripts\extract-solutions.ps1 -OutputDir examples\my-solutions

# With game files for puzzle titles
.\scripts\extract-solutions.ps1 `
  -OutputDir examples\my-solutions `
  -GameFilesDir originalgamefilessteam\Content
```

## Finding Your Steam ID

Your Steam ID is a long number (e.g., `76561198053458113`) that uniquely identifies your Steam account.

### Quick Method
Look in the save directory - there should be only one subdirectory with a numeric name:

```bash
# macOS
ls ~/Library/Application\ Support/SHENZHEN\ IO/

# Linux
ls ~/.local/share/SHENZHEN\ IO/

# Windows (PowerShell)
Get-ChildItem "$env:USERPROFILE\Documents\My Games\SHENZHEN IO\"
```

### Alternative: From Steam Profile URL
1. Open Steam and go to your profile
2. Look at the URL - it will contain your Steam ID:
   - `steamcommunity.com/profiles/76561198053458113/` (Steam ID format)
   - `steamcommunity.com/id/customname/` (custom URL - you'll need to convert)

## Output Structure

The extraction script creates one `.asm` file per chip:

```
examples/my-solutions/
└── 76561198053458113/
    ├── fake-surveillance-camera-0/
    │   ├── chip01_UC4_x10_y3.asm
    │   ├── chip02_UC4_x10_y6.asm
    │   └── chip03_UC4_x11_y3.asm
    ├── control-signal-amplifier-0/
    │   └── chip01_UC4_x9_y4.asm
    └── ...
```

**Filename Format:**
```
chip<number>_<type>_x<x>_y<y>.asm
```

- `<number>` - Chip index (01, 02, 03, ...)
- `<type>` - Chip type (UC4, UC6, UC4X, NOTE, etc.)
- `<x>`, `<y>` - Position on the PCB

## What Gets Extracted

### Included
- ✅ **UC4** - Basic microcontroller (9 lines of code)
- ✅ **UC6** - Advanced microcontroller (14 lines of code)
- ✅ **UC4X** - XBus-enabled microcontroller
- ✅ **DX3** - Logic chip (AND, OR, NOT gates)
- ✅ **RAM** - Memory chip
- ✅ **ROM** - Read-only memory chip

### Excluded
- ❌ **NOTE** - Documentation/comment chips (freeform text, not assembly)

## Processing Steps

The extraction script automatically:

1. Parses `.txt` save files
2. Extracts `[chip]` sections with `[code]` blocks
3. **Skips NOTE chips** (documentation only)
4. **Strips line number prefixes** (e.g., `1:`, `2:`, `12:`)
5. Removes leading whitespace
6. Saves as individual `.asm` files

## Testing Extracted Solutions

After extraction, validate that all solutions assemble correctly:

```bash
# Test all extracted chips
for f in examples/my-solutions/*/*.asm; do
  echo "Testing $(basename $f)..."
  mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble "$f" -o /tmp/test.out \
    || echo "FAILED: $f"
done
```

Expected output:
```
Testing chip01_UC4_x10_y3.asm...
Testing chip02_UC4_x10_y6.asm...
...
```

If all files assemble without errors, you're good to go!

## Troubleshooting

### "Directory not found"

**Problem**: The save directory doesn't exist or has a different path.

**Solutions**:
- Verify you've launched Shenzhen I/O at least once
- Check if the game is installed via Steam or standalone
- Try searching for "SHENZHEN IO" in your user directories

### "Permission denied"

**Problem**: Cannot read save files.

**Solutions**:
```bash
# Check permissions (macOS/Linux)
ls -la ~/Library/Application\ Support/SHENZHEN\ IO/*/

# Fix if needed
chmod +r ~/Library/Application\ Support/SHENZHEN\ IO/*/*.txt
```

### "No .txt files found"

**Problem**: No save files in the directory.

**Solutions**:
- Play at least one puzzle in the game and save a solution
- Check if you're looking in the correct Steam ID directory
- Verify the game saves successfully (check in-game)

### "Assembly failed on extracted code"

**Problem**: Extracted assembly doesn't assemble.

**Solutions**:
1. Check if the solution uses features not yet supported
2. Report the issue with the failing `.asm` file
3. Manually inspect the `.txt` source and `.asm` output

## Save File Format Reference

Shenzhen I/O uses a custom text-based save format:

```
[name] My Solution
[puzzle] Sz001
[production-cost] 3
[power-usage] 58
[lines-of-code] 12

[traces]
  (ASCII art of PCB traces)

[chip]
[type] UC4
[x] 10
[y] 3
[code]
  mov 0 p0
  slp 4
  mov 100 p0
  slp 2

[chip]
[type] UC4
...
```

## Advanced: Manual Extraction

If you need to extract a single solution manually:

```bash
# View a specific save file
cat ~/Library/Application\ Support/SHENZHEN\ IO/76561198053458113/fake-surveillance-camera-0.txt

# Extract just the [code] sections
awk '/^\[code\]/,/^\[/ {if (!/^\[/) print}' save-file.txt > output.asm
```

## See Also

- [USAGE.md](../USAGE.md) - CLI usage guide
- [TESTING.md](../TESTING.md) - Running tests
- [validation-results.md](validation-results.md) - Real-world solution validation

