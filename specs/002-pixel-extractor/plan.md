# Implementation Plan: Pixel-Extractor for Verification-Tab Screenshots

**Branch**: `002-pixel-extractor` | **Date**: 2026-06-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-pixel-extractor/spec.md`

## Summary

Build a small Python CLI that reads the shiawasenahikari verification
screenshots, recovers per-time-unit signal values from the waveform panel, and
emits test definitions in the project's declarative YAML test format. The plan
optimizes for the **shortest path to real extracted YAML data**: P1 (binary
extraction for fake-surveillance-camera and diagnostic-pulse-generator) ships
first and produces committed `examples/extracted/` files; analog, batch, and
the manual-rule cross-check follow incrementally on the same core.

This is **development tooling**, not product code: it generates data the
toolchain consumes, and is not part of the assembler/simulator/test-runner
runtime.

## Technical Context

**Language/Version**: Python 3 (system `python3`, ≥3.9)
**Primary Dependencies**: Pillow (PIL) only — already available on this machine; no OpenCV, no OCR
**Storage**: Files — PNG screenshots in (read-only) `third_party/`, YAML configs and outputs in-repo
**Testing**: Self-check via the manual-rule cross-check (US4) + golden comparison against hand transcription; tests reference `third_party/` images and skip when absent
**Target Platform**: Developer machines (macOS/Linux/Windows with Python 3 + Pillow)
**Project Type**: Single CLI tool under `tools/`
**Performance Goals**: Full 76-screenshot batch < 5 minutes (SC-003); per-image well under 5 s
**Constraints**: Deterministic output for identical inputs; no game-binary content read or embedded; emits only derived numeric data
**Scale/Scope**: 76 screenshots, ≤45 levels, ~2–4 traces per panel, ~30–60 visible time units per trace

## Decisions (pre-made, recorded here in lieu of research.md)

| # | Decision | Rationale | Alternatives rejected |
|---|---|---|---|
| D1 | Python 3 + Pillow, in `tools/pixel-extractor/` | Already installed; image work is awkward in C#/Zig; tooling does not need Mono compatibility (Constitution III applies to the runtime toolchain) | C# (Mono imaging story is poor), Zig (no imaging ecosystem; user's Zig effort is the simulator), OpenCV (heavyweight, unneeded for polyline-on-dark extraction) |
| D2 | Per-level mapping configs are YAML files in `tools/pixel-extractor/levels/<level>.yaml` | Hand-authored, reviewable, one file per level doubles as the to-do list (FR-004) | Single monolithic config (merge churn); sidecar files next to screenshots (would write into `third_party/`) |
| D3 | **One verification-panel time unit = one test-format cycle unit** (sleep-unit granularity). Inputs emit one sample per time unit; expected outputs emit cycle-exact events `{cycle: <time-unit index, 0-based>, value}` at each change plus the initial value | The panel's x-axis is sleep-time, the only timing the screenshot encodes; pinning the convention now lets the user's new simulator adopt the same clock | Order-only mode (discards the timing the screenshots actually capture); real CPU-cycle mapping (not recoverable from pixels; depends on solution code) |
| D4 | Generated tests land in `examples/extracted/<level>/<screenshot-stem>.yaml` with a provenance comment header and a top-level `reviewStatus: unreviewed \| reviewed` field | Satisfies FR-007/FR-008; directory keeps machine-generated data apart from hand-written `examples/us*` | Separate staging branch (heavier workflow); provenance only in comments (not machine-checkable) |
| D5 | `reviewStatus` is a **new optional top-level field** in the test format (default `reviewed` when absent, so existing files are unaffected); documented in `docs/test-format.md` | Cheapest format change that makes review state machine-checkable | Directory convention only (lost on file moves); external registry file (drifts) |
| D6 | Skip `research.md`, `data-model.md`, `contracts/` artifacts | Domain research already lives in `docs/community-test-data.md`, `docs/known-gaps.md`; entities are in the spec; the only contract is the YAML schema, specified below | Full speckit artifact set (ceremony without new information) |
| D7 | Trace direction: mapping config is authoritative; brightness detection (inputs brighter) runs as a lint that warns on mismatch (FR-003) | Pixel heuristics should never silently override a human-stated fact | Brightness-only (fails on edge cases); config-only (loses a free error check) |
| D8 | The C# test runner is **not** a gate for this feature. Generated YAML must validate against the format schema; whether it runs/passes depends on simulator capabilities out of scope (spec Assumptions). A `--validate` step checks YAML shape, not execution | User is writing a new simulator; blocking data production on C# fixes inverts the priority | Requiring `sio test` to pass (couples data work to `gen`/`@`/multi-chip gaps) |

## Constitution Check

*GATE: evaluated against constitution v1.0.0.*

| Principle | Status | Notes |
|---|---|---|
| I. CLI-first, headless | ✅ | `extract.py` CLI; stdout report, stderr diagnostics, non-zero exit on failure |
| II. Determinism | ✅ | Pure function of (PNG bytes, config); no randomness, no timestamps in output body (provenance records source paths, not run time) |
| III. Cross-platform / Mono | ✅ (justified) | Python tooling runs on all three OSes. Mono compatibility governs the C#/runtime toolchain; this tool generates data consumed by it. Recorded in Complexity Tracking |
| IV. Asset safety | ✅ | Reads only community screenshots already vendored in `third_party/` under their own licenses; never reads the game binary or local-only game assets; outputs are derived numeric waveform data (FR-013) |
| V. Licensing | ✅ | Tool code is MIT. Generated data derives from third-party community screenshots — outputs carry a provenance header naming the source repo; `third_party/README.md` attribution covers the source material |
| VI. Spec-driven | ✅ | This plan implements spec 002; D5's format addition will be reflected in `docs/test-format.md` |
| VII. Quality gates | ✅ | Extractor ships with golden tests (extracted vs. hand-transcribed traces for the P1 levels) and the schema `--validate` check; format-schema change updates docs + examples |

**Post-design re-check**: no new violations introduced by the design below.

## Project Structure

### Documentation (this feature)

```text
specs/002-pixel-extractor/
├── spec.md              # Feature spec (committed)
├── plan.md              # This file
├── checklists/
│   └── requirements.md  # Spec quality checklist (committed)
└── tasks.md             # Only if /speckit.tasks is run later (optional)
```

### Source Code (repository root)

```text
tools/pixel-extractor/
├── extract.py           # CLI entry point (single level or --batch)
├── panel.py             # Panel location, grid/time-unit detection
├── traces.py            # Trace following: binary levels & analog heights, brightness lint
├── emit.py              # YAML test emission (provenance header, reviewStatus)
├── crosscheck.py        # US4: published-rule cross-check (per-level rule registry)
├── levels/              # Hand-authored per-level mapping configs
│   ├── 001-fake-surveillance-camera.yaml
│   └── 003-diagnostic-pulse-generator.yaml
└── tests/
    └── test_golden.py   # Golden traces vs. hand transcription (skips if third_party/ absent)

