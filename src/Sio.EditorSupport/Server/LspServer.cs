using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;
using Sio.EditorSupport.Analysis;
using Sio.EditorSupport.JsonRpc;

namespace Sio.EditorSupport.Server
{
    /// <summary>
    /// The Shenzhen I/O language server. Implements a focused subset of LSP:
    /// lifecycle, text sync, diagnostics, hover, completion, and go-to-definition.
    /// </summary>
    public sealed class LspServer
    {
        private readonly RpcConnection _rpc;
        private readonly DocumentStore _docs = new DocumentStore();
        private bool _shutdownRequested;

        public LspServer(RpcConnection rpc)
        {
            _rpc = rpc ?? throw new ArgumentNullException(nameof(rpc));
        }

        public int Run()
        {
            while (true)
            {
                JObject message;
                try
                {
                    message = _rpc.ReadMessage();
                }
                catch (Exception)
                {
                    break;
                }

                if (message == null)
                    break;

                var method = (string)message["method"];
                var id = message["id"];

                try
                {
                    Dispatch(method, id, message["params"] as JObject);
                }
                catch (Exception ex)
                {
                    if (id != null)
                        SendError(id, -32603, "Internal error: " + ex.Message);
                }

                if (method == "exit")
                    return _shutdownRequested ? 0 : 1;
            }

            return _shutdownRequested ? 0 : 1;
        }

        private void Dispatch(string method, JToken id, JObject p)
        {
            switch (method)
            {
                case "initialize":
                    SendResult(id, BuildInitializeResult());
                    break;
                case "initialized":
                    break; // notification, nothing to do
                case "shutdown":
                    _shutdownRequested = true;
                    SendResult(id, JValue.CreateNull());
                    break;
                case "exit":
                    break;
                case "textDocument/didOpen":
                    OnDidOpen(p);
                    break;
                case "textDocument/didChange":
                    OnDidChange(p);
                    break;
                case "textDocument/didClose":
                    OnDidClose(p);
                    break;
                case "textDocument/hover":
                    SendResult(id, OnHover(p));
                    break;
                case "textDocument/completion":
                    SendResult(id, OnCompletion());
                    break;
                case "textDocument/definition":
                    SendResult(id, OnDefinition(p));
                    break;
                default:
                    if (id != null)
                        SendError(id, -32601, "Method not found: " + method);
                    break;
            }
        }

        // ---- lifecycle ----

        private static JObject BuildInitializeResult()
        {
            return new JObject
            {
                ["capabilities"] = new JObject
                {
                    ["textDocumentSync"] = 1, // full document sync
                    ["hoverProvider"] = true,
                    ["definitionProvider"] = true,
                    ["completionProvider"] = new JObject
                    {
                        ["triggerCharacters"] = new JArray()
                    }
                },
                ["serverInfo"] = new JObject
                {
                    ["name"] = "sio-langserver",
                    ["version"] = "0.1.0"
                }
            };
        }

        // ---- text sync + diagnostics ----

        private void OnDidOpen(JObject p)
        {
            var doc = p["textDocument"];
            var uri = (string)doc["uri"];
            var text = (string)doc["text"];
            _docs.Set(uri, text);
            PublishDiagnostics(uri, text);
        }

        private void OnDidChange(JObject p)
        {
            var uri = (string)p["textDocument"]["uri"];
            var changes = p["contentChanges"] as JArray;
            if (changes == null || changes.Count == 0)
                return;
            // Full sync: the last change holds the whole document.
            var text = (string)changes.Last["text"];
            _docs.Set(uri, text);
            PublishDiagnostics(uri, text);
        }

        private void OnDidClose(JObject p)
        {
            var uri = (string)p["textDocument"]["uri"];
            _docs.Remove(uri);
            // Clear diagnostics for the closed document.
            PublishDiagnostics(uri, null, clear: true);
        }

        private void PublishDiagnostics(string uri, string text, bool clear = false)
        {
            var arr = new JArray();
            if (!clear)
            {
                var analysis = Analyzer.Analyze(text);
                foreach (var d in analysis.Diagnostics)
                    arr.Add(DiagnosticToJson(d));
            }

            SendNotification("textDocument/publishDiagnostics", new JObject
            {
                ["uri"] = uri,
                ["diagnostics"] = arr
            });
        }

