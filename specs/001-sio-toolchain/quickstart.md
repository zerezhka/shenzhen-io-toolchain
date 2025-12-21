# Quickstart: Shenzhen I/O CLI Toolchain

**Feature**: `001-sio-toolchain`  
**Date**: 2025-12-21

This is a *design-time* quickstart describing the intended user workflow. Commands will become actionable as implementation lands.

## 1) Assemble

Assemble extended source into vanilla Shenzhen I/O assembly:

- `sio assemble input.asm -o output.txt`

Expected behavior:

- resolves `include`
- resolves `const` and `alias`
- strips comments (including block comments)
- outputs vanilla assembly text suitable for use in Shenzhen I/O

## 2) Simulate

Run a deterministic, headless single‑MCU simulation:

- `sio simulate program.asm --trace --cycles 100000`

Expected behavior:

- deterministic outputs for the same program + inputs
- full instruction coverage for the target MCU(s)
- optional trace output for debugging

## 3) Test

Run YAML/JSON tests:

- `sio test level.yaml`

Expected behavior:

- cycle‑exact output validation supported (timestamped expected outputs)
- optional order‑only comparison mode per test case (when timing is not relevant)
- non-zero exit code if any test fails

## Local original game assets (optional)

You may keep local-only original assets (e.g., `messages.en/`, `descriptions.en/`, signal dumps like `nulyu.txt`) to author tests and metadata more easily.

- These assets must **not** be committed to the repo.
- See `docs/local-original-assets.md`.

