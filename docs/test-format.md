# Test Definition Format

**Version**: 1.0.0  
**Date**: 2025-12-21

This document describes the YAML/JSON format for defining test cases for Shenzhen I/O programs.

## Overview

Test definitions allow you to:
- Specify input signal sequences
- Define expected output sequences (cycle-exact or order-only)
- Set cycle limits
- Map ports to named streams
- Reference metadata files (optional)

## Schema

### Top-Level Structure

```yaml
formatVersion: "1.0"
cases:
  - name: "Test Case Name"
    program:
      path: "path/to/program.asm"
    cycleLimit: 100
    ports:
      count: 6
    portMappings:
      p0: "input_stream"
      p1: "output_stream"
    inputs:
      - id: "input_stream"
        samples: [0, 1, 2, 3]
    expectedOutputs:
      - streamId: "output_stream"
        mode: "cycle-exact"  # or "order-only"
        events: [...]  # for cycle-exact
        values: [...]   # for order-only
```

### Fields

#### `formatVersion` (required)
Schema version string for forward/backward compatibility. Currently `"1.0"`.

#### `cases` (required)
Array of test cases. Each case must have:

- **`name`** (string, required): Descriptive name for the test case
- **`program`** (object, required):
  - **`path`** (string, required): Path to vanilla assembly file (`.asm`)
- **`cycleLimit`** (integer, required, minimum 1): Maximum cycles to execute
- **`ports`** (object, required):
  - **`count`** (integer, required, minimum 1): Number of ports (p0..pN)
- **`portMappings`** (object, optional): Maps port IDs to stream IDs
  - Keys: port IDs like `"p0"`, `"p1"`, `"x0"`, etc.
  - Values: stream ID strings
- **`inputs`** (array, required): Input signal streams
  - **`id`** (string, required): Stream identifier
  - **`rate`** (integer, optional): Sample rate metadata
  - **`samples`** (array of integers, required): Input values
- **`expectedOutputs`** (array, required): Expected output streams
  - **`streamId`** (string, required): Stream identifier (must match port mapping)
  - **`mode`** (string, required): `"cycle-exact"` or `"order-only"`
  - **`events`** (array, required for cycle-exact): List of `{cycle, value}` objects
  - **`values`** (array, required for order-only): List of expected values in order
- **`metadataRefs`** (object, optional): References to local metadata files
  - **`description`** (string, optional): Path to description file
  - **`messages`** (string, optional): Path to messages file

## Output Modes

### Cycle-Exact Mode

Validates outputs at specific cycle timestamps:

```yaml
expectedOutputs:
  - streamId: "output"
    mode: "cycle-exact"
    events:
      - cycle: 5
        value: 10
      - cycle: 10
        value: 20
      - cycle: 15
        value: 30
```

**Use when**: Timing is critical (e.g., signal synchronization, real-time constraints).

### Order-Only Mode

Validates outputs by value order only, ignoring cycle timestamps:

```yaml
expectedOutputs:
  - streamId: "output"
    mode: "order-only"
    values: [10, 20, 30, 40]
```

**Use when**: Only the sequence of values matters, not when they occur.

## Port Mappings

Port mappings connect named streams to physical ports:

```yaml
portMappings:
  p0: "input_a"      # Port 0 receives "input_a" stream
  p1: "input_b"      # Port 1 receives "input_b" stream
  p2: "output"       # Port 2 produces "output" stream
```

- Input streams are queued to their mapped ports
- Output streams are read from their mapped ports
- Unmapped ports are ignored

## Input Streams

Input streams provide test data:

```yaml
inputs:
  - id: "input_a"
    samples: [0, 1, 2, 3, 4]
  - id: "input_b"
    rate: 1
    samples: [10, 20, 30]
```

- Values are queued in order
- When a port reads, it dequeues the next value
- If the queue is empty, the port returns 0

## Examples

### Example 1: Cycle-Exact Test

```yaml
formatVersion: "1.0"
cases:
  - name: "Square Wave Generator"
    program:
      path: "square.asm"
    cycleLimit: 100
    ports:
      count: 2
    portMappings:
      p0: "output"
    inputs: []
    expectedOutputs:
      - streamId: "output"
        mode: "cycle-exact"
        events:
          - cycle: 1
            value: 100
          - cycle: 4
            value: 0
          - cycle: 7
            value: 100
```

