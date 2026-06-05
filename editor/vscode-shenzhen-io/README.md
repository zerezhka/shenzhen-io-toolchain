# Shenzhen I/O Assembly for VS Code

VS Code language support for Shenzhen I/O assembly: syntax highlighting plus a
language server (diagnostics, hover, completion, go-to-definition) and commands
that drive the `sio` CLI.

## Features

- **Syntax highlighting** for all instructions, labels, registers, ports, numbers
- **Diagnostics** — unknown instructions, undefined `jmp` labels, parser errors
- **Hover** — instruction signatures/descriptions and register docs
- **Completion** — instructions and registers
- **Go-to-definition** for labels
- **Commands** — assemble / simulate / test the current file via the `sio` CLI
- Extended syntax: `const`, `alias`, `include`; `#` and `/* */` comments

## Requirements

The language server is a .NET (`net472`) executable. Build it once:

```bash
dotnet build src/Sio.EditorSupport
```

On Linux/macOS it runs under **mono** (configurable via `shenzhenIo.mono.path`).

## Installation (from source)

```bash
cd editor/vscode-shenzhen-io
npm install && npm run compile
cp -r . ~/.vscode/extensions/shenzhen-io-0.2.0
```

Reload VS Code. Opening any `.asm` file activates the extension.

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `shenzhenIo.languageServer.path` | _(auto)_ | Path to `sio-langserver.exe`. Auto-resolved from the workspace build if empty. |
| `shenzhenIo.mono.path` | `mono` | Mono runtime used to run the server on Linux/macOS. |
| `shenzhenIo.cli.path` | _(auto)_ | Path to the `sio` CLI. Falls back to the repo's `./sio` wrapper. |
| `shenzhenIo.trace.server` | `off` | LSP trace verbosity. |

## Commands

Available from the Command Palette and the editor context menu:

- **Shenzhen I/O: Assemble Current File** — writes `<file>.out.txt`
- **Shenzhen I/O: Simulate Current File** — runs with `--trace`
- **Shenzhen I/O: Run Tests (Current File)**
- **Shenzhen I/O: Restart Language Server**

## License

MIT
