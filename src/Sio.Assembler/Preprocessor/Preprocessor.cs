using System;
using System.IO;
using System.Linq;
using System.Text;
using Sio.Assembler.Model;

namespace Sio.Assembler.Preprocessor
{
    public sealed class Preprocessor
    {
        public string Process(SourceProject project)
        {
            var constTable = new ConstTable();
            var aliasTable = new AliasTable();
            var commentStripper = new CommentStripper();

            // First pass: collect all const and alias definitions from all files
            var allContent = new StringBuilder();
            foreach (var file in project.Files.OrderBy(f => f == project.EntryFile ? 0 : 1))
            {
                var content = File.ReadAllText(file);
                allContent.Append(content);
                allContent.Append("\n");
            }

            var fullContent = allContent.ToString();
            var lines = fullContent.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);

            // Collect const and alias definitions
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("const ", StringComparison.OrdinalIgnoreCase))
                {
                    var parts = trimmed.Substring(6).Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length >= 2 && int.TryParse(parts[1], out var value))
                    {
                        constTable.Define(parts[0], value);
                    }
                }
                else if (trimmed.StartsWith("alias ", StringComparison.OrdinalIgnoreCase))
                {
                    var parts = trimmed.Substring(6).Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length >= 2)
                    {
                        aliasTable.Define(parts[0], parts[1]);
                    }
                }
            }

            // Second pass: remove include/const/alias directives, then substitute and strip
            var processedLines = new StringBuilder();
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                // Skip include, const, and alias directive lines
                if (trimmed.StartsWith("include ", StringComparison.OrdinalIgnoreCase) ||
                    trimmed.StartsWith("const ", StringComparison.OrdinalIgnoreCase) ||
                    trimmed.StartsWith("alias ", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                processedLines.Append(line);
                processedLines.Append("\n");
            }

            var contentToProcess = processedLines.ToString();
            
            // Strip comments FIRST (before substitution to avoid treating comment text as constants/aliases)
            contentToProcess = commentStripper.Strip(contentToProcess);
            
            // Apply const substitution
            contentToProcess = constTable.Substitute(contentToProcess);
            
            // Apply alias substitution
            contentToProcess = aliasTable.Substitute(contentToProcess);
            
            // Clean up extra blank lines but preserve structure
            var finalLines = contentToProcess.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None)
                .Where(l => l.Trim().Length > 0 || l == "")
                .ToList();
            
            var output = string.Join("\n", finalLines).TrimEnd('\n');
            // Ensure trailing newline (standard for text files)
            return output + "\n";
        }
    }
}