examples/extracted/      # Generated test definitions (committed once reviewed)
└── <level>/<screenshot-stem>.yaml

docs/test-format.md      # + reviewStatus field, + time-unit convention note
docs/community-test-data.md  # + pointer to the tool once it exists
```

**Structure Decision**: standalone tool under `tools/` (new directory — the
repo has no tooling dir yet); product code under `src/` is untouched. Generated
data is separated from hand-written examples via `examples/extracted/`.

## Design

### Mapping config schema (`tools/pixel-extractor/levels/<level>.yaml`)

```yaml
level: "001-fake-surveillance-camera"   # directory name in third_party set
puzzle: "Sz000"                          # game puzzle id (from save files)
screenshots:                             # relative to repo root
  - third_party/solutions-shiawasenahikari/001-fake-surveillance-camera/screenshot0.png
program: third_party/solutions-shiawasenahikari/001-fake-surveillance-camera/...txt
traces:                                  # top-to-bottom order in the panel
  - name: active                         # hand-typed from the panel label
    direction: output                    # input | output (authoritative, FR-003)
    class: binary                        # binary | analog | xbus (xbus → skipped)
  - name: network
    direction: output
    class: binary
ports:                                   # panel trace name → test-format port id
  active: p0
  network: p1
```

### Extraction pipeline (per screenshot)

1. **Panel location** — fixed crop window for the uniform 1920×1080 layout,
   then verified by detecting the label column and at least one orange trace
   row; verification failure ⇒ `failed: layout` (edge case, FR-001/FR-011).
2. **Row segmentation** — find each trace's horizontal band from the label
   column blocks; band count must equal `traces:` count or ⇒ `failed: mapping`.
3. **Time-unit grid** — detect the per-time-unit column width from the
   checkered background; trailing partial column dropped (FR-006).
4. **Trace following** — per band, per time-unit column: locate orange pixels
   (hue/brightness threshold); binary ⇒ high/low from y-position vs. band
   midline; analog ⇒ linear map of trace y to 0–100, rounded to nearest int.
   Ambiguity (no orange found, or two disjoint orange runs) ⇒ trace fails
   loudly with the time-unit index (FR-011).
5. **Direction lint** — mean brightness per trace; warn if ranking contradicts
   config `direction` (D7).
6. **Emit** — YAML per D3/D4/D5; `cycleLimit` = number of full visible time
   units (FR-006).

### Emitted test shape (contract)

```yaml
# GENERATED by tools/pixel-extractor — do not hand-edit values.
# source: third_party/solutions-shiawasenahikari/001-fake-surveillance-camera/screenshot0.png
# mapping: tools/pixel-extractor/levels/001-fake-surveillance-camera.yaml
formatVersion: "1.0"
reviewStatus: unreviewed          # flips to `reviewed` after human spot-check
cases:
  - name: "Fake Surveillance Camera — screenshot0 (sampled run)"
    program:
      path: ../../../third_party/...   # from mapping config
    cycleLimit: 44                     # visible full time units
    ports: { count: 2 }
    portMappings: { p0: active, p1: network }
    inputs: []                         # this level has no inputs
    expectedOutputs:
      - streamId: active
        mode: cycle-exact
        events:                        # one event per change + initial value
          - { cycle: 0, value: 0 }
          - { cycle: 6, value: 100 }
          # ...
