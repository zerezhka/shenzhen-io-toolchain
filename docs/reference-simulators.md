# Reference Simulators & Assemblers

External implementations used as references for validating this toolchain's
instruction set and behavior.

## Simulators

### nielseneli/shenzhen-io

- **Repository**: https://github.com/nielseneli/shenzhen-io
- **What it is**: Computer Architecture final project — the MC3999, a Verilog
  hardware implementation of an MC4000-like microcontroller, with a Python
  assembler (`assembler/machine_codes.py` is the opcode table). The repo also
  ships its own `ISA.pdf` describing the MC3999 encoding.
- **Local clone** (gitignored, this machine only): `.tmp/licensecheck/nielseneli-shenzhen-io/`
- **Instruction coverage**: 15 of 16 mnemonics — `nop`, `mov`, `jmp`, `slp`,
  `slx`, `dst`, `dgt`, `add`, `sub`, `mul`, `not`, `teq`, `tgt`, `tlt`, `tcp`.
  It deliberately omits `gen` and the `@` once-marker (the README notes the
  MC3999 "lacks a few of the more niche assembly commands"; funct code `0101`
  is left unused in its 4-bit opcode space).

### anthonywritescode/shenzhen-io-sim

- **Repository**: https://github.com/anthonywritescode/shenzhen-io-sim
- **What it is**: Software simulator of the MCxxxx family.

## Assemblers

### omaskery/shenzhen.io-assembler

- **Repository**: https://github.com/omaskery/shenzhen.io-assembler
- **What it is**: Inspiration for the extension preprocessor syntax
  (`const`, `alias`, `include`). Vendored under
  `third_party/omaskery-shenzhen.io-assembler`.

## Instruction coverage comparison

Full game instruction set: 15 documented mnemonics plus the undocumented `gen`
and `@` (see [undocumented-instructions.md](undocumented-instructions.md)).

| Component | `slx` | `gen` | `@` |
|---|---|---|---|
| C# assembler parser (`Sio.Assembler`) | ✅ | ✅ | ✅ |
| C# simulator (`Sio.Simulator` registry/manifest) | ✅ | ❌ no `Gen` implementation | ❌ |
| Zig parser (`zig/src/parse/Parser.zig`) | ✅ | ✅ | ✅ |
| Editor support (`Sio.EditorSupport` docs) | ✅ | ✅ | ✅ |
| nielseneli/shenzhen-io (reference) | ✅ | ❌ | ❌ |

Note: because the C# parser accepts `gen` but `InstructionRegistry` has no
handler, a program using `gen` parses fine and then throws
`Unsupported instruction: gen` from `StepEngine` at runtime. The reference
simulator cannot be used to validate `gen` behavior either — the only spec is
the in-game email (`Content/messages.en/undocumented-instruction.txt`):
`gen P X Y` ≡ `mov 100 P` / `slp X` / `mov 0 P` / `slp Y`. Neither shipped
manual PDF (English or Chinese) documents `gen` or `@`; see
[undocumented-instructions.md](undocumented-instructions.md).

## Solution corpora

Community solution repositories used for smoke testing are documented in
[validation-results.md](validation-results.md) and
[`third_party/README.md`](../third_party/README.md).
