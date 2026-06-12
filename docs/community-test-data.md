# Community Test Data Sources

## Overview

While the game doesn't expose test cases in an extractable format, the community has created valuable resources that can help generate test definitions.

## Screenshot-Based Test Data

### Available Resources

We have **94 screenshots** in our third-party solution repositories, but the
two sources are not equally useful (verified 2026-06-12 by inspecting crops at
full resolution):

```bash
# Count of screenshots with potential verification data
find third_party/solutions -name "*.png" | wc -l          # 18 screenshots
find third_party/solutions-shiawasenahikari -name "*.png" | wc -l  # 76 screenshots
find third_party/solutions-stinkingbanana -name "*.png" | wc -l    # 0 screenshots
```

- **`solutions-shiawasenahikari` (76 PNGs) — the primary source.** Uniform
  1920×1080 layout, verification tab open with waveforms visible at the bottom
  of the frame (sampled: levels 001, 003, 012, 027 — all show it), numbered
  folders covering all 41 campaign levels plus bonus levels.
- **`solutions` (sunzenshen, 18 PNGs) — mostly not useful.** The sampled
  screenshots show the INFORMATION tab with the verification panel collapsed.

### Waveform classes and how transcribable each is

The verification panels fall into three classes (examples are crops at 2×
upscale from the shiawasenahikari set):

1. **Binary simple I/O** (e.g. 001 fake surveillance camera, 003 diagnostic
   pulse generator): crisp two-level orange traces over a per-time-unit grid.
   Trivially human-readable; also machine-extractable (see Option 2). For the
   camera the description says the signals are "fixed, repeating", so the
   screenshot *is* the spec, not just one sampled run.
2. **Analog simple I/O** (e.g. 012 unknown optimization device): continuous
   0–100 traces, value encoded as trace height. Readable, but pixel
   measurement is more reliable than eyeballing.
3. **XBus numeric** (e.g. 027 deep-sea sensor grid): packet values rendered as
   small number boxes. Readable at 2× zoom, so manual transcription works but
   is tedious; this is the only class where automation would need OCR.

Inputs are rendered as brighter orange traces than expected outputs, which
disambiguates direction even without reading the port-label text.

**Caveat — visible window only**: the panel shows only the on-screen portion
of the timeline; a verification run may extend past the right edge. Tests
transcribed from a screenshot should bound `cycleLimit` to the visible span.

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

- **XBus packet values**: rendered as small number boxes — needs OCR (or
  manual reading at zoom); simple-I/O waveform *values* are extractable from
  trace height, see Option 2
- **Port Indices**: The game uses semantic names, we use `p0`, `p1`, etc.
- **The full run**: only the visible timeline window is captured (see caveat
  above)

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

### Option 2: Pixel Extraction (IMPLEMENTED — `tools/pixel-extractor/`)

> **Status 2026-06-12**: implemented for binary simple I/O; first extracted
> tests live in `examples/extracted/` (fake surveillance camera, diagnostic
> pulse generator), overlay-verified and pinned by golden tests. See
> `specs/002-pixel-extractor/` for the full plan.

Earlier versions of this doc rated automation as "very complex (OpenCV,
Tesseract, custom waveform parser)". Inspection of the actual pixels
(2026-06-12) shows that is overstated for the shiawasenahikari set:

- The verification panel sits at a consistent position in every 1920×1080
  screenshot.
- Waveforms are single orange polylines on a near-black background, with a
  visible per-time-unit grid — a small Python/PIL script can recover binary
  levels (high/low per column) and analog values (trace height per column)
  with **no OCR at all**.
- Port labels are few per level and can simply be hand-typed.
- Only **XBus levels** need OCR (Tesseract on the number boxes) or manual
  reading.

**Pros:**
- Could bulk-generate test vectors for most of the 41 campaign levels
- More accurate than eyeballing analog trace heights

**Cons:**
- Generated tests still need a human spot-check pass
- XBus levels remain manual/OCR
- Captures one sampled run, truncated to the visible timeline window

### Option 2b: Clean-Room Oracle from Manual + Descriptions

For input→output puzzles, the expected output is a *function* of the input,
and for some levels that function is published verbatim in local assets:

- **10 of 45 level descriptions** (`descriptions.en/`) point to the manual for
  their behavioral spec (`grep -rln -i manual descriptions.en/` → 10 files:
  unknown-device, amplifier, bartender, haunted-doll, comm-badge,
  spoiler-blocker, targeting-laser, shoes, scaffold-printer, meat-printer).
- The manual's **Supplemental Data** section contains exact formulas — e.g.
  the harmonic maximization engine's `AUDIO_OUT = (AUDIO_IN - 50) x 4 + 50`
  and the unknown optimization device's full x/y→power "2A27 GEOMETRIC
  SPECIFICATIONS" map (verified via `pdftotext`).

So for these levels: transcribe (or pixel-extract) only the **input** traces
from a screenshot, then *compute* the expected outputs from the published
rule. This yields a complete test vector without reverse-engineering anything,
and the computed outputs double-check the transcribed ones.

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

1. **Option 1 now** for the binary-waveform priority levels (camera, pulse
   generator, animated sign) — readable today with no tooling.
2. **Option 2 pixel-extraction script** against the shiawasenahikari set to
   bulk-generate binary/analog vectors, with manual spot-checks.
3. **Option 2b** for the 10 manual-specified levels — compute expected outputs
   from the published rules instead of transcribing them.

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

- [shiawasenahikari/SHENZHEN-IO-Solutions](https://github.com/shiawasenahikari/SHENZHEN-IO-Solutions) - 76 PNG screenshots, verification tab visible — the primary source
- [sunzenshen/shenzhen-io-solutions](https://github.com/sunzenshen/shenzhen-io-solutions) - 18 PNG screenshots, mostly INFORMATION tab only
- Game manual PDF (`Content/SHENZHEN IO Manual (English).pdf`, local install) - exact behavioral formulas for ~10 levels in the Supplemental Data section
- Game save files - Input test data only, no expected outputs
- Steam Community guides - Descriptive, not machine-readable

