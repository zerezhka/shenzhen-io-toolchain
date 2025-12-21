# Shenzhen I/O Instruction Set

**Version**: 1.0.0  
**Date**: 2025-12-21  
**Source**: `src/Sio.Simulator/Isa/InstructionSetManifest.cs`

This document is automatically generated from the instruction set manifest. It serves as the canonical reference for all supported instructions in the simulator.

## Instruction Categories

### Basic Instructions

- **nop** - No operation (has no effect)
- **mov** R/I R - Copy the value of the first operand into the second operand
- **jmp** L - Jump to the instruction following the specified label
- **slp** R/I - Sleep for the number of time units specified by the operand
- **slx** P - Sleep until data is available to be read on the XBus pin specified by the operand

### Test Instructions

- **teq** R/I R/I - Test if the value of the first operand (A) is equal to the value of the second operand (B)
- **tgt** R/I R/I - Test if the value of the first operand (A) is greater than the value of the second operand (B)
- **tlt** R/I R/I - Test if the value of the first operand (A) is less than the value of the second operand (B)
- **tcp** R/I R/I - Compare the value of the first operand (A) to the value of the second operand (B)

### Arithmetic Instructions

- **add** R/I - Add the value of the operand to the value of the acc register and store the result in acc
- **sub** R/I - Subtract the value of the operand from the value of the acc register and store the result in acc
- **mul** R/I - Multiply the value of the operand by the value of the acc register and store the result in acc
- **not** - If the value in acc is 0, store a value of 100 in acc. Otherwise, store a value of 0 in acc
- **dgt** R/I - Isolate the specified digit of the value in the acc register and store the result in acc
- **dst** R/I R/I - Set the digit of acc specified by the first operand to the value of the second operand

## Operand Notation

| Notation | Meaning |
|----------|---------|
| R | Register (acc, dat, p0-p9, x0-x9, null) |
| I | Integer (range -999 to 999) |
| R/I | Register or integer |
| P | Pin register (p0, p1, etc.) |
| L | Label (must be defined elsewhere in the program) |

## Total Instructions

**15 instructions** across 3 categories:
- 5 Basic instructions
- 4 Test instructions
- 6 Arithmetic instructions

## Implementation Status

All instructions listed above must have corresponding execution handlers in `src/Sio.Simulator/Isa/Instructions/`. See `tests/Sio.UnitTests/Simulator/InstructionCoverageTests.cs` for coverage validation.
