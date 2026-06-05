import * as path from "path";
import * as fs from "fs";
import * as cp from "child_process";
import * as vscode from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
} from "vscode-languageclient/node";

let client: LanguageClient | undefined;
let output: vscode.OutputChannel;

export function activate(context: vscode.ExtensionContext): void {
  output = vscode.window.createOutputChannel("Shenzhen I/O");
  context.subscriptions.push(output);

  startServer();

  context.subscriptions.push(
    vscode.commands.registerCommand("shenzhenIo.assemble", () => runCli(["assemble"], true)),
    vscode.commands.registerCommand("shenzhenIo.simulate", () => runCli(["simulate", "--trace"], false)),
    vscode.commands.registerCommand("shenzhenIo.test", () => runCli(["test"], false)),
    vscode.commands.registerCommand("shenzhenIo.restartServer", async () => {
      await stopServer();
      startServer();
      vscode.window.showInformationMessage("Shenzhen I/O language server restarted.");
    })
  );
}

export function deactivate(): Thenable<void> | undefined {
  return stopServer();
}

// ---- language server ----

function startServer(): void {
  const serverExe = resolveServerPath();
  if (!serverExe) {
    output.appendLine(
      "Language server not found. Build it with `dotnet build src/Sio.EditorSupport` " +
        "or set `shenzhenIo.languageServer.path`."
    );
    return;
  }

  const cfg = vscode.workspace.getConfiguration("shenzhenIo");
  const monoPath = cfg.get<string>("mono.path") || "mono";

  // On Windows the .exe runs directly; elsewhere it runs under mono.
  const run =
    process.platform === "win32"
      ? { command: serverExe, args: [] as string[] }
      : { command: monoPath, args: [serverExe] };

  const serverOptions: ServerOptions = {
    run,
    debug: run,
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "shenzhen-io" }],
    outputChannel: output,
  };

  client = new LanguageClient(
    "shenzhenIo",
    "Shenzhen I/O Language Server",
    serverOptions,
    clientOptions
  );
  client.start();
}

function stopServer(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  const stopping = client.stop();
  client = undefined;
  return stopping;
}

function resolveServerPath(): string | undefined {
  const cfg = vscode.workspace.getConfiguration("shenzhenIo");
  const configured = cfg.get<string>("languageServer.path");
  if (configured && fs.existsSync(configured)) {
    return configured;
  }

  // Look for the build output in each open workspace folder.
  const rel = path.join(
    "src",
    "Sio.EditorSupport",
    "bin",
    "Debug",
    "net472",
    "sio-langserver.exe"
  );
  for (const folder of vscode.workspace.workspaceFolders ?? []) {
    const candidate = path.join(folder.uri.fsPath, rel);
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return undefined;
}

// ---- CLI commands ----

function runCli(args: string[], wantsOutputFile: boolean): void {
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.document.languageId !== "shenzhen-io") {
    vscode.window.showWarningMessage("Open a Shenzhen I/O (.asm) file first.");
    return;
  }

  editor.document.save().then(() => {
    const inputPath = editor.document.uri.fsPath;
    const cli = resolveCli(inputPath);
    if (!cli) {
      vscode.window.showErrorMessage(
        "sio CLI not found. Set `shenzhenIo.cli.path` or build the CLI."
      );
      return;
    }

    const fullArgs = [...cli.args, ...args, inputPath];
    if (wantsOutputFile) {
      fullArgs.push("-o", inputPath.replace(/\.asm$/i, ".out.txt"));
    }

    output.clear();
    output.show(true);
    output.appendLine(`$ ${cli.command} ${fullArgs.join(" ")}`);

    const proc = cp.spawn(cli.command, fullArgs, {
      cwd: path.dirname(inputPath),
    });
    proc.stdout.on("data", (d: Buffer) => output.append(d.toString()));
    proc.stderr.on("data", (d: Buffer) => output.append(d.toString()));
    proc.on("error", (err) => output.appendLine(`error: ${err.message}`));
    proc.on("close", (code) => output.appendLine(`\n[exit ${code}]`));
  });
}

function resolveCli(inputPath: string): { command: string; args: string[] } | undefined {
  const cfg = vscode.workspace.getConfiguration("shenzhenIo");
  const configured = cfg.get<string>("cli.path");
  if (configured && fs.existsSync(configured)) {
    return configured.endsWith(".exe") && process.platform !== "win32"
      ? { command: cfg.get<string>("mono.path") || "mono", args: [configured] }
      : { command: configured, args: [] };
  }

  // Fall back to the repo's ./sio wrapper from the nearest workspace folder.
  const folder = vscode.workspace.getWorkspaceFolder(vscode.Uri.file(inputPath));
  if (folder) {
    const wrapper = path.join(folder.uri.fsPath, "sio");
    if (fs.existsSync(wrapper)) {
      return { command: wrapper, args: [] };
    }
  }
  return undefined;
}
