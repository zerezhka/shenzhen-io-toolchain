# Testing Guide

This document describes how to test the Shenzhen I/O CLI toolchain implementation.

## Prerequisites

- Mono runtime (for .NET Framework 4.7.2 compatibility)
- MSBuild (usually comes with Mono)

## Building the Project

### Step 1: Restore NuGet packages
```bash
cd src
msbuild Sio.sln /t:Restore
```

Or if you have `dotnet` CLI:
```bash
cd src
dotnet restore
```

### Step 2: Build all projects:
```bash
cd src
msbuild Sio.sln /t:Build
```

Or with dotnet:
```bash
cd src
dotnet build
```

### Build specific project:
```bash
cd src
msbuild Sio.Cli/Sio.Cli.csproj /t:Build
```

## Running Unit Tests

### Run all tests:
```bash
cd tests/Sio.UnitTests
msbuild Sio.UnitTests.csproj /t:Build
# Then run with NUnit console runner (if installed)
# nunit3-console bin/Debug/net472/Sio.UnitTests.dll
```

### Run tests with dotnet (if available):
```bash
cd tests/Sio.UnitTests
dotnet test
```

### Quick test run (all tests):
```bash
# From project root
cd tests/Sio.UnitTests
dotnet test --verbosity normal
```

## Testing the CLI Command

### Build the CLI:
```bash
cd src
msbuild Sio.Cli/Sio.Cli.csproj /t:Build
```

### Test the Assembler:
```bash
# Basic usage
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm

# With output file
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm -o output.asm

# View the output
cat output.asm
```

### Test the Simulator:
```bash
# Run simulation with trace output
mono src/Sio.Cli/bin/Debug/net472/sio.exe simulate examples/us2/program.asm --cycles 100 --trace

# Specify cycle limit
mono src/Sio.Cli/bin/Debug/net472/sio.exe simulate examples/us2/program.asm --cycles 50
```

### Test the Test Runner:
```bash
# Run test cases (cycle-exact validation)
mono src/Sio.Cli/bin/Debug/net472/sio.exe test examples/us3/test-cycle-exact.yaml

# Run test cases (order-only validation)
mono src/Sio.Cli/bin/Debug/net472/sio.exe test examples/us3/test-order-only.yaml

# Run test with inputs
mono src/Sio.Cli/bin/Debug/net472/sio.exe test examples/us3/test-with-inputs.yaml

# Run multiple test files
mono src/Sio.Cli/bin/Debug/net472/sio.exe test examples/us3/*.yaml
```

### Test with example files:
```bash
# Test the example from US1
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm -o /tmp/test-output.asm

# Compare with expected output
diff /tmp/test-output.asm examples/us1/expected/main.asm
```

## Manual Testing Scenarios

### 1. Test Include Resolution
Create a test file with includes:
```bash
echo "include helpers.asm" > /tmp/test.asm
echo "mov acc 1" >> /tmp/test.asm
echo "mov acc 2" > /tmp/helpers.asm
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble /tmp/test.asm
```

### 2. Test Const/Alias Resolution
```bash
cat > /tmp/test.asm << 'EOF'
const VALUE 42
alias PORT p0
mov acc VALUE
mov PORT acc
EOF
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble /tmp/test.asm
```

### 3. Test Comment Stripping
```bash
cat > /tmp/test.asm << 'EOF'
; line comment
mov acc 1
/* block
comment */
mov dat 2
EOF
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble /tmp/test.asm
```

### 4. Test Error Handling
```bash
# Test missing file
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble /nonexistent.asm

# Test include cycle (should fail)
echo "include file2.asm" > /tmp/file1.asm
echo "include file1.asm" > /tmp/file2.asm
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble /tmp/file1.asm
```

## Expected Test Results

### Unit Tests Should Pass:
- ✅ PreprocessorTests: Include resolution, cycle detection, comment stripping, const/alias
- ✅ ParserTests: Tokenization, parsing, label handling, instruction parsing

### CLI Should:
- ✅ Resolve includes correctly
- ✅ Strip all comments
- ✅ Resolve const and alias definitions
- ✅ Produce clean vanilla assembly output
- ✅ Handle errors gracefully with clear messages

## Troubleshooting

### Build Errors:
- Ensure Mono is properly installed: `mono --version`
- Check that MSBuild can find the SDK: `msbuild /version`
- Verify .NET Framework 4.7.2 target is available

### Runtime Errors:
- Check that all dependencies are resolved
- Verify file paths are correct
- Check that output directories exist

### Test Failures:
- Review test output for specific failure messages
- Check that test data files exist
- Verify file permissions

