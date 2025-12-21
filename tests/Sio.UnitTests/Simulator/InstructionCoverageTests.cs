using System.Linq;
using NUnit.Framework;
using Sio.Simulator.Isa;

namespace Sio.UnitTests.Simulator
{
    public sealed class InstructionCoverageTests
    {
        [Test]
        public void AllManifestInstructions_HaveImplementations()
        {
            // This test ensures that every instruction in the manifest has a corresponding
            // implementation.
            
            var manifestInstructions = InstructionSetManifest.AllInstructions;
            Assert.IsNotNull(manifestInstructions);
            Assert.Greater(manifestInstructions.Count, 0, "Manifest should contain instructions");
            
            var implementedInstructions = InstructionRegistry.GetAllInstructionNames().ToList();
            
            foreach (var instruction in manifestInstructions)
            {
                Assert.IsTrue(InstructionRegistry.IsImplemented(instruction),
                    $"Instruction '{instruction}' from manifest has no implementation");
            }
            
            // Verify we have all 15 instructions
            Assert.AreEqual(15, manifestInstructions.Count, "Should have 15 instructions total");
            Assert.AreEqual(15, implementedInstructions.Count, "Should have 15 implementations");
        }

        [Test]
        public void Manifest_ContainsExpectedInstructions()
        {
            var instructions = InstructionSetManifest.AllInstructions;
            
            // Verify basic instructions
            Assert.IsTrue(instructions.Contains("nop", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("mov", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("jmp", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("slp", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("slx", System.StringComparer.OrdinalIgnoreCase));
            
            // Verify test instructions
            Assert.IsTrue(instructions.Contains("teq", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("tgt", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("tlt", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("tcp", System.StringComparer.OrdinalIgnoreCase));
            
            // Verify arithmetic instructions
            Assert.IsTrue(instructions.Contains("add", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("sub", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("mul", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("not", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("dgt", System.StringComparer.OrdinalIgnoreCase));
            Assert.IsTrue(instructions.Contains("dst", System.StringComparer.OrdinalIgnoreCase));
        }

        [Test]
        public void Manifest_IsValidInstruction_Works()
        {
            Assert.IsTrue(InstructionSetManifest.IsValidInstruction("mov"));
            Assert.IsTrue(InstructionSetManifest.IsValidInstruction("MOV"));
            Assert.IsTrue(InstructionSetManifest.IsValidInstruction("add"));
            Assert.IsFalse(InstructionSetManifest.IsValidInstruction("invalid"));
            Assert.IsFalse(InstructionSetManifest.IsValidInstruction(""));
            Assert.IsFalse(InstructionSetManifest.IsValidInstruction(null));
        }
    }
}

