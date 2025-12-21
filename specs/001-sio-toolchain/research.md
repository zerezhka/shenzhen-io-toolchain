# Research: Shenzhen I/O CLI Toolchain

**Feature**: `001-sio-toolchain`  
**Date**: 2025-12-21

This document captures Phase 0 decisions required to proceed from the feature spec to concrete design/contracts.

## Decisions

### Decision: Single‑MCU MVP simulation scope

- **Decision**: MVP simulates a single MCU only. Multi‑MCU board simulation + message passing are deferred.
- **Rationale**: Reduces surface area while still enabling deterministic debugging and test execution.
- **Alternatives considered**:
  - Multi‑MCU simulation in MVP (rejected: larger scope and higher implementation risk)

### Decision: Instruction coverage level

- **Decision**: MVP requires full instruction set coverage for the target Shenzhen I/O MCU(s).
- **Rationale**: Avoids “unsupported instruction” blockers for valid programs.
- **Alternatives considered**:
  - Partial subset for MVP (rejected by clarification)

### Decision: Output validation semantics

- **Decision**: Tests support **cycle‑exact** expected outputs (timestamped). Order‑only comparison may exist as an optional convenience mode.
- **Rationale**: Matches cycle accuracy goals and makes timing failures unambiguous.
- **Alternatives considered**:
  - Order-only comparison (rejected as default; allowed optionally)

### Decision: Port model in simulation/tests

- **Decision**: Simulation exposes ports as `p0..pN` (single MCU). Tests map streams to specific ports.
- **Rationale**: Simple, testable, and aligns with Shenzhen I/O assembly idioms.
- **Alternatives considered**:
  - Abstract stream-only ports
  - Device-style endpoints (e.g., “audio-in”) as first-class in MVP

### Decision: Handling original game assets

- **Decision**: Repository does not include copyrighted assets. Local files (e.g., `messages.en/`, `descriptions.en/`, dumps like `nulyu.txt`) can be referenced by users locally and remain ignored by git.
- **Rationale**: Keeps repo redistributable and legally safer.
- **Alternatives considered**:
  - Bundling original assets (rejected)

### Decision: Licensing when using third‑party code

- **Decision**: Original project code is MIT; any third‑party code included retains its original license and required attribution/NOTICE material.
- **Rationale**: Legal compliance and clarity.
- **Alternatives considered**:
  - Relicensing third‑party code as MIT (rejected)

### Decision: “Upstream-first” adoption strategy

- **Decision**: Prefer adopting existing permissively-licensed components where available, then harden them with our test definitions and deterministic runner, rather than rewriting everything up front.
- **Rationale**: Faster time-to-value and better “comfort of development” if we can stand on proven community work.
- **Alternatives considered**:
  - Full rewrite from scratch (rejected as default due to time/cost; still used where licenses are unclear)

### Decision: Editor support

- **Decision**: Provide optional VS Code highlighting support (e.g., a lightweight grammar-based package); it is not a runtime dependency of the CLI.
- **Rationale**: UX improvement without coupling core tooling to an editor.

## License reconnaissance (current findings)

This section captures what we can safely reuse *today*.

- **omaskery/shenzhen.io-assembler**:
  - **License**: MIT (license text verified via GitHub API)
  - **Reuse posture**: Safe to vendor/adapt with attribution and including the MIT notice.
- **nielseneli/shenzhen-io**:
  - **License**: No `LICENSE` file found (GitHub API did not surface a license; repo clone found none).
  - **Reuse posture**: Treat as **reference/inspiration only** until an explicit license is confirmed.
- **anthonywritescode/shenzhen-io-sim**:
  - **Status**: Repository not found via GitHub API at that name.
  - **Reuse posture**: Not currently usable as an upstream dependency; requires rediscovery/verification.

## “LeetCode-like” runner UX (comfort of development)

Key behaviors to emulate:

- **One command to run a case**: `sio test case.yaml` with clear pass/fail and non-zero exit on failure
- **Readable diffs**: show expected vs actual, including cycle timestamps for cycle-exact checks
- **Determinism**: re-running produces identical outputs and trace summaries
- **Easy fixtures**: accept user-supplied signal dumps (optional adapter) to populate inputs without manual transcription

## Open follow-ups (deferred to design)

- Define concrete test definition schema fields (names, timestamps, mapping format) and trace output shape.
- Define the exact supported instruction set and timing model details for the target MCU(s) (as a spec in docs and unit tests).