### Example 2: Order-Only Test

```yaml
formatVersion: "1.0"
cases:
  - name: "Counter"
    program:
      path: "counter.asm"
    cycleLimit: 50
    ports:
      count: 1
    portMappings:
      p0: "output"
    inputs: []
    expectedOutputs:
      - streamId: "output"
        mode: "order-only"
        values: [0, 1, 2, 3, 4, 5]
```

### Example 3: Test with Inputs

```yaml
formatVersion: "1.0"
cases:
  - name: "Adder"
    program:
      path: "adder.asm"
    cycleLimit: 50
    ports:
      count: 3
    portMappings:
      p0: "a"
      p1: "b"
      p2: "sum"
    inputs:
      - id: "a"
        samples: [10, 20]
      - id: "b"
        samples: [5, 15]
    expectedOutputs:
      - streamId: "sum"
        mode: "order-only"
        values: [15, 35]
```

## Metadata References

Optional references to local-only text assets:

```yaml
metadataRefs:
  description: "path/to/description.en"
  messages: "path/to/messages.en"
```

These files are loaded but not embedded in test outputs. They're useful for documentation and debugging.

## Format Version 2.0 (multi-chip boards)

`formatVersion: "2.0"` extends a case to a whole board (used by
`examples/multi-chip/` and all generated tests in `examples/extracted/`):

- **`chips`** (array): `{id, type, program}` — declare chips explicitly, or
- **`saveFile`** (string): path to a community save file; chips and wiring are
  loaded from its `[chip]` sections and `[traces]` grid.
- **`connections`** (array): `{from: "chipId.pN", to: "chipId.pN", type: simple|xbus}`
  for explicit wiring between chips.
- **`inputs[].target`** / **`expectedOutputs[].source`**: address a pin as
  `"chipId.pN"` instead of using `portMappings`.

### Level-terminal binding (`level.<name>`)

Tests that describe a *game level's* behavior (rather than a specific board)
address the puzzle's I/O terminals by their in-game name:

```yaml
inputs:
  - target: "level.button"     # the level's named input terminal
expectedOutputs:
  - source: "level.pulse"      # the level's named output terminal
```

Resolving `level.<name>` to a concrete chip pin on the loaded board is the
runner's job (it depends on which terminal each chip is wired to in the save
file). **Status**: convention defined here and emitted by the pixel extractor;
not yet implemented by the C# test runner — a simulator that wants to run
these tests must provide the binding.

### Timeline convention for level tests

One cycle index in a level test equals **one verification-panel time unit**
(one sleep unit / `slp 1`), because that is the only clock the game's
verification waveforms encode. Inputs carry one sample per time unit;
expected outputs are `cycle-exact` events on the same clock. `cycleLimit` is
the number of full time units the source screenshot shows — a sampled window,
not the level's full run length.

### `reviewStatus` (generated tests)

Optional top-level field, default `reviewed` when absent (hand-written tests
are unaffected):

```yaml
reviewStatus: unreviewed   # machine-generated, pending human spot-check
```

Machine-generated tests (see `tools/pixel-extractor/`) are emitted as
`unreviewed` with provenance comments naming the source screenshot and mapping
config. A human flips the field to `reviewed` after spot-checking the values
against the source; only `reviewed` tests should be relied on as correctness
oracles.

## Running Tests

```bash
sio test examples/us3/test-cycle-exact.yaml
```

The test runner will:
1. Load the test definition
2. Execute each test case
3. Report pass/fail with diffs
4. Return non-zero exit code on failure

## Failure Reporting

When a test fails, the runner shows:
- Test name
- Failure reason
- Diff showing expected vs actual (LeetCode-style)
- Cycle information

Example failure output:

```
✗ Counter - Cycle Exact
  Cycle-exact mismatch:
    Missing cycles: 5
    Extra cycles: 6
    Mismatched values:
      Cycle 9: expected 2, got 3

Stream 'output' (cycle-exact):

Cycle | Expected | Actual
------|----------|-------
    5 |       10 |      -
    9 |        2 |       3 ✗
```
