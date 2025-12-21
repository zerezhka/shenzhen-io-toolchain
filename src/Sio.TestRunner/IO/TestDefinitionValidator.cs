using System;
using System.IO;
using System.Linq;
using NJsonSchema;

namespace Sio.TestRunner.IO
{
    public sealed class TestDefinitionValidationResult
    {
        public bool IsValid { get; }
        public string[] Errors { get; }

        public TestDefinitionValidationResult(bool isValid, string[] errors)
        {
            IsValid = isValid;
            Errors = errors ?? Array.Empty<string>();
        }
    }

    public static class TestDefinitionValidator
    {
        public static TestDefinitionValidationResult ValidateAgainstSchema(TestDefinitionDocument doc, string schemaPath)
        {
            if (doc == null) throw new ArgumentNullException(nameof(doc));
            if (string.IsNullOrWhiteSpace(schemaPath)) throw new ArgumentException("schemaPath is required", nameof(schemaPath));

            var schemaJson = File.ReadAllText(schemaPath);
            var schema = JsonSchema.FromJsonAsync(schemaJson).GetAwaiter().GetResult();

            var errors = schema.Validate(doc.Json.ToString());
            var msgs = errors
                .Select(e => $"{e.Path}: {e.Kind} {e.Property}")
                .Distinct()
                .OrderBy(s => s, StringComparer.Ordinal)
                .ToArray();

            return new TestDefinitionValidationResult(msgs.Length == 0, msgs);
        }
    }
}


