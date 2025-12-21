using System;
using System.IO;
using Newtonsoft.Json;
using Sio.TestRunner.Model;
using YamlDotNet.Serialization;

namespace Sio.TestRunner.IO
{
    /// <summary>
    /// Loads test definitions from YAML or JSON files.
    /// </summary>
    public sealed class TestLoader
    {
        /// <summary>
        /// Loads a test suite from a file (YAML or JSON).
        /// </summary>
        public TestSuite Load(string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
                throw new ArgumentException("File path cannot be empty", nameof(filePath));

            if (!File.Exists(filePath))
                throw new FileNotFoundException($"Test file not found: {filePath}");

            var extension = Path.GetExtension(filePath).ToLowerInvariant();
            var content = File.ReadAllText(filePath);

            if (extension == ".json")
            {
                return LoadJson(content);
            }
            else if (extension == ".yaml" || extension == ".yml")
            {
                return LoadYaml(content);
            }
            else
            {
                throw new NotSupportedException($"Unsupported test file format: {extension}. Use .json or .yaml");
            }
        }

        private TestSuite LoadJson(string content)
        {
            try
            {
                return JsonConvert.DeserializeObject<TestSuite>(content);
            }
            catch (JsonException ex)
            {
                throw new InvalidOperationException($"Failed to parse JSON test file: {ex.Message}", ex);
            }
        }

        private TestSuite LoadYaml(string content)
        {
            try
            {
                var deserializer = new DeserializerBuilder()
                    .WithNamingConvention(YamlDotNet.Serialization.NamingConventions.CamelCaseNamingConvention.Instance)
                    .IgnoreUnmatchedProperties()
                    .Build();
                return deserializer.Deserialize<TestSuite>(content);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to parse YAML test file: {ex.Message}", ex);
            }
        }
    }
}

