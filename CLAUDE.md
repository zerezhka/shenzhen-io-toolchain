# shenzhen-simulator-io Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-06-12

## Active Technologies

- Python 3 (system `python3`, ≥3.9) + Pillow (PIL) only — already available on this machine; no OpenCV, no OCR (002-pixel-extractor)

## Project Structure

```text
src/                  # C# toolchain (Sio.Assembler, Sio.Simulator, Sio.TestRunner, Sio.Cli)
zig/                  # Zig rewrite (parser/emitter; simulator in progress by the user)
tools/pixel-extractor/  # Python tooling: screenshot → YAML test extraction (002)
examples/             # Test definitions; examples/extracted/ is machine-generated
specs/                # Feature specs/plans (speckit)
docs/                 # Project documentation
third_party/          # Vendored community solutions and screenshots (read-only)
```

## Commands

- `python3 tools/pixel-extractor/extract.py <level>` — extract one level's tests
- `python3 -m pytest tools/pixel-extractor/tests/` — extractor golden tests
- `dotnet build src/Sio.sln` — build C# toolchain

## Code Style

Python 3 (system `python3`, ≥3.9): standard conventions; Pillow only, no new dependencies.

## Recent Changes

- 002-pixel-extractor: Added Python 3 (system `python3`, ≥3.9) + Pillow (PIL) only — already available on this machine; no OpenCV, no OCR

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
