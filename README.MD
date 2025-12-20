# Shenzhen I/O toolchain (assembler + simulator + tests)

Build, test, and validate Shenzhen I/O assembly **outside the game** with a **CLI-first**, cross-platform toolchain.

## Goals

- **Develop in a real editor**: unlimited line length, richer comments, clearer structure
- **Assemble to vanilla game-compatible assembly**: output suitable for manual use in Shenzhen I/O
- **Simulate deterministically**: headless, reproducible runs for debugging and validation
- **Run automated tests**: YAML/JSON test definitions with input sequences, expected outputs, and cycle limits

## Non-goals

- **No GUI**: this project is CLI-first
- **No Unity dependency**
- **No embedded copyrighted assets**: original Shenzhen I/O content must remain local-only

## Project status

Early stage (spec-first). See the current feature spec at `specs/001-sio-toolchain/spec.md`.

## CLI (planned)

- `sio assemble input.asm -o output.txt`
- `sio simulate program.asm --trace`
- `sio test level.yaml`

## Repository layout (planned)

- `src/` — implementation
  - `Assembler/`
  - `Simulator/`
  - `TestRunner/`
- `schemas/` — test definition schemas
- `examples/` — sample programs + tests
- `docs/` — instruction set, timing model, and usage notes

## Using local original game files (optional)

You can keep a local copy of original Shenzhen I/O content (e.g., `messages.en/`, `descriptions.en/`, signal dumps like `nulyu.txt`) for convenience when authoring tests and debugging.

- These files are **not meant to be committed**.
- The repo ignores `/originalgamefilessteam/` by default.
- See `docs/local-original-assets.md`.

## References / inspiration

- Assembler/preprocessor inspiration: `https://github.com/omaskery/shenzhen.io-assembler`
- Simulator references: `https://github.com/nielseneli/shenzhen-io`, `https://github.com/anthonywritescode/shenzhen-io-sim`

## License

MIT (see spec for intent; license file to be added as part of repository setup).