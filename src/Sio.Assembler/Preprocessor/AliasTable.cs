using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace Sio.Assembler.Preprocessor
{
    public sealed class AliasTable
    {
        private readonly Dictionary<string, string> _aliases = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public void Define(string name, string value)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("Alias name is required", nameof(name));
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Alias value is required", nameof(value));
            _aliases[name.Trim()] = value.Trim();
        }

        public string Substitute(string input)
        {
            if (string.IsNullOrEmpty(input))
                return input;

            var result = new StringBuilder();
            var lines = input.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);

            foreach (var line in lines)
            {
                var processed = ProcessLine(line);
                result.Append(processed);
                result.Append("\n");
            }

            return result.ToString().TrimEnd('\n');
        }

        private string ProcessLine(string line)
        {
            // Check if this is an alias definition
            var trimmed = line.Trim();
            if (trimmed.StartsWith("alias ", StringComparison.OrdinalIgnoreCase))
            {
                var parts = trimmed.Substring(6).Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length >= 2)
                {
                    Define(parts[0], parts[1]);
                    return ""; // Remove alias definition line
                }
            }

            // Substitute aliases in the line
            var result = line;
            foreach (var kvp in _aliases)
            {
                // Use word boundaries to avoid partial matches
                var pattern = @"\b" + Regex.Escape(kvp.Key) + @"\b";
                result = Regex.Replace(result, pattern, kvp.Value, RegexOptions.IgnoreCase);
            }

            // Check for undefined aliases - throw if we find an identifier that looks like an alias
            // but isn't defined and isn't a known keyword
            var words = Regex.Matches(result, @"\b[A-Za-z_][A-Za-z0-9_]*\b");
            foreach (Match word in words)
            {
                var wordValue = word.Value;
                // Skip known keywords, numbers, and defined aliases
                if (IsKnownKeyword(wordValue) || int.TryParse(wordValue, out _) || _aliases.ContainsKey(wordValue))
                    continue;

                // If it's an uppercase identifier (likely an alias), throw
                if (wordValue.All(c => char.IsUpper(c) || char.IsDigit(c) || c == '_'))
                {
                    throw new InvalidOperationException($"Undefined alias: {wordValue}");
                }
            }

            return result;
        }

        private bool IsKnownKeyword(string word)
        {
            // Valid Shenzhen I/O instructions and registers
            var keywords = new[] { 
                // Basic instructions
                "nop", "mov", "jmp", "slp", "slx",
                // Test instructions
                "teq", "tgt", "tlt", "tcp",
                // Arithmetic instructions
                "add", "sub", "mul", "not", "dgt", "dst",
                // Registers
                "acc", "dat", "p0", "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9",
                "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9", "null",
                // Extended directives (for preprocessing)
                "const", "alias", "include"
            };
            return Array.Exists(keywords, k => string.Equals(k, word, StringComparison.OrdinalIgnoreCase));
        }
    }
}

