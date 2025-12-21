using System.Collections.Generic;
using System.Linq;
using System.Text;
using Sio.TestRunner.Model;
using Sio.TestRunner.Runtime;

namespace Sio.TestRunner.Assert
{
    /// <summary>
    /// Matches outputs with cycle-exact precision.
    /// </summary>
    public sealed class CycleExactMatcher : IMatcher
    {
        public bool Match(ExpectedOutput expected, List<SimulatorHarness.PortOutput> actual, out string failureReason)
        {
            if (expected.Mode != "cycle-exact")
            {
                failureReason = "CycleExactMatcher can only match cycle-exact mode";
                return false;
            }

            if (expected.Events == null || expected.Events.Count == 0)
            {
                failureReason = "No expected events defined";
                return false;
            }

            // Build expected events map (cycle -> value)
            var expectedMap = expected.Events.ToDictionary(e => e.Cycle, e => e.Value);

            // Build actual events map (cycle -> value)
            var actualMap = actual.ToDictionary(a => a.Cycle, a => a.Value);

            // Check for missing or extra events
            var missingCycles = expectedMap.Keys.Except(actualMap.Keys).OrderBy(c => c).ToList();
            var extraCycles = actualMap.Keys.Except(expectedMap.Keys).OrderBy(c => c).ToList();
            var mismatchedCycles = expectedMap.Keys
                .Intersect(actualMap.Keys)
                .Where(c => expectedMap[c] != actualMap[c])
                .OrderBy(c => c)
                .ToList();

            if (missingCycles.Count > 0 || extraCycles.Count > 0 || mismatchedCycles.Count > 0)
            {
                var sb = new StringBuilder();
                sb.AppendLine("Cycle-exact mismatch:");

                if (missingCycles.Count > 0)
                {
                    sb.AppendLine($"  Missing cycles: {string.Join(", ", missingCycles)}");
                }

                if (extraCycles.Count > 0)
                {
                    sb.AppendLine($"  Extra cycles: {string.Join(", ", extraCycles)}");
                }

                if (mismatchedCycles.Count > 0)
                {
                    sb.AppendLine("  Mismatched values:");
                    foreach (var cycle in mismatchedCycles)
                    {
                        sb.AppendLine($"    Cycle {cycle}: expected {expectedMap[cycle]}, got {actualMap[cycle]}");
                    }
                }

                failureReason = sb.ToString();
                return false;
            }

            failureReason = null;
            return true;
        }
    }
}

