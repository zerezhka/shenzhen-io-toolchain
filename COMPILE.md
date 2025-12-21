# How to Compile the Assembler

## Quick Build (macOS with Mono)

```bash
cd src
msbuild Sio.sln /t:Build /p:Configuration=Debug
```

This builds all projects including:
- `Sio.Assembler.dll` - The assembler library
- `sio.exe` - The CLI executable

## Build Individual Projects

### Build just the Assembler:
```bash
cd src
msbuild Sio.Assembler/Sio.Assembler.csproj /t:Build /p:Configuration=Debug
```

Output: `src/Sio.Assembler/bin/Debug/net472/Sio.Assembler.dll`

### Build just the CLI:
```bash
cd src
msbuild Sio.Cli/Sio.Cli.csproj /t:Build /p:Configuration=Debug
```

Output: `src/Sio.Cli/bin/Debug/net472/sio.exe`

## Run the Assembler

After building, test it:

```bash
mono src/Sio.Cli/bin/Debug/net472/sio.exe assemble examples/us1/extended/main.asm -o /tmp/output.asm
cat /tmp/output.asm
```

## Build All Projects (Full Solution)

```bash
cd src
msbuild Sio.sln /t:Build /p:Configuration=Debug
```

This builds:
- Sio.Assembler
- Sio.Simulator  
- Sio.TestRunner
- Sio.Cli
- Sio.EditorSupport

## Troubleshooting

### Missing `using System;` errors
If you see errors about `StringSplitOptions` or `StringComparison` not found, make sure all C# files have `using System;` at the top.

### Build fails with NuGet errors
The project should build without needing to restore packages first (dependencies are minimal), but if needed:
```bash
msbuild Sio.sln /t:Restore
```

### Output directory is empty
- Check for build errors in the output
- Make sure you're in the `src` directory
- Verify the project files are correct

