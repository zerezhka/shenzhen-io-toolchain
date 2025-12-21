# CLI Usage Guide

## Running the CLI

The CLI executable is located at:
```
src/Sio.Cli/bin/Debug/net472/sio.exe
```

### On macOS/Linux (with Mono)

Run with `mono`:

```bash
mono src/Sio.Cli/bin/Debug/net472/sio.exe <command> [args...]
```

### Quick Setup (Optional)

You can make the wrapper script executable and add it to your PATH:

```bash
# Make wrapper executable
chmod +x sio

# Add to PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$PATH:/Users/zerezhka/Projects/shenzhen-simulator-io"

# Or create a symlink in a directory already in PATH
ln -s /Users/zerezhka/Projects/shenzhen-simulator-io/sio ~/bin/sio
```

Then you can run:
```bash
sio <command> [args...]
```

## Commands

### Assemble

Assemble extended assembly syntax to vanilla assembly:

```bash
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm -o output.asm
```

### Simulate

Simulate a program:

```bash
mono src/Sio.Cli/bin/Debug/net472/sio.exe simulate examples/us2/program.asm --cycles 100 --trace
```

## Examples

All examples are in the `examples/` directory:
- `examples/us1/` - Assembler examples (extended syntax)
- `examples/us2/` - Simulator examples
- `examples/us3/` - Test runner examples

For detailed testing instructions including the test runner, see `TESTING.md`.

### Full Workflow

```bash
# 1. Assemble extended syntax
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm -o main.asm

# 2. Simulate with trace
mono src/Sio.Cli/bin/Debug/net472/sio.exe simulate main.asm --trace

# 3. Run tests
mono src/Sio.Cli/bin/Debug/net472/sio.exe test examples/us3/test-order-only.yaml
```

