using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Sio.Assembler.Model;

namespace Sio.Assembler.IO
{
    public sealed class SourceLoader
    {
        public SourceProject Load(string entryFile, IEnumerable<string> includePaths)
        {
            if (string.IsNullOrWhiteSpace(entryFile))
                throw new ArgumentException("Entry file is required", nameof(entryFile));
            if (!File.Exists(entryFile))
                throw new FileNotFoundException("Entry file not found", entryFile);

            var resolvedPaths = includePaths?.ToList() ?? new List<string>();
            var files = new HashSet<string>();
            var visited = new HashSet<string>();
            var includeChain = new List<string>();

            ResolveIncludes(entryFile, resolvedPaths, files, visited, includeChain);

            return new SourceProject(entryFile, resolvedPaths, files);
        }

        private void ResolveIncludes(
            string filePath,
            List<string> includePaths,
            HashSet<string> files,
            HashSet<string> visited,
            List<string> includeChain)
        {
            var normalizedPath = Path.GetFullPath(filePath);
            
            if (visited.Contains(normalizedPath))
            {
                var cycle = string.Join(" -> ", includeChain) + " -> " + normalizedPath;
                throw new InvalidOperationException($"Include cycle detected: {cycle}");
            }

            visited.Add(normalizedPath);
            files.Add(normalizedPath);
            includeChain.Add(normalizedPath);

            try
            {
                var content = File.ReadAllText(normalizedPath);
                var directory = Path.GetDirectoryName(normalizedPath);
                var lines = content.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);

                foreach (var line in lines)
                {
                    var trimmed = line.Trim();
                    if (trimmed.StartsWith("include ", StringComparison.OrdinalIgnoreCase))
                    {
                        var includeFile = trimmed.Substring(8).Trim();
                        var includePath = FindIncludeFile(includeFile, directory, includePaths);
                        
                        if (includePath == null)
                        {
                            var chain = string.Join(" -> ", includeChain);
                            throw new FileNotFoundException($"Include file not found: {includeFile} (searched from {chain})");
                        }

                        ResolveIncludes(includePath, includePaths, files, visited, includeChain);
                    }
                }
            }
            finally
            {
                includeChain.RemoveAt(includeChain.Count - 1);
                visited.Remove(normalizedPath);
            }
        }

        private string FindIncludeFile(string fileName, string currentDirectory, List<string> includePaths)
        {
            // First check relative to current file's directory
            var relativePath = Path.Combine(currentDirectory, fileName);
            if (File.Exists(relativePath))
                return Path.GetFullPath(relativePath);

            // Then check include paths
            foreach (var includePath in includePaths)
            {
                var fullPath = Path.Combine(includePath, fileName);
                if (File.Exists(fullPath))
                    return Path.GetFullPath(fullPath);
            }

            return null;
        }
    }
}

