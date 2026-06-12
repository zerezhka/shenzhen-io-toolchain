# Feature Specification: Pixel-Extractor for Verification-Tab Screenshots

**Feature Branch**: `002-pixel-extractor`
**Created**: 2026-06-12
**Status**: Draft
**Input**: User description: "Pixel-extractor for verification-tab screenshots: a tool that reads the 76 shiawasenahikari verification screenshots (uniform 1920x1080, verification panel at a consistent position, orange waveform polylines on a dark per-time-unit grid) and extracts behavioral test data into the project's declarative YAML test format — clean-room reconstructing per-level test vectors. Binary simple-I/O traces extract as high/low levels per time unit; analog simple-I/O traces extract as 0-100 values from trace height; XBus numeric value boxes are out of scope for automated extraction (manual/OCR later). Inputs are brighter orange than expected outputs, which disambiguates signal direction. Port labels are hand-typed via a small per-level mapping config, not OCR'd. Generated YAML tests must bound cycleLimit to the visible timeline window and require a human spot-check pass before being committed as examples."

## Overview

The project currently has original-game behavioral test data for **zero** of the
45 campaign levels ([known-gaps.md](../../docs/known-gaps.md), gap 4). The best
available proxy is the set of 76 community verification screenshots
(`third_party/solutions-shiawasenahikari/`), whose waveform panels were assessed
as machine-extractable on 2026-06-12
([community-test-data.md](../../docs/community-test-data.md), Option 2). This
feature turns those screenshots into test definitions in the project's
declarative YAML format ([test-format.md](../../docs/test-format.md)), giving the
simulator its first per-level behavioral test corpus — reconstructed clean-room
from already-public community images, without touching the obfuscated game
binary.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Extract a binary simple-I/O level into a YAML test (Priority: P1)

A test author picks a level whose verification panel shows only two-level
(high/low) simple-I/O waveforms — e.g. fake surveillance camera or diagnostic
pulse generator — writes a small per-level mapping entry (which trace is which
named port, which solution program the test should run against), runs the
extractor on that level's screenshot, and receives a YAML test definition with
per-time-unit input samples and expected output events that the existing test
runner can load.

**Why this priority**: Binary waveforms are the most reliable class to extract
and cover the early campaign levels that were already identified as the
highest-value starting set. One working level proves the entire pipeline
(image → traces → YAML → test runner) end to end.

**Independent Test**: Run the extractor on the fake-surveillance-camera
screenshot with its mapping entry; compare the emitted YAML against an
independent hand transcription of the same waveforms; load the YAML with the
test runner to confirm it is well-formed.

**Acceptance Scenarios**:

1. **Given** a screenshot with a visible verification panel containing only
   binary simple-I/O traces and a mapping entry for the level, **When** the
   extractor runs, **Then** it emits a YAML test definition that conforms to the
   project's test format and contains one stream per mapped trace with the
   correct high/low value for every visible time unit.
2. **Given** the emitted YAML, **When** it is loaded by the existing test
   runner, **Then** it parses without errors and the `cycleLimit` does not
   exceed the timeline span visible in the screenshot.
3. **Given** a trace marked as an input in the mapping entry, **When** the
   extractor emits the test, **Then** that trace appears as an input stream and
   the dimmer traces appear as expected-output streams (and a mismatch between
   the mapping entry and the detected brightness direction is reported as a
   warning, with the mapping entry winning).

---

### User Story 2 - Extract analog simple-I/O levels (Priority: P2)

A test author runs the extractor on a level whose panel contains continuous
0–100 traces (e.g. unknown optimization device). The extractor reads each
trace's height per time unit and emits the corresponding integer values.

**Why this priority**: Analog levels are the second-largest extractable class
and are precisely the ones where pixel measurement beats human eyeballing —
but they depend on the trace-following machinery proven in User Story 1.

**Independent Test**: Run the extractor on the unknown-optimization-device
screenshot; verify the extracted x/y input curves are smooth integer sequences
in 0–100 and that the power output levels match what a human reads from the
zoomed crop.

**Acceptance Scenarios**:

1. **Given** a panel with analog traces, **When** the extractor runs, **Then**
   each trace yields one integer value in 0–100 per visible time unit, derived
   from trace height.
2. **Given** a time unit where the trace height falls between two integer
   values, **When** the extractor quantizes it, **Then** it picks the nearest
   value and the overall sequence contains no single-unit spikes that are not
   present in the source image.

---

### User Story 3 - Batch run with coverage report (Priority: P3)