        private static JObject DiagnosticToJson(LspDiagnostic d)
        {
            return new JObject
            {
                ["range"] = Range(d.Line, d.StartChar, d.Line, d.EndChar),
                ["severity"] = (int)d.Severity,
                ["source"] = "sio",
                ["message"] = d.Message
            };
        }

        // ---- hover ----

        private JToken OnHover(JObject p)
        {
            if (!TryGetDocAndPosition(p, out var text, out var line, out var ch))
                return JValue.CreateNull();

            var analysis = Analyzer.Analyze(text);
            var token = analysis.TokenAt(line, ch);
            if (token == null || string.IsNullOrEmpty(token.Value))
                return JValue.CreateNull();

            string markdown = null;
            if (InstructionDocs.TryGet(token.Value, out var doc))
                markdown = InstructionDocs.ToMarkdown(doc);
            else if (RegisterDocs.TryGet(token.Value, out var reg))
                markdown = "**" + token.Value + "** — " + reg;
            else if (analysis.Labels.TryGetValue(token.Value, out var label))
                markdown = "Label **" + label.Name + "** (defined at line " + (label.Line + 1) + ")";

            if (markdown == null)
                return JValue.CreateNull();

            return new JObject
            {
                ["contents"] = new JObject
                {
                    ["kind"] = "markdown",
                    ["value"] = markdown
                }
            };
        }

        // ---- completion ----

        private JToken OnCompletion()
        {
            var items = new JArray();
            foreach (var doc in InstructionDocs.All)
            {
                items.Add(new JObject
                {
                    ["label"] = doc.Name,
                    ["kind"] = 3, // Function
                    ["detail"] = doc.Signature,
                    ["documentation"] = new JObject
                    {
                        ["kind"] = "markdown",
                        ["value"] = InstructionDocs.ToMarkdown(doc)
                    }
                });
            }
            foreach (var reg in RegisterDocs.All)
            {
                items.Add(new JObject
                {
                    ["label"] = reg.Key,
                    ["kind"] = 6, // Variable
                    ["detail"] = "register",
                    ["documentation"] = reg.Value
                });
            }
            return items;
        }

        // ---- definition ----

        private JToken OnDefinition(JObject p)
        {
            if (!TryGetDocAndPosition(p, out var text, out var line, out var ch))
                return JValue.CreateNull();

            var analysis = Analyzer.Analyze(text);
            var token = analysis.TokenAt(line, ch);
            if (token == null || string.IsNullOrEmpty(token.Value))
                return JValue.CreateNull();

            if (!analysis.Labels.TryGetValue(token.Value, out var label))
                return JValue.CreateNull();

            var uri = (string)p["textDocument"]["uri"];
            return new JObject
            {
                ["uri"] = uri,
                ["range"] = Range(label.Line, label.Character, label.Line, label.Character + label.Name.Length)
            };
        }

        // ---- helpers ----

        private bool TryGetDocAndPosition(JObject p, out string text, out int line, out int character)
        {
            text = null; line = 0; character = 0;
            var uri = (string)p["textDocument"]?["uri"];
            if (uri == null || !_docs.TryGet(uri, out text))
                return false;
            var pos = p["position"];
            if (pos == null)
                return false;
            line = (int)pos["line"];
            character = (int)pos["character"];
            return true;
        }

        private static JObject Range(int sl, int sc, int el, int ec)
        {
            return new JObject
            {
                ["start"] = new JObject { ["line"] = sl, ["character"] = sc },
                ["end"] = new JObject { ["line"] = el, ["character"] = ec }
            };
        }

        private void SendResult(JToken id, JToken result)
        {
            _rpc.WriteMessage(new JObject
            {
                ["jsonrpc"] = "2.0",
                ["id"] = id,
                ["result"] = result ?? JValue.CreateNull()
            });
        }

        private void SendError(JToken id, int code, string message)
        {
            _rpc.WriteMessage(new JObject
            {
                ["jsonrpc"] = "2.0",
                ["id"] = id,
                ["error"] = new JObject { ["code"] = code, ["message"] = message }
            });
        }

        private void SendNotification(string method, JObject @params)
        {
            _rpc.WriteMessage(new JObject
            {
                ["jsonrpc"] = "2.0",
                ["method"] = method,
                ["params"] = @params
            });
        }
    }
}
