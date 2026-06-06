# Shenzhen I/O Assembly for IntelliJ IDEA

IntelliJ plugin providing language support for Shenzhen I/O assembly. It reuses
the same `sio-langserver` language server as the VS Code extension (via
[LSP4IJ](https://github.com/redhat-developer/lsp4ij)) so the language smarts stay
in one place.

## Features

- `.asm` file type recognition
- **Diagnostics, hover, completion, go-to-definition** through `sio-langserver`
- **Run configurations** — the ▶ toolbar button runs the current `.asm` file; a
  single "Shenzhen I/O" config type lets you pick the command
  (assemble/simulate/test) and extra arguments. Opening an `.asm` file
  auto-creates a runnable config.
- Editor context-menu actions: **Assemble / Simulate / Run Tests** (via the `sio` CLI)

## Requirements

- IntelliJ IDEA 2024.3+ (built/tested against 2026.1)
- The [LSP4IJ](https://plugins.jetbrains.com/plugin/23257-lsp4ij) plugin
  (IntelliJ offers to install it automatically — it's a declared dependency)
- The language server built once: `dotnet build src/Sio.EditorSupport`
- `mono` on PATH (Linux/macOS) to run the .NET server

## Build

```bash
cd editor/intellij-shenzhen-io
gradle buildPlugin       # -> build/distributions/shenzhen-io-intellij-*.zip
gradle runIde            # launch a sandbox IDE with the plugin loaded
```

> The build targets the **locally installed** IDE at `/usr/share/idea`
> (see `local(...)` in `build.gradle.kts`) because build 261 is newer than any
> published download. Adjust that path for your install, or switch to
> `create("IC", "<version>")` once a matching artifact is published.

## Install

`Settings → Plugins → ⚙ → Install Plugin from Disk…` and pick the built zip.

## Configuration

The plugin locates executables relative to the open project (the repo root):

- `src/Sio.EditorSupport/bin/Debug/net472/sio-langserver.exe`
- `./sio` (CLI wrapper)

Override via environment variables when needed: `SIO_LANGSERVER`, `SIO_CLI`, `SIO_MONO`.
