# Undocumented Shenzhen I/O Instructions

## Overview

Shenzhen I/O has several undocumented instructions that were included in the original Chinese documentation but omitted from the English manual. This is presented in-game as a "translation oversight" as part of the storyline.

## Discovered Instructions

### 1. `gen` - Signal Generator

**Syntax:**
```
gen P X Y
```

**Parameters:**
- `P` - Port to generate signal on (p0-p9)
- `X` - Duration (in cycles) to keep signal HIGH (100)
- `Y` - Duration (in cycles) to keep signal LOW (0)

**Equivalent Code:**
```
mov 100 P
slp X
mov 0 P
slp Y
```

**Purpose:** 
Convenience instruction for generating pulse signals. Commonly used for timing-based protocols or PWM-like patterns.

**Example:**
```
# Generate a 50% duty cycle signal on p0
loop:
gen p0 5 5
jmp loop
```

### 2. `@` - Initialization Marker

**Syntax:**
```
@ [label or line]
```

**Purpose:**
Used for program counter initialization or reset. Exact behavior is somewhat inconsistent and context-dependent.

**Known Issues:**
- Some users report inconsistencies during test execution
- Behavior may vary between different MCU types
- Use with caution

**Example:**
```
@ start
# ... code ...
start:
mov 0 acc
```

## Sources

- [Shenzhen I/O Wiki - Gen Instruction](https://shenzhen-io.fandom.com/wiki/Gen_%28instruction%29)
- [Steam Community Discussions](https://steamcommunity.com/app/504210/discussions/)
- [GOG Forums - Chinese Localization Manual](https://www.gog.com/forum/shenzhen_io/chinese_localisation_manual)

## Implementation Notes

### For Assembler
- Added `gen` and `@` to valid instruction set
- `gen` requires 3 operands (port, high-duration, low-duration)
- `@` accepts 0 or 1 operands (optional label/line)

### For Simulator
- `gen` can be expanded to its equivalent mov/slp sequence
- `@` behavior needs investigation for proper implementation

## Compatibility

Including these instructions ensures compatibility with:
- Community solutions using undocumented features
- Puzzles that may reference Chinese documentation
- Advanced optimization techniques

## Testing

Found in real-world solutions:
- `160-aquaponics-maintenance-robot/chip04` uses `gen`
- Several other community solutions leverage these features

Our toolchain now supports these instructions for maximum compatibility.

