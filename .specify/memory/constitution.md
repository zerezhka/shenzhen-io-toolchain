# shenzhen-simulator-io Constitution

## Core Principles

### I. CLI-First, Headless Toolchain

- The primary interface MUST be a **CLI**.
- All core features MUST be usable without any GUI.
- CLI behavior MUST be scriptable: stable exit codes, stdout for results, stderr for errors.

### II. Determinism & Reproducibility

- For the same inputs, the assembler, simulator, and test runner MUST produce identical outputs across repeated runs.
- Any non-deterministic behavior MUST be treated as a defect unless explicitly documented and gated behind an opt-in flag.

### III. Compatibility & Portability (Cross-Platform)

- The project MUST run on Windows, macOS, and Linux.
- The runtime target MUST remain compatible with **Mono** (avoid modern-only runtime features and dependencies).

### IV. Asset Safety (No Copyrighted Game Content)

- The repository MUST NOT embed or redistribute original Shenzhen I/O game assets.
- Local-only assets (e.g., extracted `messages.*`, `descriptions.*`, signal dumps) MAY be supported as inputs, but MUST be excluded from version control by default.

### V. Licensing & Attribution (Non-Negotiable)

- Original code in this repository MUST be licensed under **MIT**.
- If third-party code is included, it MUST retain its original license and required attribution/NOTICE materials.
- The project MUST NOT relicense third-party code under MIT unless the upstream license explicitly permits and the required notices are preserved.

### VI. Specification-Driven Development

- `specs/<feature>/spec.md` is the source of truth for user-facing behavior and acceptance criteria.
- `specs/<feature>/plan.md` and `tasks.md` MUST remain consistent with the spec.
- When a conflict exists, the team MUST either:
  - update plan/tasks to match the spec, or
  - explicitly revise the spec (with rationale).

### VII. Quality Gates (Tests & Validation)

- Any change that affects parsing, simulation semantics, or test evaluation MUST add or update automated tests.
- The test runner MUST support deterministic pass/fail and non-zero exit on failures.
- Contract/schema changes MUST be accompanied by updated examples and schema validation.

## Additional Constraints

### Scope Discipline

- MVP scope MUST follow the current spec’s clarifications (e.g., single-MCU simulation in MVP unless the spec changes).
- “Full instruction coverage” MUST be backed by an explicit, versioned instruction list in docs (so it is testable).

### Dependency Discipline

- Avoid unnecessary dependencies; prefer small, well-audited libraries compatible with Mono.
- Dependencies requiring Unity or the game runtime are prohibited.

## Development Workflow & Review

- Every PR MUST check:
  - no copyrighted assets added
  - licensing/attribution compliance for any included third-party code
  - deterministic behavior (where applicable)
  - cross-platform build/run feasibility (at least via CI or documented local verification)

## Governance

- This constitution supersedes other workflow conventions and templates in the repo.
- Amendments MUST include:
  - a short rationale
  - the affected gates/principles
  - any migration notes for existing specs/plans/tasks

**Version**: 1.0.0 | **Ratified**: 2025-12-21 | **Last Amended**: 2025-12-21
