using System;
using System.Collections.Generic;
using System.Linq;
using Sio.Assembler.Parse;

namespace Sio.EditorSupport.Analysis
{
    public enum DiagSeverity { Error = 1, Warning = 2, Information = 3, Hint = 4 }

    public sealed class LspDiagnostic
    {
        public int Line;        // 0-based
        public int StartChar;   // 0-based
        public int EndChar;     // 0-based, exclusive
        public DiagSeverity Severity;
        public string Message;
    }

    public sealed class LabelInfo
    {
        public string Name;
        public int Line;        // 0-based
        public int Character;   // 0-based start of the label name
    }

    /// <summary>
    /// Result of analysing a single document: diagnostics plus an index that the
    /// hover/definition/completion handlers reuse.
    /// </summary>
    public sealed class DocumentAnalysis
    {
        public IList<LspDiagnostic> Diagnostics { get; } = new List<LspDiagnostic>();
        public IList<Token> Tokens { get; set; } = new List<Token>();
        public IDictionary<string, LabelInfo> Labels { get; } =
            new Dictionary<string, LabelInfo>(StringComparer.Ordinal);

        /// <summary>Returns the token whose span covers the 0-based position, if any.</summary>
        public Token TokenAt(int line, int character)
        {
            foreach (var t in Tokens)
            {
                if (t.Line - 1 != line)
                    continue;
                var start = t.Column;
                var end = t.Column + (t.Value?.Length ?? 0);
                if (character >= start && character < end)
                    return t;
            }
            return null;
        }
    }

    /// <summary>
    /// Token-based analyzer. Reuses the assembler's <see cref="Tokenizer"/> so the
    /// language server sees source exactly as the real assembler does, then layers
    /// on multi-error diagnostics (the assembler parser stops at the first error).
    /// </summary>
    public static class Analyzer
    {
        private static readonly HashSet<string> ValidInstructions =
            new HashSet<string>(InstructionDocs.All.Select(d => d.Name), StringComparer.OrdinalIgnoreCase);

        public static DocumentAnalysis Analyze(string text)
        {
            var result = new DocumentAnalysis();
            text = text ?? string.Empty;

            var tokenizer = new Tokenizer();
            var tokens = tokenizer.Tokenize(text);
            result.Tokens = tokens;

            // Pass 1: collect label definitions.
            foreach (var t in tokens)
            {
                if (t.IsLabel && !result.Labels.ContainsKey(t.Value))
                {
                    result.Labels[t.Value] = new LabelInfo
                    {
                        Name = t.Value,
                        Line = t.Line - 1,
                        Character = t.Column
                    };
                }
            }

            // Pass 2: per-logical-line checks (unknown instruction, jmp target).
            AnalyzeLines(tokens, result);

            // Pass 3: run the real parser to surface structural errors it catches.
            try
            {
                new Parser().Parse(text);
            }
            catch (ParseException ex)
            {
                AddParseError(result, ex);
            }
            catch (Exception)
            {
                // Non-positional failures are ignored here; pass 2 covers the
                // common cases and we don't want to spam a 0:0 diagnostic.
            }

            return result;
        }

        private static void AnalyzeLines(IList<Token> tokens, DocumentAnalysis result)
        {
            int i = 0;
            while (i < tokens.Count)
            {
                var t = tokens[i];
                if (t.Type == TokenType.EndOfFile)
                    break;
                if (t.Type == TokenType.Newline)
                {
                    i++;
                    continue;
                }

                // Skip a leading "label:" on this line.
                if (t.IsLabel && i + 1 < tokens.Count && tokens[i + 1].Type == TokenType.Colon)
                {
                    i += 2;
                    continue;
                }

                // Optional conditional prefix (+ / -), tokenized as an identifier.
                if (t.Type == TokenType.Identifier && (t.Value == "+" || t.Value == "-"))
                {
                    i++;
                    if (i >= tokens.Count)
                        break;
                    t = tokens[i];
                    if (t.Type == TokenType.Newline || t.Type == TokenType.EndOfFile)
                        continue;
                }

                // First identifier here is the mnemonic.
                if (t.Type == TokenType.Identifier)
                {
                    if (!ValidInstructions.Contains(t.Value))
                    {
                        result.Diagnostics.Add(new LspDiagnostic
                        {
                            Line = t.Line - 1,
                            StartChar = t.Column,
                            EndChar = t.Column + t.Value.Length,
                            Severity = DiagSeverity.Error,
                            Message = "Unknown instruction: '" + t.Value + "'."
                        });
                    }
                    else if (string.Equals(t.Value, "jmp", StringComparison.OrdinalIgnoreCase)
                             && i + 1 < tokens.Count
                             && tokens[i + 1].Type == TokenType.Identifier)
                    {
                        var target = tokens[i + 1];
                        if (!result.Labels.ContainsKey(target.Value))
                        {
                            result.Diagnostics.Add(new LspDiagnostic
                            {
                                Line = target.Line - 1,
                                StartChar = target.Column,
                                EndChar = target.Column + target.Value.Length,
                                Severity = DiagSeverity.Warning,
                                Message = "Undefined label: '" + target.Value + "'."
                            });
                        }
                    }
                }

                // Advance to end of logical line.
                while (i < tokens.Count
                       && tokens[i].Type != TokenType.Newline
                       && tokens[i].Type != TokenType.EndOfFile)
                {
                    i++;
                }
            }
        }

        private static void AddParseError(DocumentAnalysis result, ParseException ex)
        {
            var line = Math.Max(0, ex.Line - 1);
            var ch = Math.Max(0, ex.Column);
            // Don't duplicate a diagnostic the line pass already reported at this spot.
            if (result.Diagnostics.Any(d => d.Line == line && d.StartChar == ch))
                return;
            result.Diagnostics.Add(new LspDiagnostic
            {
                Line = line,
                StartChar = ch,
                EndChar = ch + 1,
                Severity = DiagSeverity.Error,
                Message = ex.Message
            });
        }
    }
}
