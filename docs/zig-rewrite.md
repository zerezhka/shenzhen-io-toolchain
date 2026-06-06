# Direction: rewrite the toolchain in Zig

**Status:** planned · **Started:** 2026-06-06

> Beginner-friendly, step-by-step companion (на русском, с объяснением понятий и
> ссылками): [zig-plan.md](zig-plan.md).

## Why

The current toolchain is C# targeting **.NET Framework 4.7.2 (`net472`)**. On
Linux/macOS that means shipping a `.exe` and running it through **Mono**
(`mono sio.exe`), plus pulling in the .NET SDK to build. That `.exe`-plus-runtime
approach is the main thing we want to get away from.

Goals of the rewrite:

- **Single native binary, no runtime.** `sio` should be a self-contained
  executable on Linux/macOS/Windows — no Mono, no .NET install.
- **Simple builds.** `zig build` with no SDK juggling or framework targeting.
- **Learning Zig.** This is also a deliberate excuse to get hands-on with the
  language; expect the early code to be exploratory.

This does **not** mean the C# code was wrong — it stays as the reference
implementation (see below). It's a runtime/distribution change, not a
correctness fix.

## The C# code is the reference (the oracle)

The existing C# toolchain is validated against **483 real-world community
solutions at 100% compatibility** (see `docs/validation-results.md`). That makes
it a precise specification:

- Keep `src/` (C#) building and runnable during the rewrite.
- Port component by component; for each one, **diff the Zig output against the
  C# output** on the same inputs (examples + the third-party solution sets).
- Treat any divergence as a bug in the Zig port until proven otherwise.

The docs are the human-readable spec to port from:

- `docs/instruction-set.md` — the 15 documented instructions + operand notation
- `docs/undocumented-instructions.md` — `gen` and `@` (from the Chinese manual)
- `docs/timing-model.md` — cycle-accurate timing
- `docs/MC4000-vs-MC6000.md` — microcontroller differences

## Scope / components to port

In rough dependency order:

1. **Assembler** — comment stripping, `const`/`alias`/`include` preprocessing,
   tokenizer, parser, vanilla emitter. (C#: `src/Sio.Assembler`)
2. **Simulator** — ISA handlers, CPU/registers, ports (simple + XBus),
   cycle controller, tracer. (C#: `src/Sio.Simulator`)
3. **Test runner** — YAML/JSON test definitions, matchers, multi-chip
   coordination, save-file parsing. (C#: `src/Sio.TestRunner`)
4. **CLI** — `sio assemble | simulate | test`. (C#: `src/Sio.Cli`)
5. **Language server** *(later)* — the LSP server currently in C#
   (`src/Sio.EditorSupport`). Can be ported last, or kept in C# until the rest
   is stable, since the editor clients just launch whatever `sio-langserver`
   binary they're pointed at.

## Proposed layout

Keep the rewrite isolated so both implementations coexist:

```
src/      # existing C# toolchain (reference, stays building)
zig/      # new Zig implementation
  build.zig
  src/
    assembler/
    simulator/
    testrunner/
    main.zig          # sio CLI entrypoint
  tests/
```

The `./sio` wrapper can switch to the Zig binary once `assemble`/`simulate`
reach parity, with the C# path kept as a fallback during the transition.

## Editor plugins during/after the rewrite

The VS Code extension and IntelliJ plugin are **unaffected by the runtime
change** in principle:

- They shell out to a `sio` CLI and launch a language server over stdio. Point
  them at the Zig `sio` binary (no `mono` prefix needed) once it's ready.
- The CLI/mono wiring in both clients (`shenzhenIo.mono.path`, the
  `mono sio-langserver.exe` launch) becomes unnecessary and can be dropped when
  the server is native.
- The IntelliJ lexer/highlighter is pure-Kotlin and independent of all this.

## Milestones

- [ ] `zig build` skeleton + `sio --version`
- [ ] Assembler: tokenizer + parser + emitter; diff `assemble` vs C# on `examples/`
- [ ] Assembler: preprocessor (`const`/`alias`/`include`, comments)
- [ ] Simulator: core ISA + `simulate` with `--trace` and `--cycles`
- [ ] Validate against the third-party solution sets (target: 100% like C#)
- [ ] Test runner + `sio test`
- [ ] Flip `./sio` to the Zig binary; mark C# as reference-only
- [ ] (optional) Native language server; drop `mono` from the editor clients
```
