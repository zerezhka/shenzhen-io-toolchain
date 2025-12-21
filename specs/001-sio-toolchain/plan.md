# Implementation Plan: Shenzhen I/O CLI Toolchain

**Branch**: `001-sio-toolchain` | **Date**: 2025-12-21 | **Spec**: `spec.md`  
**Input**: Feature specification from `specs/001-sio-toolchain/spec.md`

## Summary

Implement a cross-platform, CLI-first toolchain to develop Shenzhen I/O assembly outside the game:

- Assemble/preprocess extended source into vanilla game-compatible assembly
- Run deterministic, cycle-accurate single‑MCU simulation with full instruction coverage
- Execute YAML/JSON tests with cycle‑exact output validation (order‑only optional)
- Provide optional VS Code syntax highlighting for `.asm` (no editor dependency for CLI tools)

Phase 0 (research) and Phase 1 (design/contracts) artifacts are produced alongside this plan in `specs/001-sio-toolchain/`.

**Strategy note (comfort of development)**: Prefer an “upstream-first” approach where licenses allow: adopt a permissively licensed assembler/preprocessor and harden it with our tests and runner UX. For simulator functionality, only reuse upstream code when a clear, compatible license is present; otherwise implement in-house guided by publicly available instruction specs and behavior tests.

## Technical Context

**Language/Version**: C# (Mono-compatible; target .NET Framework 4.x profile supported by Mono)  
**Primary Dependencies**: Minimal CLI args parsing; JSON + YAML parsing libraries as needed (compatible with Mono)  
**Storage**: Filesystem (text inputs/outputs, traces, test definitions)  
**Testing**: NUnit (or equivalent unit/integration test framework compatible with Mono)  
**Target Platform**: Windows / macOS / Linux (headless CLI)  
**Project Type**: Single repository with multiple libraries + one CLI entrypoint  
**Performance Goals**: Typical programs/tests complete within seconds on a developer machine; simulation supports large cycle limits without runaway memory growth  
**Constraints**: Deterministic runs, reproducible outputs, no Unity dependency, no embedded copyrighted assets; preserve third‑party licenses for included code  
**Scale/Scope**: Single‑MCU simulation MVP, full instruction coverage; multi‑MCU/message passing deferred

**Upstream reuse constraints**:

- The assembler/preprocessor can be based on permissively licensed upstream code (e.g., MIT) with attribution.
- Simulator reuse must be gated on a verified license; otherwise it stays as an internal implementation (reference repos are treated as behavioral inspiration only).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: Constitution is defined at `.specify/memory/constitution.md` and is enforceable for this feature.

**Plan Gates (derived from constitution + spec)**:

- CLI-first workflow (no GUI required)
- Deterministic simulator runs and deterministic test results
- Single‑MCU MVP (multi‑MCU/message passing explicitly deferred)
- Full instruction set coverage for the target MCU(s) in MVP
- Cycle‑exact output validation supported (order‑only optional)
- Repository does not embed original game assets; local assets remain ignored
- Repository is MIT for original code; preserve third‑party licenses/attribution for included code
- Any change to parsing/simulation/test evaluation must add/update automated tests
- Contracts/schema changes must be accompanied by updated examples and schema validation

## Project Structure

### Documentation (this feature)

```text
specs/001-sio-toolchain/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── test-definition.schema.json
│   └── signal-dump.format.md
└── tasks.md
```

### Source Code (repository root)

```text
src/
├── Sio.Cli/                # `sio` command entrypoint
├── Sio.Assembler/          # preprocessor + assembler pipeline
├── Sio.Simulator/          # single-MCU execution engine + timing model
├── Sio.TestRunner/         # YAML/JSON test runner + assertions
└── Sio.EditorSupport/      # optional assets for editor tooling (non-runtime)

editor/
└── vscode-shenzhen-io/     # optional VS Code syntax highlighting package

tests/
├── unit/
└── integration/
```

**Structure Decision**: Single repo with separately testable libraries and a small CLI entrypoint. Optional editor assets live outside runtime libraries and are not required to build/run the CLI.

## Complexity Tracking

No constitution-defined violations tracked.
