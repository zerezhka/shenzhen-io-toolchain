using System;
using System.IO;
using Newtonsoft.Json.Linq;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace Sio.TestRunner.IO
{
    public enum TestDefinitionFormat
    {
        Json,
        Yaml
    }

    public sealed class TestDefinitionDocument
    {
        public TestDefinitionFormat Format { get; }
        public JObject Json { get; }

        public TestDefinitionDocument(TestDefinitionFormat format, JObject json)
        {
            Format = format;
            Json = json ?? throw new ArgumentNullException(nameof(json));
        }
    }

    public static class TestDefinitionLoader
    {
        public static TestDefinitionDocument Load(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("path is required", nameof(path));
            var ext = Path.GetExtension(path).ToLowerInvariant();
            var text = File.ReadAllText(path);

            if (ext == ".json")
            {
                return new TestDefinitionDocument(TestDefinitionFormat.Json, JObject.Parse(text));
            }

            if (ext == ".yaml" || ext == ".yml")
            {
                // Parse YAML into a generic object graph, then roundtrip through JSON for schema validation.
                var deserializer = new DeserializerBuilder()
                    .WithNamingConvention(CamelCaseNamingConvention.Instance)
                    .Build();
                var yamlObj = deserializer.Deserialize(new StringReader(text));
                var json = JObject.FromObject(yamlObj);
                return new TestDefinitionDocument(TestDefinitionFormat.Yaml, json);
            }

            throw new NotSupportedException("Unsupported test definition file extension: " + ext);
        }
    }
}


