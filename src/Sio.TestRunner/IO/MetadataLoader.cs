using System;
using System.Collections.Generic;
using System.IO;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.IO
{
    /// <summary>
    /// Loads metadata references (local-only text assets) for test cases.
    /// </summary>
    public sealed class MetadataLoader
    {
        /// <summary>
        /// Loads metadata files referenced by a test case.
        /// </summary>
        /// <returns>Dictionary of metadata type to content</returns>
        public Dictionary<string, string> LoadMetadata(TestCase testCase, string baseDirectory = null)
        {
            if (testCase == null)
                throw new ArgumentNullException(nameof(testCase));

            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            if (testCase.MetadataRefs == null || testCase.MetadataRefs.Count == 0)
            {
                return result;
            }

            foreach (var kvp in testCase.MetadataRefs)
            {
                var metadataType = kvp.Key;
                var filePath = kvp.Value;

                // Resolve relative paths
                if (!Path.IsPathRooted(filePath) && !string.IsNullOrEmpty(baseDirectory))
                {
                    filePath = Path.Combine(baseDirectory, filePath);
                }

                if (!File.Exists(filePath))
                {
                    // Metadata files are optional - just skip if not found
                    continue;
                }

                try
                {
                    var content = File.ReadAllText(filePath);
                    result[metadataType] = content;
                }
                catch (Exception ex)
                {
                    // Log but don't fail - metadata is optional
                    System.Diagnostics.Debug.WriteLine($"Failed to load metadata {metadataType} from {filePath}: {ex.Message}");
                }
            }

            return result;
        }
    }
}

