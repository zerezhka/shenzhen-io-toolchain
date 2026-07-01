# Timing Model: Shenzhen I/O Simulator

**Version**: 2.0.0  
**Date**: 2026-07-02 (v1: 2025-12-21)  
**Source**: Based on Shenzhen I/O manual and `src/Sio.Simulator/Isa/InstructionSetManifest.cs`

## Overview

**Decision (2026-07-02): the Zig simulator matches the game's time semantics.**
The synchronization quantum is the **time unit**, not the instruction. This
supersedes the simplified v1 model below, which survives only in the legacy
single-machine `Machine.step()` path (and the C# simulator) until step 6.1
migration completes.

## Game-accurate model (Zig, step 6.x)

Per the Shenzhen I/O manual:
- **Time units** are the fundamental unit of time in the game
- CPUs execute **as many instructions as they can within one time unit**,
  stopping only at `slp` (or a blocking XBus operation)
- **Cycles** count executed instructions — a power/score metric, not a clock

Implementation (`zig/src/simulate/Machine.zig` + `Board.zig`):
- `Machine.runSlice()` runs instructions back-to-back until `slp N` (yields
  `.sleep = N`), end of program (`.halted`), or the `max_slice_instructions`
  guard fires (`error.NeverSleeps` — a loop without `slp` never yields).
- `Board` owns global `time`; one `Board.stepTimeUnit()` = one slice for every
  awake machine, then `time += 1`. `slp N` ⇒ `wake_time = time + N`.
- `cycles` += 1 per executed instruction. **Sleeping costs 0 cycles** (this
  diverges from the v1 model, which charged 1 cycle per sleep tick).
- Within a time unit, machines run in index order; wire writes are immediately
  visible to later-indexed machines in the same time unit (deterministic
  simplification of the game's "simultaneous" chips).
- Unconnected pin (`pin_map` = null): reads 0, writes are discarded (game-like).

## Legacy v1 model (C# and old `Machine.step()`)

- **1 instruction = 1 cycle**, and `slp N` advances N cycles
- Time units are not modeled separately; the instruction is the sync quantum
- Kept for reference until single-chip code paths migrate to `runSlice`/`Board`

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
| `slp` timing | ✅ Implemented (v1) | Game-accurate version: step 6.0 (`runSlice`) |
| `slx` timing | ✅ C# only | Zig: step 6.3 (blocking XBus) |
| Cycle limit enforcement | ✅ Implemented | `CycleController` enforces limits |
| Deterministic execution | ✅ Implemented | Same inputs → same outputs |
| Time unit modeling | 🚧 In progress | Game-accurate `runSlice`/`Board`: steps 6.0–6.1, stubs + red tests in place |
| Multi-MCU (shared wires) | 🚧 In progress | `Board` + `Wire`, step 6.1 |

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
- Instruction-specific cycle costs (if manual specifies different costs)
- Event-driven fast-forward: when all machines are asleep, jump to
  `min(wake_time)` instead of ticking every time unit (step 6.4)
