# Third-Party Solutions for Smoke Testing

This directory contains community-contributed Shenzhen I/O solutions that can be used for smoke testing and validation of the toolchain.

## Solutions Repositories

### sunzenshen/shenzhen-io-solutions

**Source**: https://github.com/sunzenshen/shenzhen-io-solutions  
**Author**: Alan Shen (@sunzenshen)  
**License**: Public domain / No copyright (see repo README)  
**Coverage**: 47 assembly chips tested

### shiawasenahikari/SHENZHEN-IO-Solutions

**Source**: https://github.com/shiawasenahikari/SHENZHEN-IO-Solutions  
**License**: Not specified  
**Coverage**: 407 assembly chips tested (11 NOTE chips excluded)

### StinkingBanana/shenzhen-io-solutions

**Source**: https://github.com/StinkingBanana/shenzhen-io-solutions  
**License**: Not specified  
**Coverage**: 29 assembly chips tested (11 NOTE chips excluded)

**Total Validation**: 483 real-world assembly chips, 100% compatibility

## Directory Structure

All solution directories are gitignored and should be cloned manually:

```bash
cd third_party
git clone https://github.com/sunzenshen/shenzhen-io-solutions.git solutions
git clone https://github.com/shiawasenahikari/SHENZHEN-IO-Solutions.git solutions-shiawasenahikari
git clone https://github.com/StinkingBanana/shenzhen-io-solutions.git solutions-stinkingbanana
```

## File Format

Each solution directory contains:
- `*.txt` - Save file in Shenzhen I/O's format
- `*.png` - Screenshot of the solution
- `README.md` - Notes about the puzzle

### Save File Structure

The `.txt` files contain:
- `[name]` - Solution name
- `[puzzle]` - Puzzle ID (e.g., Sz000)
- `[production-cost]` - Cost metric
- `[power-usage]` - Power metric
- `[lines-of-code]` - LOC metric
- `[traces]` - ASCII art of PCB traces
- `[chip]` sections - Each MCU/chip with:
  - `[type]` - UC4, UC6, etc.
  - `[x]`, `[y]` - Position
  - `[code]` - Assembly code
  - `[is-puzzle-provided]` - Whether chip is part of puzzle

## Using for Validation

### Extract Assembly Code

The assembly code is embedded in `[chip]` sections within `[code]` blocks. Example:

```
[chip] 
[type] UC4
[x] 10
[y] 3
[code] 
  mov 0 p0
  slp 4
  mov 100 p0
  slp 2
```

### Potential Use Cases

1. **Assembler Smoke Test**: Extract code blocks and verify they assemble without errors
2. **Simulator Validation**: Run solutions and check they execute without crashing
3. **Syntax Coverage**: Identify real-world instruction patterns
4. **Regression Testing**: Use as a large corpus for change validation

## Extraction Script (Future)

A utility script could be created to:
1. Parse `.txt` files
2. Extract `[code]` blocks
3. Save as individual `.asm` files
4. Generate test manifests

Example: `scripts/extract-solutions.sh third_party/solutions/ tests/smoke/`

## Attribution

When using these solutions, please maintain attribution to the original author and repository.

## Differences from Game Format

Our toolchain uses:
- **Comments**: `#` (game uses `#`)  ✅ Compatible
- **Extended syntax**: `const`, `alias`, `include` (not in game) - would need preprocessing
- **Conditional execution**: `+ instruction` (game uses `+` prefix) ✅ Compatible

Most solutions should work directly with our assembler!

