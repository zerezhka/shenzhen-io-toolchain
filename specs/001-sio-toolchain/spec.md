# Feature Specification: Shenzhen I/O CLI Toolchain

**Feature Branch**: `001-sio-toolchain`  
**Created**: 2025-12-21  
**Status**: Draft  
**Input**: User description: "see @ABOUT.mD AND @README.MD and make some spec based on them. they can be inconsistent, you free to ask on conFfusions, thats an llm-generated drafts"

## Clarifications

### Session 2025-12-21

- Q: Simulator coverage target (MVP) → A: Full instruction set coverage is required for the target Shenzhen I/O MCU(s).
- Q: Licensing + attribution policy (when using third-party code) → A: The repo is MIT for original code; any third-party code included keeps its original license and required attribution/NOTICE files.
- Q: Simulation scope (what do we simulate in MVP?) → A: Start with single-MCU simulation; expand to multi-MCU later (out of MVP).
- Q: Test pass/fail semantics (timing strictness) → A: Cycle-exact matching is required; an optional order-only mode is allowed for simpler tests.
- Q: What “ports” mean in MVP simulation → A: Support `p0..pN` style ports (single MCU), with tests mapping input/output streams to specific ports.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Assemble extended source into game-compatible assembly (Priority: P1)

As a Shenzhen I/O player who wants to develop outside the game editor, I want to write readable multi-file source with rich comments and symbols, and produce plain Shenzhen I/O assembly output that can be used in the game without manual cleanup.

**Why this priority**: This is the foundation of the workflow; without assembly/preprocessing, users cannot transition from “IDE-friendly” source to game-compatible code.

**Independent Test**: Can be fully tested by running a single command on a sample project containing `const`, `alias`, `include`, and comments, and verifying the produced output contains only vanilla Shenzhen I/O assembly syntax and matches expected text.

**Acceptance Scenarios**:

1. **Given** a source project that uses `include` to split code across multiple files, **When** the user runs `sio assemble` with an input file and an output path, **Then** the output is created and contains a single, flattened vanilla assembly program with includes resolved.
2. **Given** a source file containing block comments and long lines, **When** the user assembles it, **Then** the output contains no comments and is not rejected due to line length.
3. **Given** a source file containing `const` and `alias` declarations, **When** the user assembles it, **Then** all constants and aliases are resolved to the correct literal values / register or port references in the output.
4. **Given** a source project that contains an invalid directive or undefined symbol, **When** the user assembles it, **Then** the command fails with a clear error message and a non-zero exit code.

---

### User Story 2 - Run deterministic, cycle-accurate simulation for debugging (Priority: P2)

As a Shenzhen I/O player, I want to run my assembled program in a headless simulator that reflects the MCU timing model so I can debug behavior (including sleeps) and inspect traces without launching the game.

**Why this priority**: Simulation enables fast iteration and debugging for timing-sensitive programs that are painful to validate inside the game UI.

**Independent Test**: Can be fully tested by running a known program with a fixed input stream and verifying the simulator produces an expected step/cycle trace and the same outputs across repeated runs.

**Acceptance Scenarios**:

1. **Given** an assembled program and a fixed test input sequence, **When** the user runs `sio simulate` with tracing enabled, **Then** the simulator emits a deterministic trace of instruction/cycle progression and observed I/O interactions.
2. **Given** a program that uses sleep/timing behavior, **When** it is simulated with a cycle limit, **Then** the simulator advances time correctly and stops when the limit is reached.
3. **Given** a program that reads and writes ports, **When** it is simulated, **Then** port I/O behavior is reflected deterministically in outputs and trace.
4. **Given** a program that enters an infinite loop, **When** it is simulated with a cycle limit, **Then** the simulator terminates the run and reports that the limit was reached (non-crashing, clear status).

---

### User Story 3 - Validate programs with machine-readable test cases (Priority: P3)

As a Shenzhen I/O player (or a CI user), I want to define test cases in a structured file and run them from the CLI to automatically verify that my program produces the expected output sequences within a cycle limit.

**Why this priority**: Automated tests prevent regressions and enable repeatable validation outside the game.

**Independent Test**: Can be fully tested by running `sio test` on an example test definition and checking that it reports pass/fail per case and returns an appropriate exit code.

**Acceptance Scenarios**:

1. **Given** a test definition file describing input signals, expected outputs, and a cycle limit, **When** the user runs `sio test`, **Then** each test case is executed and reported as pass/fail with reasons for failures.
2. **Given** a failing test where outputs differ, **When** the test runner finishes, **Then** it returns a non-zero exit code and provides enough context to reproduce the mismatch (expected vs actual).
3. **Given** multiple test cases in one file, **When** the user runs the test runner, **Then** all cases are executed deterministically and results are summarized.
4. **Given** a test that requires timing correctness, **When** it is executed, **Then** output checks are performed against expected cycle timestamps (not just value order).

---

### User Story 4 - Get syntax highlighting in VS Code (Priority: P4)

As a Shenzhen I/O player writing assembly outside the game, I want syntax highlighting in my editor (at minimum VS Code) so code is easier to read, navigate, and review.

**Why this priority**: It improves day-to-day usability but is not required for assembling/simulating/testing correctness.

**Independent Test**: Can be tested by installing the provided editor support and verifying `.asm` files highlight core syntax elements and comment styles.

**Acceptance Scenarios**:

1. **Given** a `.asm` file containing instructions, labels, numbers, and comments, **When** it is opened in VS Code with the project’s editor support installed, **Then** core tokens (instructions/labels/comments/numbers) are highlighted in a consistent way.
2. **Given** a file using the project’s extended syntax (`const`, `alias`, `include`, block comments), **When** it is opened, **Then** those directives and comment forms are highlighted and do not break highlighting for the rest of the file.

