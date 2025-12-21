# Multi-Chip Test Definition Format

## Overview

Real Shenzhen I/O solutions use multiple microcontrollers connected together via XBus connections. This document describes the extended test format that supports multi-chip configurations.

## Format

### Single-Chip (Current Format)

```yaml
formatVersion: "1.0"
cases:
  - name: "Simple Test"
    program:
      path: "chip.asm"
    cycleLimit: 100
    ports:
      count: 6
    portMappings:
      p0: "input"
      p1: "output"
    inputs:
      - id: "input"
        samples: [1, 2, 3]
    expectedOutputs:
      - streamId: "output"
        mode: "order-only"
        values: [2, 4, 6]
```

### Multi-Chip (New Format)

```yaml
formatVersion: "2.0"  # New version for multi-chip
cases:
  - name: "Two-Chip Pipeline"
    cycleLimit: 1000
    
    # Define multiple chips
    chips:
      - id: "chip1"
        type: "MC6000"  # or MC4000
        program: "chip1.asm"
      - id: "chip2"
        type: "MC6000"
        program: "chip2.asm"
    
    # Wire chips together
    connections:
      # Connect chip1's p0 to chip2's p0 (XBus or simple connection)
      - from: "chip1.p0"
        to: "chip2.p0"
        type: "xbus"  # or "simple"
      # Connect chip1's p1 to chip2's p1
      - from: "chip1.p1"
        to: "chip2.p1"
        type: "simple"
    
    # External inputs (from test harness to chips)
    inputs:
      - target: "chip1.p2"  # Target a specific chip's port
        id: "external_input"
        samples: [10, 20, 30]
    
    # Expected outputs (from chips to test harness)
    expectedOutputs:
      - source: "chip2.p3"  # Read from a specific chip's port
        streamId: "final_output"
        mode: "order-only"
        values: [100, 200, 300]
```

## Connection Types

### Simple Connections
- Direct value transfer
- No blocking/waiting
- Value is immediately available

### XBus Connections
- Blocking read/write
- Both chips must coordinate (one writes, one reads)
- Simulates real XBus behavior in the game

## Chip Types

- **MC4000**: 9 lines of code, registers: `acc`, ports: p0-p1, x0-x1
- **MC6000**: 14 lines of code, registers: `acc`, `dat`, ports: p0-p1, x0-x2
- **MC4000X**: Same as MC4000 but with x0-x2

## Port Addressing

Format: `<chip-id>.<port-name>`

Examples:
- `chip1.p0` - Simple port 0 on chip1
- `chip2.x1` - XBus port 1 on chip2
- `multiplier.p1` - Named chip's port

## Backward Compatibility

- Format version `1.0` = single-chip (current)
- Format version `2.0` = multi-chip (new)
- Single-chip tests continue to work unchanged

