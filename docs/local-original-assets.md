# Local original game assets (do not commit)

This repo can *optionally* consume **plain-text assets** and **signal dumps** extracted from a local Shenzhen I/O installation to make debugging and test authoring more convenient.

## What’s useful (examples)

- **Contract descriptions**: `originalgamefilessteam/Content/descriptions.en/*.txt`
- **In-game email/messages**: `originalgamefilessteam/Content/messages.en/*.txt`
- **Signal dumps** (example): `originalgamefilessteam/Content/nulyu.txt`

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


