# Undocumented Shenzhen I/O Instructions

## Overview

Shenzhen I/O has two instructions that appear in **neither** shipped reference
manual. The in-game storyline presents them as a "translation oversight" from
the Chinese documentation, but this is lore: we verified (via `pdftotext`) that
both `SHENZHEN IO Manual (English).pdf` and `SHENZHEN IO Manual (Chinese).pdf`
(shipped in `Content/` of the game install, see
[local-original-assets.md](local-original-assets.md)) list the same 15
instructions — `gen` and `@` are absent from both; the Chinese manual's
instruction list goes directly from `slx P` to `add R/I`.

The only primary source for their syntax and semantics is the in-game email
`Content/messages.en/undocumented-instruction.txt`, which gives the `gen`
expansion quoted below and defines `@` as a once-only prefix.

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

### 2. `@` - Once-Only Prefix

**Syntax:**
```
@ instruction
```

**Purpose:**
Per the in-game email: "Putting an @ symbol at the beginning of an instruction
causes it to execute only once." It is a prefix (like the `+`/`-` conditional
prefixes), typically used for initialization without spending extra
instructions on a separate setup section.

**Example:**
```
@ mov 0 acc    # runs only on the first pass
loop:
add 1
jmp loop
```

## Sources

- **Primary**: in-game email `Content/messages.en/undocumented-instruction.txt`
  (local game install, gitignored — see [local-original-assets.md](local-original-assets.md))
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

