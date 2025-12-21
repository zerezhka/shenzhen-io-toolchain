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

## CLI

The CLI is located at `src/Sio.Cli/bin/Debug/net472/sio.exe`. On macOS/Linux with Mono, run it with:

```bash
mono src/Sio.Cli/bin/Debug/net472/sio.exe <command> [args...]
```

Or use the wrapper script in the project root:

```bash
./sio <command> [args...]
```

**Commands:**
- `sio assemble input.asm -o output.txt` - Assemble extended assembly to vanilla
- `sio simulate program.asm --trace` - Simulate a program with optional tracing
- `sio test level.yaml` - Run test cases from a YAML/JSON file

## Repository layout

- `src/` — implementation
  - `Sio.Assembler/` — assembler/preprocessor
  - `Sio.Simulator/` — cycle-accurate simulator
  - `Sio.TestRunner/` — test runner
  - `Sio.Cli/` — CLI entrypoint
- `editor/` — editor support
  - `vscode-shenzhen-io/` — VS Code syntax highlighting extension
- `examples/` — sample programs + tests
- `docs/` — instruction set, timing model, and usage notes
- `specs/` — feature specifications and design docs

## Documentation

### Getting Started
- **[COMPILE.md](COMPILE.md)** — Build instructions for all platforms
- **[USAGE.md](USAGE.md)** — CLI commands and examples
- **[docs/extracting-your-solutions.md](docs/extracting-your-solutions.md)** — Extract your save files (macOS/Linux/Windows)

### Testing & Validation
- **[TESTING.md](TESTING.md)** — Testing guide (unit tests and examples)
- **[docs/validation-results.md](docs/validation-results.md)** — Real-world compatibility (483 solutions, 100%)

### Technical Details
- **[docs/instruction-set.md](docs/instruction-set.md)** — Complete instruction reference
- **[docs/timing-model.md](docs/timing-model.md)** — Cycle-accurate timing
- **[docs/undocumented-instructions.md](docs/undocumented-instructions.md)** — `gen` and `@` instructions
- **[docs/MC4000-vs-MC6000.md](docs/MC4000-vs-MC6000.md)** — Microcontroller differences

## Editor Support

### VS Code Syntax Highlighting

Install the VS Code extension for syntax highlighting:

```bash
cp -r editor/vscode-shenzhen-io ~/.vscode/extensions/shenzhen-io-0.1.0
```

Then reload VS Code. See `docs/editor-vscode.md` for detailed instructions.

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