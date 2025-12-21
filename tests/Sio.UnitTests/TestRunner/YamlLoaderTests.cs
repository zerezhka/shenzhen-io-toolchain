using NUnit.Framework;
using Sio.TestRunner.IO;

namespace Sio.UnitTests.TestRunner
{
    public sealed class YamlLoaderTests
    {
        [Test]
        public void LoadYaml_ParsesIntoJsonDocument()
        {
            // Minimal smoke: parse a tiny yaml into a document.
            var tmp = System.IO.Path.GetTempFileName() + ".yaml";
            System.IO.File.WriteAllText(tmp, "formatVersion: \"1\"\ncases: []\n");
            var doc = TestDefinitionLoader.Load(tmp);
            Assert.AreEqual(TestDefinitionFormat.Yaml, doc.Format);
            Assert.AreEqual("1", (string)doc.Json["formatVersion"]);
        }
    }
}