A maintainer runs the extractor across the whole shiawasenahikari screenshot
set and receives a per-screenshot report: extracted (with output path), skipped
(no verification panel visible, XBus-only, or no mapping entry yet), or failed
(image deviates from the expected layout). No screenshot is silently dropped.

**Why this priority**: Turns the per-level tool into corpus production and
makes the remaining manual work visible (which levels still need mapping
entries, which are XBus-bound), but is pure orchestration over Stories 1–2.

**Independent Test**: Run the batch command over `third_party/solutions-shiawasenahikari/`;
confirm every PNG in the set appears exactly once in the report with a
classification, and that the counts add up to the total number of screenshots.

**Acceptance Scenarios**:

1. **Given** the full screenshot directory, **When** the batch run completes,
   **Then** every screenshot is classified as extracted, skipped (with reason),
   or failed (with reason), and the report totals match the file count.
2. **Given** a level with multiple screenshots, **When** the batch runs,
   **Then** each usable screenshot becomes a separate named test case for that
   level (each screenshot is one sampled verification run).
3. **Given** a level whose panel contains both simple-I/O traces and XBus value
   boxes, **When** the extractor runs, **Then** the simple-I/O traces are
   extracted, the XBus signals are listed as not extracted, and the emitted
   test is flagged as partial.

---

### User Story 4 - Cross-check against published level rules (Priority: P4)

For the ~10 levels whose input→output rule is published in the game manual's
Supplemental Data section (e.g. the amplifier formula, the unknown-device
x/y→power map — see [community-test-data.md](../../docs/community-test-data.md)
Option 2b), a reviewer can have the extracted **expected outputs** checked
against outputs **computed** from the extracted inputs via the published rule,
and see any disagreements per time unit.

**Why this priority**: This is the strongest correctness signal available — two
independent reconstructions agreeing — but it only applies to a subset of
levels and needs Stories 1–2 to exist first.

**Independent Test**: Run the cross-check on the control-signal-amplifier
level; confirm the computed `(input − 50) × 4 + 50` (clamped to 0–100) sequence
agrees with the extracted expected-output trace, or that genuine disagreements
are listed with their time units.

**Acceptance Scenarios**:

1. **Given** a level with a published rule and an extracted test, **When** the
   cross-check runs, **Then** it reports per-time-unit agreement or lists each
   disagreeing time unit with both values.
2. **Given** a cross-check with disagreements above a small quantization
   tolerance, **When** the report is produced, **Then** the test is flagged as
   failing review rather than silently accepted.

---

### Edge Cases

- Screenshot does not show the verification panel (INFORMATION tab only, as in
  the sunzenshen set): classified as skipped, never emits a test.
- The rightmost time unit is cut off mid-unit by the panel edge: the partial
  unit is dropped so every emitted value covers a full time unit, and
  `cycleLimit` shrinks accordingly.
- A level has no mapping entry yet: skipped with a "needs mapping" reason so
  the report doubles as a to-do list.
- Two traces overlap or cross (possible on shared axes): if the extractor
  cannot follow a trace unambiguously for some time unit, it must fail that
  trace loudly rather than emit a guessed value.
- Brightness-based direction detection disagrees with the hand-authored
  mapping entry: the mapping entry is authoritative; the disagreement is
  surfaced as a warning for the human reviewer.
- An image deviates from the uniform 1920×1080 layout (different resolution,
  shifted panel): classified as failed with a layout reason; no partial output.
