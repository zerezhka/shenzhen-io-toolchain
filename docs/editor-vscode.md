# VS Code Syntax Highlighting for Shenzhen I/O

This extension provides syntax highlighting for Shenzhen I/O assembly files (`.asm`).

## Installation

### Option 1: Copy Extension Folder (Recommended for Development)

1. Copy the extension directory to your VS Code extensions folder:

   **macOS/Linux:**
   ```bash
   cp -r editor/vscode-shenzhen-io ~/.vscode/extensions/shenzhen-io-0.1.0
   ```

   **Windows:**
   ```powershell
   xcopy /E /I editor\vscode-shenzhen-io %USERPROFILE%\.vscode\extensions\shenzhen-io-0.1.0
   ```

2. Reload VS Code:
   - Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
   - Type "Developer: Reload Window"
   - Press Enter

### Option 2: Package and Install (For Distribution)

1. Package the extension:
   ```bash
   cd editor/vscode-shenzhen-io
   vsce package
   ```

2. Install the `.vsix` file:
   - Press `Cmd+Shift+P` / `Ctrl+Shift+P`
   - Type "Extensions: Install from VSIX..."
   - Select the generated `.vsix` file

## Features

- ✅ Syntax highlighting for all Shenzhen I/O instructions
- ✅ Register highlighting (`acc`, `dat`, `null`)
- ✅ Port highlighting (`p0`-`p9`, `x0`-`x9`)
- ✅ Label highlighting
- ✅ Number highlighting
- ✅ Comment support (`#` line comments, `/* */` block comments)
- ✅ Extended syntax support (`const`, `alias`, `include` directives)
- ✅ Conditional execution prefix highlighting (`+`, `-`)

## Usage

Once installed, any file with `.asm` extension will automatically use Shenzhen I/O syntax highlighting.

You can also manually set the language:
- Press `Cmd+Shift+P` / `Ctrl+Shift+P`
- Type "Change Language Mode"
- Select "Shenzhen I/O"

## Supported Syntax Elements

### Instructions
All 15 Shenzhen I/O instructions are highlighted:
- Basic: `nop`, `mov`, `jmp`, `slp`, `slx`
- Test: `teq`, `tgt`, `tlt`, `tcp`
- Arithmetic: `add`, `sub`, `mul`, `not`, `dgt`, `dst`

### Registers
- `acc` - Accumulator
- `dat` - Data register (MC6000 only)
- `null` - Null register

### Ports
- `p0`-`p9` - Simple I/O pins
- `x0`-`x9` - XBus pins

### Labels
- `label:` - Jump targets

### Comments
- `# line comment` - Line comments
- `/* block comment */` - Block comments

### Extended Directives
- `const NAME VALUE` - Constant definition
- `alias NAME VALUE` - Alias definition
- `include FILE.ASM` - Include directive

### Conditional Execution
- `+ instruction` - Execute if test enabled
- `- instruction` - Execute if test disabled

## Troubleshooting

If highlighting doesn't work:
1. Make sure the file has `.asm` extension
2. Reload VS Code window
3. Check that the extension is enabled in Extensions view
4. Manually set language mode to "Shenzhen I/O"

## Development

The extension uses TextMate grammar format. To modify syntax highlighting, edit:
- `editor/vscode-shenzhen-io/syntaxes/shenzhen-io.tmLanguage.json`

Language configuration (comments, brackets) is in:
- `editor/vscode-shenzhen-io/language-configuration.json`

