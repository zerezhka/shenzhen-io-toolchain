# Trace Format (Wiring) in Shenzhen I/O Save Files

## Discovery

The `[traces]` section in save files contains **ASCII-encoded wiring diagrams**!

Example from `fake-surveillance-camera-0.txt`:
```
[traces] 
......................
......................
......................
......................
......................
......................
........1C............
.........34...........
......................
........1C............
.........34...........
......................
......................
......................
```

## Hex Character Encoding

Each character represents a **4-bit bitmask** of which sides of a cell have traces:

| Hex | Binary | Meaning         |
|-----|--------|-----------------|
| `.` | 0000   | No connections  |
| `1` | 0001   | Bottom          |
| `2` | 0010   | Right           |
| `3` | 0011   | Bottom + Right  |
| `4` | 0100   | Top             |
| `5` | 0101   | Top + Bottom    |
| `6` | 0110   | Top + Right     |
| `7` | 0111   | Top + Right + Bottom |
| `8` | 1000   | Left            |
| `9` | 1001   | Left + Bottom   |
| `A` | 1010   | Left + Right    |
| `B` | 1011   | Left + Right + Bottom |
| `C` | 1100   | Left + Top      |
| `D` | 1101   | Left + Top + Bottom |
| `E` | 1110   | Left + Top + Right |
| `F` | 1111   | All sides       |

Bits: `[Left][Top][Right][Bottom]` (0x8, 0x4, 0x2, 0x1)

## Grid Layout

- Each cell is one character
- Chips occupy specific (x, y) positions
- Traces show connections between chips and I/O pins

## Solution

**YES** - we can auto-extract connections from the `[traces]` section!

This means:
1. Read the entire save file (not just `[code]` blocks)
2. Parse `[traces]` to build a wiring graph
3. Parse `[chip]` blocks with their (x, y) positions
4. Map traces to chip ports based on spatial relationships
5. Auto-generate `connections:` in the test YAML

## Implementation Plan

1. Create `TracesParser.cs` to decode the hex grid
2. Create `CircuitLayout.cs` to map chips to positions
3. Create `ConnectionResolver.cs` to infer chip-to-chip connections from traces
4. Update multi-chip test format to make `connections:` **optional**
   - If present: use explicit connections (manual override)
   - If absent: auto-extract from save file's `[traces]`

## Benefits

- **No manual wiring specification needed!**
- Test definitions become much simpler:
  ```yaml
  formatVersion: "2.0"
  cases:
    - name: "Test from Save File"
      saveFile: "solution.txt"  # Contains chips + traces
      inputs:
        - target: "external_pin_0"  # Map to physical I/O
          samples: [1, 2, 3]
      expectedOutputs:
        - source: "external_pin_1"
          values: [2, 4, 6]
  ```

## Next Steps

Would you like me to:
1. Implement the traces parser to auto-extract connections?
2. Support loading entire save files instead of individual `.asm` files?
3. Make the test format even simpler by referencing save files directly?