```

Input traces emit as `inputs: [{id, samples: [one value per time unit]}]`.

### Cross-check rule registry (US4)

`crosscheck.py` holds hand-restated rules keyed by level (starting set:
amplifier `clamp((in − 50) × 4 + 50, 0, 100)`; unknown-device geometric map),
compares computed vs. extracted expected outputs per time unit with ±1
tolerance for analog quantization, and fails review on disagreement (FR-012).
Rules are re-stated from the manual by hand — no game prose is copied.

### Missing functionality picked up on the way (in scope as encountered)

- `docs/test-format.md`: document `reviewStatus` and the time-unit↔cycle
  convention (D3, D5) — the convention is the piece the user's new simulator
  needs to agree with.
- `examples/extracted/` README stub explaining provenance and the review
  workflow.

### Explicitly NOT in this feature

- C# simulator changes (`gen`/`@`, cycle-clock semantics) — user is writing a
  new simulator; D8.
- XBus value-box OCR (FR-009), sunzenshen/INFORMATION-tab screenshots,
  non-1920×1080 sources (spec Assumptions).

## Implementation order (shortest path to data)

1. **P1 vertical slice**: `panel.py` + binary `traces.py` + `emit.py` +
   mapping configs for camera & pulse generator → first two
   `examples/extracted/` files, spot-checked against the existing zoomed crops.
2. Golden test pinning those traces; `docs/test-format.md` update (D3/D5).
3. **P2 analog**: height mapping; unknown-optimization-device config.
4. **P4 cross-check** for amplifier (binary→analog math is trivial and it
   hardens P2) — note: ordered before batch because it is the correctness
   oracle for everything batch will mass-produce.
5. **P3 batch + report** over the full shiawasenahikari set; remaining mapping
   configs authored incrementally afterwards, guided by the report.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Python tool in a C#/Zig repo (Constitution III is about the Mono runtime, but this adds a third language) | Image work needs a real imaging library; Pillow is the smallest viable one and Python is preinstalled | Doing it in C# keeps one language but has no good cross-platform imaging story under Mono and would couple throwaway tooling to product code |
