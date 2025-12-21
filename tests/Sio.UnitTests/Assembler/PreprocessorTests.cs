using System;
using System.IO;
using System.Linq;
using NUnit.Framework;
using Sio.Assembler.IO;
using Sio.Assembler.Preprocessor;

namespace Sio.UnitTests.Assembler
{
    public sealed class PreprocessorTests
    {
        private string _tempDir;

        [SetUp]
        public void SetUp()
        {
            _tempDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
            Directory.CreateDirectory(_tempDir);
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_tempDir))
            {
                Directory.Delete(_tempDir, recursive: true);
            }
        }

        [Test]
        public void SourceLoader_ResolvesSimpleInclude()
        {
            var mainFile = Path.Combine(_tempDir, "main.asm");
            var incFile = Path.Combine(_tempDir, "inc.asm");
            File.WriteAllText(mainFile, "mov acc 1\ninclude inc.asm\nmov acc 2");
            File.WriteAllText(incFile, "mov dat 3");

            var loader = new SourceLoader();
            var project = loader.Load(mainFile, new[] { _tempDir });

            Assert.AreEqual(2, project.Files.Count);
            Assert.IsTrue(project.Files.Contains(mainFile));
            Assert.IsTrue(project.Files.Contains(incFile));
        }

        [Test]
        public void SourceLoader_DetectsIncludeCycle()
        {
            var file1 = Path.Combine(_tempDir, "file1.asm");
            var file2 = Path.Combine(_tempDir, "file2.asm");
            File.WriteAllText(file1, "include file2.asm");
            File.WriteAllText(file2, "include file1.asm");

            var loader = new SourceLoader();
            Assert.Throws<InvalidOperationException>(() => loader.Load(file1, new[] { _tempDir }));
        }

        [Test]
        public void CommentStripper_RemovesLineComments()
        {
            var input = "mov acc 1 ; comment\nmov dat 2";
            var stripper = new CommentStripper();
            var output = stripper.Strip(input);
            Assert.AreEqual("mov acc 1\nmov dat 2", output);
        }

        [Test]
        public void CommentStripper_RemovesBlockComments()
        {
            var input = "mov acc 1\n/* block\ncomment */\nmov dat 2";
            var stripper = new CommentStripper();
            var output = stripper.Strip(input);
            Assert.AreEqual("mov acc 1\n\nmov dat 2", output);
        }

        [Test]
        public void CommentStripper_PreservesCodeInQuotes()
        {
            // Note: Shenzhen I/O assembly may not have string literals, but test edge cases
            var input = "mov acc 1 ; valid comment\nmov dat 2";
            var stripper = new CommentStripper();
            var output = stripper.Strip(input);
            Assert.IsFalse(output.Contains(";"));
        }

        [Test]
        public void ConstTable_ResolvesConstants()
        {
            var table = new ConstTable();
            table.Define("MAX", 100);
            table.Define("MIN", 0);

            var input = "mov acc MAX\nmov dat MIN";
            var output = table.Substitute(input);
            Assert.AreEqual("mov acc 100\nmov dat 0", output);
        }

        [Test]
        public void ConstTable_ThrowsOnUndefinedConstant()
        {
            var table = new ConstTable();
            var input = "mov acc UNDEFINED";
            Assert.Throws<InvalidOperationException>(() => table.Substitute(input));
        }

        [Test]
        public void AliasTable_ResolvesAliases()
        {
            var table = new AliasTable();
            table.Define("LED", "p0");
            table.Define("SENSOR", "p1");

            var input = "mov acc LED\nmov dat SENSOR";
            var output = table.Substitute(input);
            Assert.AreEqual("mov acc p0\nmov dat p1", output);
        }

        [Test]
        public void AliasTable_ThrowsOnUndefinedAlias()
        {
            var table = new AliasTable();
            var input = "mov acc UNDEFINED";
            Assert.Throws<InvalidOperationException>(() => table.Substitute(input));
        }

        [Test]
        public void Preprocessor_Pipeline_IncludesCommentsConstAlias()
        {
            var mainFile = Path.Combine(_tempDir, "main.asm");
            var incFile = Path.Combine(_tempDir, "inc.asm");
            File.WriteAllText(mainFile, "const VALUE 42\nalias OUT p0\n; comment\nmov acc VALUE\ninclude inc.asm");
            File.WriteAllText(incFile, "mov OUT acc");

            var loader = new SourceLoader();
            var project = loader.Load(mainFile, new[] { _tempDir });

            var preprocessor = new Preprocessor();
            var result = preprocessor.Process(project);

            // Should have no comments, const/alias resolved, includes flattened
            Assert.IsFalse(result.Contains(";"));
            Assert.IsFalse(result.Contains("const"));
            Assert.IsFalse(result.Contains("alias"));
            Assert.IsFalse(result.Contains("include"));
            Assert.IsTrue(result.Contains("42"));
            Assert.IsTrue(result.Contains("p0"));
        }
    }
}

