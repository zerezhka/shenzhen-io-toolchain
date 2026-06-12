# Extracted level tests (machine-generated)

Test definitions reconstructed from community verification-tab screenshots by
[`tools/pixel-extractor/`](../../tools/pixel-extractor/) — see
[`specs/002-pixel-extractor/`](../../specs/002-pixel-extractor/) and
[`docs/community-test-data.md`](../../docs/community-test-data.md).

Each file is **one sampled verification run** of one game level, truncated to
the timeline window visible in the source screenshot. Provenance (source
screenshot + mapping config) is in the comment header of every file.

## Conventions

- `formatVersion: "2.0"` with `saveFile:` pointing at the community solution
  and `level.<terminal>` I/O binding — see
  [`docs/test-format.md`](../../docs/test-format.md).
- One cycle = one verification-panel time unit (sleep unit).
- `reviewStatus: unreviewed` until a human has spot-checked the values against
  the source screenshot (e.g. with
  `python3 tools/pixel-extractor/extract.py <level> --dump` next to a zoomed
  crop). Flip to `reviewed` only after that check.

## Regenerating

```bash
python3 tools/pixel-extractor/extract.py 001-fake-surveillance-camera
python3 tools/pixel-extractor/extract.py --batch     # everything with a mapping config
```

Do not hand-edit values — fix the mapping config or the extractor and
regenerate, or the provenance header becomes a lie.
