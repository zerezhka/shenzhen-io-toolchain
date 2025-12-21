# Community Test Data Sources

## Overview

While the game doesn't expose test cases in an extractable format, the community has created valuable resources that can help generate test definitions.

## Screenshot-Based Test Data

### Available Resources

We have **94 screenshots** with verification timing diagrams in our third-party solution repositories:

```bash
# Count of screenshots with potential verification data
find third_party/solutions -name "*.png" | wc -l          # 18 screenshots
find third_party/solutions-shiawasenahikari -name "*.png" | wc -l  # 76 screenshots
find third_party/solutions-stinkingbanana -name "*.png" | wc -l    # 0 screenshots
```

### Example: Unknown Optimization Device

The file `third_party/solutions-shiawasenahikari/012-unknown-optimization-device/screenshot0.png` shows:

- **INFORMATION Tab**: Puzzle description and requirements
- **VERIFICATION Tab**: Signal timing diagrams showing:
  - Input signals: `simple input` (appears twice), `power`
  - Output signals: `simple output`
  - Timing relationships: cycle-accurate waveforms

### What Can Be Extracted

From verification screenshots, we can identify:

1. **Input Port Names**: e.g., "simple input", "power", "x", "y"
2. **Output Port Names**: e.g., "simple output", "power", "z"
3. **Signal Patterns**: Visual waveforms showing expected I/O behavior
4. **Relative Timing**: When outputs should change relative to inputs

### What Cannot Be Automatically Extracted

- **Exact Values**: Screenshots show visual waveforms, not numeric data
- **Cycle Numbers**: X-axis is visible but requires OCR and manual mapping
- **Port Indices**: The game uses semantic names, we use `p0`, `p1`, etc.

## Approaches for Test Generation

### Option 1: Manual Transcription (Current Best Option)

For each puzzle you want to test:

1. Open the screenshot with the verification tab
2. Manually read the timing diagram
3. Create a YAML test file like:

```yaml
formatVersion: 1
name: "Unknown Optimization Device - Manual Test"
program: "../extracted-solutions/012-unknown-optimization-device/chip01_MC6000_x1_y2.asm"
ports:
  inputs:
    p0: "simple input"
    p1: "power"
  outputs:
    p2: "simple output"
inputs:
  p0: [10, 20, 30, 40]  # Read from diagram
  p1: [100, 100, 100, 100]
expectedOutputs:
  - port: p2
    mode: order-only
    values: [30, 50, 70, 90]  # Computed based on puzzle description
cycleLimit: 1000
```

**Pros:**
- Accurate and reliable
- No OCR or image processing needed
- You understand the test you're creating

**Cons:**
- Time-consuming (but only needs to be done once per puzzle)
- Requires domain knowledge

### Option 2: OCR + Image Processing (Complex)

Use image processing to extract timing diagrams:

1. **OCR** to read port names and cycle numbers
2. **Waveform analysis** to extract signal transitions
3. **Value extraction** from waveform heights

**Pros:**
- Could automate test generation for all 94 screenshots

**Cons:**
- Very complex implementation (OpenCV, Tesseract, custom waveform parser)
- Error-prone (requires validation of every generated test)
- Screenshots may vary in quality/format
- Not all screenshots show verification tab

### Option 3: Community Contribution

Create a simple web form or spreadsheet where players can:

1. Select a puzzle
2. Paste input values from the game
3. Paste expected output values
4. Export as YAML

**Pros:**
- Leverages community knowledge
- Simple to implement
- No complex image processing

**Cons:**
- Requires community engagement
- Manual effort (but distributed)

## Recommendation

**Start with Option 1** for puzzles you personally want to test:

1. Pick 5-10 interesting puzzles
2. Manually create test cases while viewing verification screenshots
3. Document the process for contributors
4. Share test cases in the repo for others to use/extend

**Future Enhancement (Option 3):**
- Create a simple test case template generator script
- Document the process for community contributions
- Accept pull requests with new test definitions

## Test Case Coverage

Current state:
- ✅ **Assembly**: 100% (501/501 solutions assemble successfully)
- ⚠️ **Simulation**: Limited (only 3 manual test cases in `examples/`)
- 🎯 **Target**: Create test cases for 10-20 representative puzzles

Representative puzzles to prioritize:
1. **Fake Surveillance Camera** (Sz000) - First puzzle, simple I/O
2. **Animated Sign** (Sz001) - Pattern generation
3. **Diagnostic Pulse Generator** (Sz002) - Timing-sensitive
4. **Harmonic Maximization Engine** (Sz003) - Math operations
5. **Drinking Game Scorekeeper** (Sz004) - State machine
6. **Unknown Optimization Device** (Sz010) - Complex logic

## Resources

- [sunzenshen/shenzhen-io-solutions](https://github.com/sunzenshen/shenzhen-io-solutions) - 18 PNG screenshots
- [shiawasenahikari/SHENZHEN-IO-Solutions](https://github.com/shiawasenahikari/SHENZHEN-IO-Solutions) - 76 PNG screenshots
- Game save files - Input test data only, no expected outputs
- Steam Community guides - Descriptive, not machine-readable

