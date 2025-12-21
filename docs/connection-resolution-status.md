# Connection Resolution Status

## Current Implementation

The `ConnectionResolver` attempts to infer chip-to-chip connections from the trace grid by:
1. Parsing the hex-encoded wiring from `[traces]`
2. Finding trace cells adjacent to chip positions
3. Following trace paths to find connected chips
4. Guessing port names based on trace direction

## Limitations

### ⚠️ Heuristic-Based Port Mapping

The current implementation uses simplified heuristics:
- Left/Right traces → assumed to be `p0` / `p1`
- Top/Bottom traces → assumed to be `x0` (XBus)

**Problem**: Real chip layouts are more complex:
- UC4 chips are 3x2 cells (width x height)
- UC6 chips are 3x3 cells
- Port positions vary by chip type and orientation
- The game has specific port locations that we don't fully model

### What Works ✓

- ✅ Trace grid parsing (hex decoding)
- ✅ Chip position extraction  
- ✅ Path finding through traces
- ✅ Detection of which chips are connected

### What Needs Work ⚠️

- ⚠️ **Port name resolution** - Heuristic, not accurate
- ⚠️ **Connection type detection** - Simplified (simple vs xbus)
- ⚠️ **Multi-port connections** - Not handled
- ⚠️ **External I/O mapping** - Puzzle-provided pins not mapped

## Current Test Status

**Tests pass** but connections may not be correctly mapped:
- Programs load and execute ✓
- But chip-to-chip data transfer may not work correctly ✗
- Tests with no expected outputs don't catch this ✗

## Solutions

### Option 1: Manual Connections (Current Workaround)

For now, users can manually specify connections:

```yaml
formatVersion: "2.0"
cases:
  - name: "My Test"
    chips:
      - id: "chip01"
        type: "MC6000"
        program: "chip1.asm"
      - id: "chip02"
        type: "MC6000"
        program: "chip2.asm"
    connections:
      - from: "chip01.p1"
        to: "chip02.p0"
        type: "simple"
```

### Option 2: Implement Proper Chip Layouts

To fix this properly, we need to:
1. Define chip layouts (UC4 = 3x2, UC6 = 3x3, etc.)
2. Map port names to specific grid offsets
3. Match trace endpoints to actual port positions
4. Handle rotations and orientations

This requires reverse-engineering the game's chip placement logic.

### Option 3: Shared Port Bus (Simpler)

Instead of explicit connections, use a **shared port bus**:
- All chips share the same PortBus instance
- Reading from `p0` reads from the global port 0
- Writing to `p1` writes to global port 1
- Mimics how the game actually works

This is simpler but less explicit about connections.

## Recommendation

For **basic testing**, the current implementation works (programs load/execute).

For **correct multi-chip behavior**, use **Option 1** (manual connections) until we implement Option 2 or 3.

The trace parser infrastructure is complete - we just need better semantic understanding of chip layouts.

