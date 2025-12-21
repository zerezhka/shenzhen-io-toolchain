using NUnit.Framework;
using Sio.Assembler.Parse;
using Sio.Assembler.Emit;

namespace Sio.UnitTests.Assembler
{
    public sealed class ParserTests
    {
        [Test]
        public void Tokenizer_ParsesSimpleInstruction()
        {
            var tokenizer = new Tokenizer();
            var tokens = tokenizer.Tokenize("mov acc 1");
            Assert.AreEqual(3, tokens.Count);
            Assert.AreEqual("mov", tokens[0].Value);
            Assert.AreEqual("acc", tokens[1].Value);
            Assert.AreEqual("1", tokens[2].Value);
        }

        [Test]
        public void Tokenizer_ParsesLabel()
        {
            var tokenizer = new Tokenizer();
            var tokens = tokenizer.Tokenize("loop:\nmov acc 1");
            Assert.IsTrue(tokens[0].IsLabel);
            Assert.AreEqual("loop", tokens[0].Value);
        }

        [Test]
        public void Tokenizer_ParsesMultipleLines()
        {
            var tokenizer = new Tokenizer();
            var tokens = tokenizer.Tokenize("mov acc 1\nmov dat acc");
            Assert.AreEqual(6, tokens.Count);
        }

        [Test]
        public void Parser_ParsesInstruction()
        {
            var parser = new Parser();
            var program = parser.Parse("mov acc 1");
            Assert.AreEqual(1, program.Statements.Count);
            Assert.AreEqual("mov", program.Statements[0].Instruction);
        }

        [Test]
        public void Parser_ParsesLabel()
        {
            var parser = new Parser();
            var program = parser.Parse("loop:\nmov acc 1");
            Assert.AreEqual(2, program.Statements.Count);
            Assert.IsTrue(program.Statements[0].IsLabel);
            Assert.AreEqual("loop", program.Statements[0].Label);
        }

        [Test]
        public void Parser_ParsesJumpToLabel()
        {
            var parser = new Parser();
            var program = parser.Parse("jmp loop\nloop:\nmov acc 1");
            Assert.AreEqual(3, program.Statements.Count);
            Assert.AreEqual("jmp", program.Statements[0].Instruction);
            Assert.AreEqual("loop", program.Statements[0].Operands[0]);
        }

        [Test]
        public void Parser_ReportsErrorLocation()
        {
            var parser = new Parser();
            Assert.Throws<ParseException>(() => parser.Parse("invalid instruction"));
        }

        [Test]
        public void VanillaEmitter_EmitsSimpleInstruction()
        {
            var parser = new Parser();
            var program = parser.Parse("mov acc 1");
            var emitter = new VanillaEmitter();
            var output = emitter.Emit(program);
            Assert.AreEqual("mov acc 1", output.Trim());
        }

        [Test]
        public void VanillaEmitter_EmitsLabel()
        {
            var parser = new Parser();
            var program = parser.Parse("loop:\nmov acc 1");
            var emitter = new VanillaEmitter();
            var output = emitter.Emit(program);
            var lines = output.Split('\n');
            Assert.IsTrue(lines[0].Contains("loop:"));
            Assert.IsTrue(lines[1].Contains("mov"));
        }
    }
}

