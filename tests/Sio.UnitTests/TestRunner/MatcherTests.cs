using System.Collections.Generic;
using NUnit.Framework;
using Sio.TestRunner.Assert;
using Sio.TestRunner.Model;
using Sio.TestRunner.Runtime;

namespace Sio.UnitTests.TestRunner
{
    public sealed class MatcherTests
    {
        [Test]
        public void CycleExactMatcher_ExactMatch()
        {
            var matcher = new CycleExactMatcher();
            var expected = new ExpectedOutput
            {
                Mode = "cycle-exact",
                Events = new List<OutputEvent>
                {
                    new OutputEvent { Cycle = 5, Value = 10 },
                    new OutputEvent { Cycle = 10, Value = 20 }
                }
            };
            var actual = new List<SimulatorHarness.PortOutput>
            {
                new SimulatorHarness.PortOutput { Cycle = 5, Value = 10 },
                new SimulatorHarness.PortOutput { Cycle = 10, Value = 20 }
            };

            var result = matcher.Match(expected, actual, out var reason);
            Assert.IsTrue(result);
            Assert.IsNull(reason);
        }

        [Test]
        public void CycleExactMatcher_Mismatch()
        {
            var matcher = new CycleExactMatcher();
            var expected = new ExpectedOutput
            {
                Mode = "cycle-exact",
                Events = new List<OutputEvent>
                {
                    new OutputEvent { Cycle = 5, Value = 10 }
                }
            };
            var actual = new List<SimulatorHarness.PortOutput>
            {
                new SimulatorHarness.PortOutput { Cycle = 5, Value = 20 }
            };

            var result = matcher.Match(expected, actual, out var reason);
            Assert.IsFalse(result);
            Assert.IsNotNull(reason);
            Assert.IsTrue(reason.Contains("Mismatched"));
        }

        [Test]
        public void OrderOnlyMatcher_ExactMatch()
        {
            var matcher = new OrderOnlyMatcher();
            var expected = new ExpectedOutput
            {
                Mode = "order-only",
                Values = new List<int> { 1, 2, 3 }
            };
            var actual = new List<SimulatorHarness.PortOutput>
            {
                new SimulatorHarness.PortOutput { Cycle = 5, Value = 1 },
                new SimulatorHarness.PortOutput { Cycle = 10, Value = 2 },
                new SimulatorHarness.PortOutput { Cycle = 15, Value = 3 }
            };

            var result = matcher.Match(expected, actual, out var reason);
            Assert.IsTrue(result);
            Assert.IsNull(reason);
        }

        [Test]
        public void OrderOnlyMatcher_Mismatch()
        {
            var matcher = new OrderOnlyMatcher();
            var expected = new ExpectedOutput
            {
                Mode = "order-only",
                Values = new List<int> { 1, 2, 3 }
            };
            var actual = new List<SimulatorHarness.PortOutput>
            {
                new SimulatorHarness.PortOutput { Cycle = 5, Value = 1 },
                new SimulatorHarness.PortOutput { Cycle = 10, Value = 3 },
                new SimulatorHarness.PortOutput { Cycle = 15, Value = 2 }
            };

            var result = matcher.Match(expected, actual, out var reason);
            Assert.IsFalse(result);
            Assert.IsNotNull(reason);
            Assert.IsTrue(reason.Contains("Mismatch"));
        }
    }
}

