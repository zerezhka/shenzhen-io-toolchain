# Deobfuscation Attempt — Can We Extract Level Test Data?

**Date**: 2026-06-12
**Subject**: `originalgamefilessteam/Shenzhen.exe` (local game install, gitignored)
**Goal**: Recover per-level verification test vectors (inputs + expected
outputs) for the 45 campaign puzzles.
**Result**: **Not feasible as a fast extraction.** Structure recovered;
test *data* does not exist to extract (it is generated code), and recovering
the generator logic needs tooling we don't have installed.

> All work below was done on a locally-owned copy for interoperability
> analysis. Nothing extracted is redistributed — see
> [local-original-assets.md](local-original-assets.md).

## What the binary is

- `Shenzhen.exe`: 1.4 MB PE32, Mono/.NET assembly (XNA/FNA game).
- Obfuscated with **Eazfuscator.NET**: ~10,000 `#=q…` mangled identifiers
  (`grep -c '#=q'` over the type dump), and **encrypted string literals**.

## What worked (fast)

Mono's `monodis` disassembles the whole assembly to IL in ~0.4s
(184k lines), no obfuscation barrier at the IL level. Type names survive for
engine/public types, so the puzzle scaffolding is readable:

```
Puzzle                          # one campaign level
Puzzles                         # static holder; .cctor builds all 45
PuzzleDescriptionItem
PuzzleProvidedChipTerminalPin
Terminal / TerminalType / TerminalDirection   # I/O pins
LcdPattern, Trace, Index2, ChipType           # board + display model
```

`Puzzles::.cctor` constructs every level inline. A single level looks like:

```
newobj Puzzle::.ctor()
... set name      = Decrypt(1549313900)          # encrypted string token
... set generator = Func<Ctx, int, SignalSet>    # <-- the verification logic
... set Terminals = Terminal[] { (name, type, direction, x, y), ... }
... set traces, chip layout, etc.
```

The load-bearing finding is the **generator field**:

```il
ldftn  Puzzles/'<>c'::<lambda>(class <Ctx>, int32)
newobj System.Func`3<<Ctx>, int32, <SignalSet>>::.ctor(object, native int)
stfld  Puzzle::<generatorField>
```

Every puzzle stores a `Func<Context, int, SignalSet>` — a **function** that,
given a run context and an `int` (the test-run index / seed), *computes* the
input signals and expected outputs.

## Why the test data can't simply be "extracted"

1. **It isn't data — it's code.** There is no table of input/expected vectors
   anywhere. The verification is the `Func<Ctx, int, SignalSet>` lambda,
   emitted as IL. The waveforms you see in-game are the *output* of running
   that lambda; nothing static is stored.
2. **Inputs are generated per run.** The `int` parameter is the run index, and
   the lambdas pull from a randomness context — which is why the game runs
   several verification passes. A capture yields one random sample, not the
   spec.
3. **Strings are encrypted.** Every literal is
   `Decrypt(int32 token)` (`'#=qUUf8T5EPHKSxq2ahkf3sQQ=='`), so even
   identifying which lambda is which puzzle requires running the runtime
   string decryptor.

## Why it wasn't "fast"

To turn the lambdas into readable, mappable logic you need:

- **de4dot** (or a current dnSpy/ILSpy with the Eazfuscator plugin) to strip
  the obfuscation and decrypt strings statically. **Neither `de4dot` nor
  `dnSpy` is installed** on this machine (`which de4dot dnSpy` → not found),
  and they are Windows/.NET-Framework tools — awkward under macOS/Mono.
- Even after deobfuscation, you would be reading and hand-porting 45
  generator functions, then re-implementing the RNG to reproduce specific
  runs. That is a multi-day reverse-engineering effort, not a one-shot dump.

## Has anyone already done this publicly? (searched 2026-06-12)

No public dump of SHENZHEN I/O's per-level test vectors or a deobfuscated
`Puzzles` source appears to exist. What does exist:

- **Solution corpora** — many repos of *player solutions* (sunzenshen,
  shiawasenahikari, StinkingBanana, twolfson, Spinnernicholas). These are the
  `.txt` save files we already use; none contain puzzle/test definitions.
- **`gtw123/ShenzhenMod`** — the most technically advanced public project on
  the binary. It uses **Mono.Cecil IL patching with pattern-based method
  discovery** (`ShenzhenLocator.cs`, `CecilCilExtensions.cs`): it finds
  obfuscated methods by their *IL shape* and patches them blindly, precisely
  *because* the Eazfuscator symbol names can't be recovered. It does **not**
  deobfuscate, and does **not** extract puzzle/test data. This independently
  confirms the obfuscation analysis above — even a working, maintained mod
  works around the obfuscation rather than through it.
- **de4dot / holly-hacker's EazFixer** — generic Eazfuscator removers exist
  and can decrypt strings, but symbol renaming is *unrecoverable* (the
  original names aren't in the assembly), and no one has published the result
  for this game.

Conclusion: as far as the public internet goes, this scaffolding analysis is
not pre-solved. Nobody has published the test data because, as shown above,
it isn't data — and the people who got deepest into the binary (modders) chose
to pattern-patch around the obfuscation instead.

## Practical conclusion

Confirmed for [known-gaps.md](known-gaps.md): we cannot get original per-level
test vectors by extraction. The realistic routes remain:

1. **Transcribe the 94 verification screenshots** into YAML test definitions
   (one real generated run per puzzle).
2. **Re-implement the generators** ourselves from the in-game descriptions
   (`descriptions.en/`) — clean-room, no extracted content.
3. **Power-usage oracle**: re-simulate community solutions and check the
   recorded `[power-usage]` matches (needs multi-chip simulation first).

If someone wants to push further on the binary: install `de4dot`, run it on a
copy of `Shenzhen.exe`, then open the cleaned assembly in ILSpy and read
`Puzzles::.cctor`. The structure above is the map for where to look.

## Reproduce

```bash
cd originalgamefilessteam
monodis --typedef Shenzhen.exe | grep -iE 'puzzle|terminal'   # scaffolding
monodis Shenzhen.exe > shenzhen.il                            # full IL (~184k lines)
# Puzzles::.cctor is the per-level construction; generator = Func`3<Ctx,int,SignalSet>
```
