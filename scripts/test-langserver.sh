#!/bin/bash
# Smoke-test the Shenzhen I/O language server.
# Builds Sio.EditorSupport, then drives a minimal LSP handshake over stdio
# and prints the raw responses (initialize result + publishDiagnostics).
#
# Requires the .NET SDK (dotnet) or mono-msbuild on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="$ROOT/src/Sio.EditorSupport/Sio.EditorSupport.csproj"

if command -v dotnet >/dev/null 2>&1; then
  dotnet build "$PROJ" -c Debug
  DLL="$ROOT/src/Sio.EditorSupport/bin/Debug/net472/sio-langserver.dll"
  EXE="$ROOT/src/Sio.EditorSupport/bin/Debug/net472/sio-langserver.exe"
  if [ -f "$EXE" ]; then RUN=(mono "$EXE"); else RUN=(dotnet "$DLL"); fi
elif command -v msbuild >/dev/null 2>&1; then
  msbuild "$PROJ" /t:Restore,Build /p:Configuration=Debug
  RUN=(mono "$ROOT/src/Sio.EditorSupport/bin/Debug/net472/sio-langserver.exe")
else
  echo "error: need dotnet or msbuild on PATH" >&2
  exit 1
fi

# Build LSP messages with Content-Length framing.
frame() { local body="$1"; printf 'Content-Length: %d\r\n\r\n%s' "${#body}" "$body"; }

DOC='nop\nmov 1 acc\nbadinstr p0\njmp nowhere\n'

{
  frame '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}'
  frame '{"jsonrpc":"2.0","method":"initialized","params":{}}'
  frame "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"textDocument\":{\"uri\":\"file:///t.asm\",\"languageId\":\"shenzhen-io\",\"version\":1,\"text\":\"$DOC\"}}}"
  frame '{"jsonrpc":"2.0","id":2,"method":"shutdown","params":null}'
  frame '{"jsonrpc":"2.0","method":"exit","params":null}'
} | "${RUN[@]}"

echo
echo "(expected: initialize capabilities, then diagnostics for 'badinstr' and undefined label 'nowhere')"