---

### Edge Cases

- A source file includes itself (directly or indirectly): assembler detects the include cycle and fails with a clear error.
- A program exceeds any in-game MCU line limits: assembler still produces valid vanilla assembly output; users can choose how to deploy it in-game (tool does not enforce in-game line limits).
- Unknown instruction / malformed statement: assembler fails with location info (file + line) and actionable message.
- Simulator input stream ends early: simulator behaves deterministically (no undefined reads) and reports the condition according to the test definition.
- Tests that hit the cycle limit without producing enough outputs: reported as failure with clear reason.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a CLI command to assemble/preprocess extended Shenzhen I/O source into vanilla Shenzhen I/O assembly output.
- **FR-002**: The assembler MUST support extended syntax features: block comments, `const` definitions, `alias` definitions, and `include` directives.
- **FR-003**: The assembler MUST resolve `include` directives into a single output program and MUST detect and reject include cycles.
- **FR-004**: The assembler MUST produce output that contains only vanilla Shenzhen I/O assembly syntax (no extended directives or comments).
- **FR-005**: The simulator MUST execute assembled programs headlessly and deterministically for the same program + inputs.
- **FR-006**: The simulator MUST model instruction timing sufficiently to support cycle-based limits and sleep/timing behavior.
- **FR-007**: The simulator MUST support core single-MCU concepts: registers and ports.
- **FR-007a**: The simulator MUST expose ports using `p0..pN` naming (or an equivalent canonical representation) so tests can target specific pins.
- **FR-008**: System MUST provide a CLI command to simulate a program with an option to emit a human-readable execution trace for debugging.
- **FR-009**: System MUST provide a CLI command to run tests defined in either YAML or JSON.
- **FR-010**: The test definition format MUST support: input signal sequences, expected output signal sequences, and a cycle limit per test case.
- **FR-010a**: Expected output signals MUST be expressible with cycle timestamps to support cycle-exact validation.
- **FR-010b**: Test definitions MUST support mapping named input/output streams to specific MCU ports (e.g., `p0`, `p1`, …) for simulation and validation.
- **FR-011**: The test runner MUST provide deterministic results and MUST return a non-zero exit code if any test fails.
- **FR-011a**: The test runner MAY support an order-only output comparison mode for tests where timing is not relevant.
- **FR-012**: System MUST support importing “level metadata” text assets (e.g., `description.en`, `messages.en`) as plain text inputs for test runs, without embedding copyrighted assets in the repository.
- **FR-013**: The toolchain MUST be usable without a GUI (CLI-first workflow).
- **FR-014**: The simulator MUST support the full instruction set of the target Shenzhen I/O MCU(s) such that any valid assembled program can be executed without “unsupported instruction” failures.
- **FR-015**: System MUST provide optional editor support for syntax highlighting of Shenzhen I/O assembly (including the project’s extended syntax).
- **FR-016**: The repository MUST include instructions for enabling syntax highlighting in VS Code (either via a bundled extension or a documented install step), without making VS Code a runtime dependency of the CLI tools.

### Non-Functional Requirements

- **NFR-001**: Toolchain MUST run on Windows, macOS, and Linux.
- **NFR-002**: Toolchain MUST not require Unity or any game runtime to execute.
- **NFR-003**: Outputs (assembled text, simulator traces, test results) MUST be reproducible for the same inputs (deterministic runs).
- **NFR-004**: The project MUST be open-source and licensed under MIT for original code.
- **NFR-005**: If third-party code is included, the repository MUST retain the original third-party license(s) and required attribution/NOTICE materials.

### Assumptions & Out of Scope

- The toolchain focuses on enabling development and validation outside the game; it does not attempt to ship or embed game assets.
- IDE/editor integration (e.g., syntax highlighting extensions) is considered optional and not required for MVP; users can use any editor.
- For convenience, the toolchain MAY support importing “signal dump” text files in the same simple line-based format used by community/game-adjacent workflows (e.g., `NAME.CH:RATE,SAMPLES...`), but this is strictly for local user-supplied data and is not required to ship with the repository.
- Multi-MCU board simulation and inter-node message passing are explicitly out of MVP; they are a planned follow-up once single-MCU parity is established.

### Key Entities *(include if feature involves data)*

- **Source Project**: A set of text files representing extended Shenzhen I/O source, including included files and symbol definitions.
- **Assembled Program**: The generated vanilla assembly text output suitable for use in other tools and for manual use in the game.
- **Simulation Run**: A deterministic execution of an assembled program with a defined input stream and cycle limit.
- **Execution Trace**: A human-readable record of simulation steps/cycles, including I/O interactions and relevant state changes.
- **Test Definition**: A YAML/JSON document containing one or more test cases and references to any required plain-text metadata assets.
- **Test Case**: A single case containing inputs, expected outputs, and a cycle limit (and optional descriptive metadata).
- **Signal Dump (Optional)**: A user-supplied plain text file containing named sampled input streams, used to populate test inputs without manual transcription.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can complete the core workflow (assemble → simulate → test) using no more than 3 CLI commands and obtain a clear pass/fail outcome.
- **SC-002**: For a fixed program + fixed test inputs, repeated simulator runs produce identical outputs and identical trace summaries (deterministic behavior).
- **SC-003**: The repository includes at least 3 example test cases that can be executed by a new user and pass without modification.
- **SC-004**: When assembly or tests fail, the tool reports an actionable error that includes at least: what failed, where it failed (file/line when applicable), and how to proceed (next-step hint).
- **SC-005**: A new user can enable syntax highlighting for `.asm` files in VS Code in under 5 minutes by following repository documentation.
