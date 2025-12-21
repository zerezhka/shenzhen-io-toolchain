# Tasks: Shenzhen I/O CLI Toolchain

**Input**: Design documents from `/Users/zerezhka/Projects/shenzhen-simulator-io/specs/001-sio-toolchain/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), plus `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

## Format: `[ID] [P?] [Story] Description (with file path)`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US#]**: User story label from `spec.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize repo structure and C# solution scaffolding per `plan.md`.

- [X] T001 Create repository folders `src/`, `tests/`, `editor/`, `examples/`, `third_party/`
- [X] T002 Create solution file `src/Sio.sln` and initial project folders under `src/`
- [X] T003 [P] Create `src/Sio.Cli/Sio.Cli.csproj` and basic `src/Sio.Cli/Program.cs` (placeholder command router)
- [X] T004 [P] Create `src/Sio.Assembler/Sio.Assembler.csproj`
- [X] T005 [P] Create `src/Sio.Simulator/Sio.Simulator.csproj`
- [X] T006 [P] Create `src/Sio.TestRunner/Sio.TestRunner.csproj`
- [X] T007 [P] Create `src/Sio.EditorSupport/Sio.EditorSupport.csproj` (non-runtime assets helper)
- [X] T008 [P] Create test projects `tests/Sio.UnitTests/Sio.UnitTests.csproj` and `tests/Sio.IntegrationTests/Sio.IntegrationTests.csproj` (NUnit; Mono-compatible)
- [X] T009 Add root licensing files: `LICENSE` (MIT for original code) and `THIRD_PARTY_NOTICES.md`
- [X] T010 Add build/run docs scaffold `docs/` with placeholders: `docs/instruction-set.md`, `docs/timing-model.md`, `docs/test-format.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting contracts and shared primitives used by all user stories.

**⚠️ CRITICAL**: No user story work should start until this phase is done.

- [X] T011 Define shared CLI exit codes + error output conventions in `src/Sio.Cli/ExitCodes.cs`
- [X] T012 Define canonical port ID type (`p0..pN`) in `src/Sio.Simulator/Ports/PortId.cs`
- [X] T013 Define canonical trace record format in `src/Sio.Simulator/Trace/TraceEvent.cs`
- [X] T014 Define “signal stream” + timestamped events models in `src/Sio.TestRunner/Model/SignalStream.cs` and `src/Sio.TestRunner/Model/ExpectedOutput.cs`
- [X] T015 Implement deterministic text output helpers in `src/Sio.Cli/Output/ConsoleWriter.cs` (stable ordering, no timestamps unless requested)
- [X] T016 Implement JSON + YAML loading abstraction in `src/Sio.TestRunner/IO/TestDefinitionLoader.cs`
- [X] T017 Implement JSON schema validation for test definitions using `specs/001-sio-toolchain/contracts/test-definition.schema.json` in `src/Sio.TestRunner/IO/TestDefinitionValidator.cs`
- [X] T018 Implement signal dump adapter for `NAME.CH:RATE,SAMPLES...` in `src/Sio.TestRunner/IO/SignalDumpParser.cs` (local-only input)
- [X] T019 Add “do not embed copyrighted assets” guardrails in docs: update `docs/local-original-assets.md` reference from `docs/test-format.md`
- [X] T020 Add baseline NUnit tests for foundational IO and determinism helpers in `tests/Sio.UnitTests/Foundation/` (schema validation, signal dump parsing, stable output ordering)
- [X] T021 Pick and validate a Mono-compatible YAML parser (e.g., YamlDotNet) in `src/Sio.TestRunner/IO/` with tests in `tests/Sio.UnitTests/TestRunner/YamlLoaderTests.cs`

**Checkpoint**: Foundation ready (CLI output conventions + core models + test IO + signal dump adapter).

---

## Phase 3: User Story 1 - Assemble extended source into game-compatible assembly (Priority: P1) 🎯 MVP

**Goal**: `sio assemble` turns extended source (includes/const/alias/comments) into vanilla Shenzhen I/O assembly.

**Independent Test**: Run `sio assemble examples/us1/extended/main.asm -o /tmp/out.asm` and verify output contains no directives/comments and matches expected output file.

### Implementation (US1)

- [X] T022 [US1] Add third-party attribution for omaskery reference in `third_party/omaskery-shenzhen.io-assembler/README.md` and `third_party/omaskery-shenzhen.io-assembler/LICENSE` (copy MIT text, include upstream author/year)
- [X] T023 [US1] Add US1 preprocessor tests (include cycles, const/alias, comment stripping) in `tests/Sio.UnitTests/Assembler/PreprocessorTests.cs`
- [X] T024 [US1] Implement source file loader + include resolution in `src/Sio.Assembler/IO/SourceLoader.cs` (include paths, cycle detection)
- [X] T025 [US1] Implement block comment stripping in `src/Sio.Assembler/Preprocessor/CommentStripper.cs`
- [X] T026 [US1] Implement `const` handling in `src/Sio.Assembler/Preprocessor/ConstTable.cs`
- [X] T027 [US1] Implement `alias` handling in `src/Sio.Assembler/Preprocessor/AliasTable.cs`
- [X] T028 [US1] Implement preprocessing pipeline in `src/Sio.Assembler/Preprocessor/Preprocessor.cs` (includes → comments → const/alias substitution)
- [X] T029 [US1] Add tokenizer/parser unit tests in `tests/Sio.UnitTests/Assembler/ParserTests.cs` (labels, instructions, operands, error locations)
- [X] T030 [US1] Implement vanilla assembly tokenizer in `src/Sio.Assembler/Parse/Tokenizer.cs`
- [X] T031 [US1] Implement parser to an AST/IR in `src/Sio.Assembler/Parse/Parser.cs` (labels, instructions, operands)
- [X] T032 [US1] Implement renderer back to vanilla assembly in `src/Sio.Assembler/Emit/VanillaEmitter.cs`
- [X] T033 [US1] Implement assembler diagnostics with file+line+include chain in `src/Sio.Assembler/Diagnostics/Diagnostic.cs`
- [X] T034 [US1] Wire CLI command `assemble` in `src/Sio.Cli/Commands/AssembleCommand.cs`
- [X] T035 [US1] Add US1 example inputs/outputs under `examples/us1/extended/` and `examples/us1/expected/`

**Checkpoint**: US1 works end-to-end via CLI and produces deterministic, game-compatible output.

---

## Phase 4: User Story 2 - Run deterministic, cycle-accurate simulation for debugging (Priority: P2)

**Goal**: `sio simulate` runs a vanilla program on a single MCU with full instruction coverage, cycle accounting, ports `p0..pN`, and optional trace.

**Independent Test**: Run `sio simulate examples/us2/program.asm --cycles 1000 --trace` and verify deterministic output and trace summary across two runs.

### Implementation (US2)

- [X] T036 [US2] Define canonical instruction list (single source of truth) in `src/Sio.Simulator/Isa/InstructionSetManifest.cs`
- [X] T037 [US2] Generate/version the instruction list documentation in `docs/instruction-set.md` (derived from manifest; includes a visible version header)
- [X] T038 [US2] Add "full instruction coverage" gate test in `tests/Sio.UnitTests/Simulator/InstructionCoverageTests.cs` (every manifest opcode must have an implementation)
- [X] T039 [US2] Implement vanilla program loader into executable IR in `src/Sio.Simulator/Parse/ProgramParser.cs`
- [X] T040 [US2] Implement CPU state model (`acc`, `dat`, `pc`, flags if needed) in `src/Sio.Simulator/Cpu/CpuState.cs`
- [X] T041 [US2] Implement cycle counter + stop conditions in `src/Sio.Simulator/Runtime/CycleController.cs`
- [X] T042 [US2] Implement port IO model (inputs provided by streams, outputs recorded) in `src/Sio.Simulator/Ports/PortBus.cs`
- [X] T043 [US2] Implement trace emitter in `src/Sio.Simulator/Trace/Tracer.cs` (instruction, cycle, port events)
- [X] T044 [US2] Implement instruction decoder in `src/Sio.Simulator/Isa/Decoder.cs`
- [X] T045 [US2] Implement full instruction set execution handlers in `src/Sio.Simulator/Isa/Instructions/` (one file per instruction or grouped, but full coverage required) - **COMPLETE: All 15 instructions implemented**
- [X] T046 [US2] Implement sleep/timing behavior (`slp`) in `src/Sio.Simulator/Isa/Instructions/Slp.cs` with correct cycle effects
- [X] T047 [US2] Implement deterministic scheduling of read/write effects in `src/Sio.Simulator/Runtime/StepEngine.cs`
- [X] T048 [US2] Wire CLI command `simulate` in `src/Sio.Cli/Commands/SimulateCommand.cs`
- [X] T049 [US2] Add US2 example program(s) under `examples/us2/` with deterministic expected trace summaries in `examples/us2/expected/`
- [X] T050 [US2] Document timing model details in `docs/timing-model.md` with "implemented vs pending" checklist tied to the manifest

**Checkpoint**: US2 runs deterministically with trace; no “unsupported instruction” failures for valid programs (per spec).

---

## Phase 5: User Story 3 - Validate programs with machine-readable test cases (Priority: P3)

**Goal**: `sio test` runs YAML/JSON suites with cycle limits and cycle-exact output validation (order-only optional).

**Independent Test**: Run `sio test examples/us3/tests.yaml` and see pass/fail with clear diffs and non-zero exit code on failures.

### Implementation (US3)

- [X] T051 [US3] Add test runner model/validation unit tests in `tests/Sio.UnitTests/TestRunner/TestDefinitionModelTests.cs` (schema → model mapping, required fields)
- [X] T052 [US3] Implement in-memory test model mapping to schema in `src/Sio.TestRunner/Model/TestSuite.cs` and `src/Sio.TestRunner/Model/TestCase.cs`
- [X] T053 [US3] Implement port mapping resolver (`p0..pN` ↔ stream ids) in `src/Sio.TestRunner/Runtime/PortMapping.cs`
- [X] T054 [US3] Implement simulation harness wrapper in `src/Sio.TestRunner/Runtime/SimulatorHarness.cs` (invokes `Sio.Simulator` with streams and cycle limit)
- [X] T055 [US3] Add matcher unit tests for cycle-exact and order-only in `tests/Sio.UnitTests/TestRunner/MatcherTests.cs`
- [X] T056 [US3] Implement cycle-exact output matcher in `src/Sio.TestRunner/Assert/CycleExactMatcher.cs`
- [X] T057 [US3] Implement optional order-only matcher in `src/Sio.TestRunner/Assert/OrderOnlyMatcher.cs`
- [X] T058 [US3] Implement "LeetCode-like" failure diff rendering in `src/Sio.TestRunner/Output/DiffRenderer.cs` (expected vs actual, include cycles for cycle-exact)
- [X] T059 [US3] Implement metadata refs loader (local-only text assets) in `src/Sio.TestRunner/IO/MetadataLoader.cs` (do not embed content into outputs unless explicitly requested)
- [X] T060 [US3] Wire CLI command `test` in `src/Sio.Cli/Commands/TestCommand.cs`
- [X] T061 [US3] Add at least 3 runnable example test cases under `examples/us3/` (YAML/JSON), including one cycle-exact case and one order-only case
- [X] T062 [US3] Update `docs/test-format.md` to describe: stream inputs, port mappings, cycle-exact outputs, order-only option, and metadata refs

**Checkpoint**: US3 delivers deterministic pass/fail, clear diffs, and proper exit codes.

---

## Phase 6: User Story 4 - Get syntax highlighting in VS Code (Priority: P4)

**Goal**: Provide optional VS Code highlighting for `.asm` including extended directives and block comments.

**Independent Test**: Install the VS Code package and verify `.asm` highlights instructions/labels/numbers/comments and `const/alias/include` directives.

### Implementation (US4)

- [X] T063 [US4] Create VS Code extension/package skeleton under `editor/vscode-shenzhen-io/` (`package.json`, `README.md`)
- [X] T064 [US4] Add TextMate grammar for vanilla assembly in `editor/vscode-shenzhen-io/syntaxes/shenzhen-io.tmLanguage.json`
- [X] T065 [US4] Extend grammar for `const`, `alias`, `include`, and block comments in `editor/vscode-shenzhen-io/syntaxes/shenzhen-io.tmLanguage.json`
- [X] T066 [US4] Add language configuration (comment toggles, brackets) in `editor/vscode-shenzhen-io/language-configuration.json`
- [X] T067 [US4] Document installation steps in `docs/editor-vscode.md` and link from root `README.MD`

**Checkpoint**: Users can enable highlighting in VS Code in <5 minutes (SC-005).

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation completeness, packaging, and guardrails.

- [ ] T068 [P] Add end-to-end smoke scripts for quickstart flows in `scripts/smoke/` (assemble/simulate/test)
- [ ] T069 Add deterministic output snapshots for examples under `examples/**/expected/` and document how to regenerate them in `docs/`
- [ ] T070 Add license/attribution verification checklist in `docs/licensing.md` (what must be preserved when vendoring third-party code)
- [ ] T071 Ensure `originalgamefilessteam/` remains excluded and documented (verify `.gitignore`, `docs/local-original-assets.md`, and `README.MD`)
- [ ] T072 Add CI matrix workflow in `.github/workflows/ci.yml` (Windows/macOS/Linux: build + unit tests + smoke scripts)
- [ ] T073 Add “no Unity / no game runtime deps” guard script in `scripts/ci/check-no-game-deps.sh` and run it from `.github/workflows/ci.yml`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** → blocks Phase 2+
- **Phase 2 (Foundational)** → blocks all user stories
- **US1** can start after Phase 2 and unblocks realistic workflows for US2/US3 examples
- **US2** can start after Phase 2 (can run in parallel with US1 once foundation is done)
- **US3** depends on US2 runtime integration (needs simulator harness), but schema/model work can start after Phase 2
- **US4** can be done in parallel after Phase 1 (but is lower priority)

### Parallel Opportunities

- Phase 1 tasks T003–T007 are parallelizable scaffolding tasks.
- Within US1, tasks can be partially parallelized (preprocessor vs tokenizer/parser/emitter) if interfaces are agreed first.
- US4 tasks can run in parallel with US1–US3 after Phase 1.


