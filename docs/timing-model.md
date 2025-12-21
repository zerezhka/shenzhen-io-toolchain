# Timing Model: Shenzhen I/O Simulator

**Version**: 1.0.0  
**Date**: 2025-12-21  
**Source**: Based on Shenzhen I/O manual and `src/Sio.Simulator/Isa/InstructionSetManifest.cs`

## Overview

The simulator uses a **cycle-based timing model** where each instruction consumes cycles, and the CPU can sleep to advance time units.

## Time Units vs Cycles

According to the Shenzhen I/O manual:
- **Time units** are the fundamental unit of time in the game
- CPUs can execute **many instructions within one time unit**
- To advance to the next time unit, a CPU must use the `slp` instruction

In our simulator:
- **Cycles** are our internal unit (1 cycle per instruction, typically)
- **Time units** are advanced via `slp` (1 time unit = multiple cycles)
- For simplicity, we currently model: **1 instruction = 1 cycle**, and `slp N` advances N cycles

## Instruction Timing

### Standard Instructions (1 cycle each)

All standard instructions consume **1 cycle**:
- `nop`, `mov`, `add`, `sub`, `mul`, `not`, `dgt`, `dst`
- `jmp`, `teq`, `tgt`, `tlt`, `tcp`

### Sleep Instructions

- **`slp R/I`**: Sleeps for the specified number of time units
  - Takes 1 cycle to execute
  - Then advances time by N cycles (where N is the operand value)
  - During sleep, CPU consumes no power and executes no instructions

- **`slx P`**: Sleeps until XBus data is available
  - Takes 1 cycle to execute
  - Then waits (advancing cycles) until data is available on the specified pin
  - Wakes immediately when data becomes available

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Instruction cycle counting | ✅ Implemented | All instructions return cycle count |
| `slp` timing | ✅ Implemented | Sleeps for specified cycles |
| `slx` timing | ✅ Implemented | Waits for XBus data |
| Cycle limit enforcement | ✅ Implemented | `CycleController` enforces limits |
| Deterministic execution | ✅ Implemented | Same inputs → same outputs |
| Time unit modeling | ⚠️ Simplified | Currently 1 cycle = 1 instruction; may need refinement |

## Power Consumption Model

Per the manual:
- **Sleeping**: No power consumption
- **Active**: Power proportional to instructions executed

Our simulator tracks cycles, which correlates with power consumption.

## Determinism

The simulator is **fully deterministic**:
- Same program + same inputs → same cycle count
- Same program + same inputs → same trace output
- Same program + same inputs → same final state

This is achieved by:
- Deterministic instruction execution order
- Deterministic cycle counting
- Deterministic port I/O handling
- No random number generation
- No non-deterministic timing

## Future Enhancements

Potential improvements to timing model:
- More accurate time unit modeling (multiple instructions per time unit)
- Instruction-specific cycle costs (if manual specifies different costs)
- Multi-MCU synchronization (when multi-MCU support is added)
