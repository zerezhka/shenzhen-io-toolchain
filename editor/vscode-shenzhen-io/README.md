# Shenzhen I/O Assembly Syntax Highlighting

VS Code extension providing syntax highlighting for Shenzhen I/O assembly language.

## Features

- Syntax highlighting for all Shenzhen I/O instructions
- Support for labels, registers, ports, and numbers
- Extended syntax support: `const`, `alias`, `include` directives
- Block comment support (`/* */`)
- Line comment support (`#`)

## Installation

### From Source

1. Copy this directory to your VS Code extensions folder:
   ```bash
   cp -r editor/vscode-shenzhen-io ~/.vscode/extensions/shenzhen-io-0.1.0
   ```

2. Reload VS Code

### Manual Installation

1. Open VS Code
2. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
3. Type "Extensions: Install from VSIX..." (if you have a packaged version)
4. Or copy the extension folder to your extensions directory

## Usage

Files with `.asm` extension will automatically use Shenzhen I/O syntax highlighting.

## Supported Syntax

- **Instructions**: `mov`, `add`, `sub`, `mul`, `not`, `dgt`, `dst`, `jmp`, `slp`, `slx`, `teq`, `tgt`, `tlt`, `tcp`, `nop`
- **Registers**: `acc`, `dat`, `null`
- **Ports**: `p0`-`p9`, `x0`-`x9`
- **Labels**: `label:`
- **Comments**: `# line comment` and `/* block comment */`
- **Extended directives**: `const`, `alias`, `include`
- **Conditional execution**: `+` and `-` prefixes

## License

MIT

