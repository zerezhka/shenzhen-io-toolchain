# Local original game assets (do not commit)

This repo can *optionally* consume **plain-text assets** and **signal dumps** extracted from a local Shenzhen I/O installation to make debugging and test authoring more convenient.

## What’s useful (examples)

- **Contract descriptions**: `originalgamefilessteam/Content/descriptions.en/*.txt`
- **In-game email/messages**: `originalgamefilessteam/Content/messages.en/*.txt`
- **Signal dumps** (example): `originalgamefilessteam/Content/nulyu.txt`
- **Original reference manuals**: `originalgamefilessteam/Content/SHENZHEN IO Manual (English).pdf`
  and `SHENZHEN IO Manual (Chinese).pdf` — the source of
  [`docs/SHENZHEN IO Manual (English).md`](SHENZHEN%20IO%20Manual%20%28English%29.md).
  Both manuals document the same 15 instructions; despite the in-game lore,
  `gen` and `@` appear in **neither** PDF — their only primary source is the
  in-game email `Content/messages.en/undocumented-instruction.txt`
  (see [undocumented-instructions.md](undocumented-instructions.md)).
  The English manual's **Supplemental Data** section also publishes exact
  behavioral specs for ~10 levels whose descriptions point to it (e.g. the
  amplifier formula, the unknown-device x/y→power map) — usable as a
  clean-room oracle for test authoring
  (see [community-test-data.md](community-test-data.md)).

These are helpful for:

- Building realistic test fixtures (inputs/expected outputs)
- Attaching human-readable metadata to tests (title/description/messages) without copying text into the repo

## Important

- Keep these files **local-only**.
- The repository should **not** embed or redistribute original game content.
- `.gitignore` is expected to exclude `originalgamefilessteam/` to prevent accidental commits.

## Suggested workflow

- Point the test runner at a local directory containing `descriptions.en/` and `messages.en/`.
- Keep test definitions in `examples/` or `specs/` and reference metadata files by relative path (without copying their content).


