# Data Model: Shenzhen I/O CLI Toolchain

**Feature**: `001-sio-toolchain`  
**Date**: 2025-12-21

This data model is language-agnostic and describes the entities implied by the feature spec and clarifications.

## Entities

### SourceProject

Represents extended source files used by the assembler/preprocessor.

- **Attributes**
  - `entryFile`: path to the main source file
  - `includePaths`: ordered list of directories to search for includes
  - `files`: set of referenced source files (resolved includes)
- **Validation**
  - include cycles must be detected and rejected
  - missing includes must produce a clear error (path + include chain)

### AssembledProgram

Represents the vanilla Shenzhen I/O assembly output.

- **Attributes**
  - `text`: full assembled program text
  - `sourceMap` (optional): mapping from output line(s) to input file/line for error reporting
- **Validation**
  - must contain no extended directives (`const`, `alias`, `include`) after assembly
  - must contain no comments in final output

### SimulationConfig

Defines how a simulation run is executed.

- **Attributes**
  - `cycleLimit`: maximum cycles to execute
  - `traceEnabled`: boolean
  - `portCount`: number of ports exposed as `p0..pN` (or equivalent)
  - `portMappings`: mapping from port IDs (`p0`, `p1`, …) to stream IDs

### SignalStream

A named sequence of values that can be bound to a port as input or captured as output.

- **Attributes**
  - `id`: unique stream identifier (string)
  - `samples`: ordered list of integer values
  - `rate` (optional): sample rate or interval metadata (if present in source dump)

### ExpectedOutput

Expected output checks for a single stream.

- **Attributes**
  - `streamId`: references a `SignalStream.id`
  - `mode`: `cycle-exact` or `order-only`
  - `events` (cycle-exact): list of `{ cycle, value }`
  - `values` (order-only): list of values in expected order

### TestCase

One deterministic validation scenario.

- **Attributes**
  - `name`: short human-readable identifier
  - `program`: reference to an assembled program (path or inline text reference, depending on schema)
  - `inputs`: collection of `SignalStream` definitions
  - `expectedOutputs`: collection of `ExpectedOutput` definitions
  - `cycleLimit`: max cycles for the case
  - `metadataRefs` (optional): references to local-only text assets (e.g., description/messages files)
  - `portMappings`: mapping from port IDs to stream IDs for inputs/outputs

### TestSuite

Represents a YAML/JSON file containing one or more test cases.

- **Attributes**
  - `formatVersion`: version string for schema evolution
  - `cases`: list of `TestCase`

## Notes

- Multi‑MCU entities (nodes, message channels) are intentionally omitted (out of MVP).
- “Signal dump” import is treated as an adapter that produces `SignalStream` values.

