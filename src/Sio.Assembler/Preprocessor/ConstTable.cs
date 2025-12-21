using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace Sio.Assembler.Preprocessor
{
    public sealed class ConstTable
    {
        private readonly Dictionary<string, int> _constants = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        public void Define(string name, int value)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("Constant name is required", nameof(name));
            _constants[name.Trim()] = value;
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
            // Check if this is a const definition
            var trimmed = line.Trim();
            if (trimmed.StartsWith("const ", StringComparison.OrdinalIgnoreCase))
            {
                var parts = trimmed.Substring(6).Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length >= 2 && int.TryParse(parts[1], out var value))
                {
                    Define(parts[0], value);
                    return ""; // Remove const definition line
                }
            }

            // Substitute constants in the line
            var result = line;
            foreach (var kvp in _constants)
            {
                // Use word boundaries to avoid partial matches
                var pattern = @"\b" + Regex.Escape(kvp.Key) + @"\b";
                result = Regex.Replace(result, pattern, kvp.Value.ToString(), RegexOptions.IgnoreCase);
            }

            // Don't check for undefined constants here - they might be aliases, labels, or other identifiers
            // The parser will catch actual errors later. We only substitute what we know.

            return result;
        }

        private bool IsKnownKeyword(string word)
        {
            // Common Shenzhen I/O keywords that shouldn't be treated as constants
            var keywords = new[] { "mov", "add", "sub", "mul", "div", "not", "and", "or", "xor", 
                "jmp", "jz", "jnz", "jg", "jl", "slp", "acc", "dat", "p0", "p1", "p2", "p3", 
                "p4", "p5", "p6", "p7", "p8", "p9", "x0", "x1", "x2", "x3", "x4", "x5", "x6", 
                "x7", "x8", "x9", "null" };
            return Array.Exists(keywords, k => string.Equals(k, word, StringComparison.OrdinalIgnoreCase));
        }
    }
}

