using NUnit.Framework;
using Sio.TestRunner.Model;

namespace Sio.UnitTests.TestRunner
{
    public sealed class TestDefinitionModelTests
    {
        [Test]
        public void TestSuite_CanBeCreated()
        {
            var suite = new TestSuite
            {
                FormatVersion = "1.0",
                Cases = new System.Collections.Generic.List<TestCase>
                {
                    new TestCase
                    {
                        Name = "Test 1",
                        Program = new ProgramReference { Path = "test.asm" },
                        CycleLimit = 100,
                        Ports = new PortConfiguration { Count = 6 }
                    }
                }
            };

            Assert.AreEqual("1.0", suite.FormatVersion);
            Assert.AreEqual(1, suite.Cases.Count);
            Assert.AreEqual("Test 1", suite.Cases[0].Name);
        }

        [Test]
        public void TestCase_RequiredFields()
        {
            var testCase = new TestCase
            {
                Name = "Required Fields Test",
                Program = new ProgramReference { Path = "program.asm" },
                CycleLimit = 50,
                Ports = new PortConfiguration { Count = 4 }
            };

            Assert.IsNotNull(testCase.Name);
            Assert.IsNotNull(testCase.Program);
            Assert.IsNotNull(testCase.Ports);
            Assert.Greater(testCase.CycleLimit, 0);
            Assert.Greater(testCase.Ports.Count, 0);
        }

        [Test]
        public void ExpectedOutput_CycleExact()
        {
            var output = new ExpectedOutput
            {
                StreamId = "output",
                Mode = "cycle-exact",
                Events = new System.Collections.Generic.List<OutputEvent>
                {
                    new OutputEvent { Cycle = 5, Value = 10 },
                    new OutputEvent { Cycle = 10, Value = 20 }
                }
            };

            Assert.AreEqual("cycle-exact", output.Mode);
            Assert.AreEqual(2, output.Events.Count);
            Assert.AreEqual(5, output.Events[0].Cycle);
            Assert.AreEqual(10, output.Events[0].Value);
        }

        [Test]
        public void ExpectedOutput_OrderOnly()
        {
            var output = new ExpectedOutput
            {
                StreamId = "output",
                Mode = "order-only",
                Values = new System.Collections.Generic.List<int> { 1, 2, 3, 4 }
            };

            Assert.AreEqual("order-only", output.Mode);
            Assert.AreEqual(4, output.Values.Count);
        }
    }
}