- XBus-only level: skipped as out of scope (per this feature's boundary), with
  the reason recorded for the future OCR/manual effort.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extractor MUST locate the verification panel within a
  screenshot and detect whether waveform traces are present, classifying
  panel-less screenshots as skipped.
- **FR-002**: The extractor MUST recover, for each simple-I/O trace, one value
  per visible time unit: high/low for binary traces, an integer in 0–100
  derived from trace height for analog traces.
- **FR-003**: The extractor MUST distinguish input traces from expected-output
  traces using relative trace brightness, while treating the per-level mapping
  entry as the authoritative source of direction and reporting any
  disagreement.
- **FR-004**: Port and stream names MUST come from a hand-authored per-level
  mapping config (level id, trace order, port names, direction, and the
  solution program the test runs against); the extractor MUST NOT attempt to
  read text from the image.
- **FR-005**: The extractor MUST emit test definitions conforming to the
  project's declarative test format (formatVersion 1.0): inputs as sample
  streams, expected outputs as expected-output streams, with port mappings
  taken from the mapping entry.
- **FR-006**: Every emitted test MUST bound `cycleLimit` to the timeline span
  actually visible in the source screenshot, dropping any partial trailing
  time unit.
- **FR-007**: Emitted tests MUST be marked as unreviewed (distinguishable from
  human-approved tests) until a person spot-checks them against the source
  screenshot; only reviewed tests may be promoted to the project's committed
  example/test corpus.
- **FR-008**: Each emitted test MUST record provenance: which screenshot it
  came from and which mapping entry produced it, so a reviewer can re-derive
  it.
- **FR-009**: XBus numeric value boxes MUST NOT be extracted automatically;
  levels or signals requiring them are reported as out of scope, and tests
  containing only a subset of a level's signals are flagged as partial.
- **FR-010**: A batch mode MUST process a directory of screenshots and produce
  a report classifying every screenshot as extracted, skipped (with reason),
  or failed (with reason), with no silent omissions.
- **FR-011**: When a trace cannot be followed unambiguously for any time unit,
  the extractor MUST fail that trace with a diagnostic instead of emitting a
  guessed value.
- **FR-012**: For levels whose input→output rule is published in the game
  manual, the tool MUST support cross-checking extracted expected outputs
  against outputs computed from the extracted inputs, reporting per-time-unit
  disagreements.
- **FR-013**: The extractor MUST operate only on the community screenshot
  images and hand-authored configs — it MUST NOT read, embed, or require any
  content from the game binary, and generated tests MUST NOT embed original
  game prose (descriptions may be referenced by local path only, per
  [local-original-assets.md](../../docs/local-original-assets.md)).

### Key Entities

- **Verification screenshot**: A community-published 1920×1080 game capture
  showing one sampled verification run for one level; the sole image input.
- **Level mapping entry**: Hand-authored record per level: level identifier,
  ordered trace descriptors (name, direction, binary/analog class), the
  solution program the generated test targets, and source screenshot paths.
- **Extracted trace**: The per-time-unit value sequence recovered for one
  signal, tagged with its class (binary/analog), direction, and any warnings.
- **Generated test definition**: A YAML document in the project's test format
  (one case per usable screenshot), carrying provenance and a review status of
  unreviewed until spot-checked.
- **Extraction report**: The batch-run output classifying every screenshot
  (extracted / skipped / failed, with reasons) and summarizing corpus coverage.
- **Published rule**: A level's input→output relationship as printed in the
  game manual's Supplemental Data section, re-stated by hand for cross-checks
  (never copied as prose into generated tests).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For the three priority binary levels (fake surveillance camera,
  diagnostic pulse generator, animated e-sports sign), extracted traces match
  an independent human transcription of the same screenshots for 100% of
  visible time units.
- **SC-002**: For every level with a published manual rule that has been
  extracted, computed and extracted expected outputs agree for at least 95% of
  time units, and every disagreement is listed in the cross-check report.
- **SC-003**: A batch run over all 76 shiawasenahikari screenshots completes
  in under 5 minutes on a developer machine and classifies 100% of the
  screenshots with no silent omissions.
- **SC-004**: At least 10 distinct campaign levels gain human-reviewed test
  definitions in the corpus (up from the current 0 levels with any
  game-derived behavioral test data).
- **SC-005**: Every generated test loads in the existing test runner without
  format errors on first attempt.
- **SC-006**: A reviewer can spot-check one generated test against its source
  screenshot in under 5 minutes using only the test file's provenance fields
  and the zoomed screenshot.

## Assumptions

- **Committing reconstructed tests is acceptable.** The screenshots are
  already public community content, and the project docs already endorse
  manual transcription of them; automated extraction produces the same kind of
  derived data. Original game *assets* (binary, prose, PDFs) remain local-only
  per [local-original-assets.md](../../docs/local-original-assets.md).
- **Generated tests target community solutions.** The test format requires a
  program; generated tests reference the corresponding community solution for
  the level. Whether a test *passes* also depends on simulator capabilities
  that are out of this feature's scope (e.g. `gen`/`@` execution, multi-chip
  boards — see [known-gaps.md](../../docs/known-gaps.md)); this feature's
  success is measured on extraction fidelity and format validity, not on
  simulator pass rates.
- **One screenshot is one sampled run.** Generated tests represent a single
  verification run, truncated to the visible timeline window — a valid test
  vector, not the level's full specification. For levels documented as having
  fixed repeating signals, the sampled run is the specification.
- **The panel's time unit maps to the test timeline's cycle unit.** The exact
  cycle mapping (time units vs. simulator cycles) is settled during planning;
  the spec requires only that per-time-unit fidelity is preserved and
  `cycleLimit` is bounded by the visible window.
- **The shiawasenahikari set stays the source of truth.** The sunzenshen
  screenshots (INFORMATION tab) are expected to be skipped; supporting other
  screenshot sources or resolutions is out of scope.
