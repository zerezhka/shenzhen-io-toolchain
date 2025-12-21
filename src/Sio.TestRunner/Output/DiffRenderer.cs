using System.Collections.Generic;
using System.Linq;
using System.Text;
using Sio.TestRunner.Model;
using Sio.TestRunner.Runtime;

namespace Sio.TestRunner.Output
{
    /// <summary>
    /// Renders "LeetCode-like" diffs showing expected vs actual outputs.
    /// </summary>
    public sealed class DiffRenderer
    {
        /// <summary>
        /// Renders a diff for cycle-exact mismatch.
        /// </summary>
        public string RenderCycleExactDiff(
            ExpectedOutput expected,
            List<SimulatorHarness.PortOutput> actual,
            string streamId)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"Stream '{streamId}' (cycle-exact):");
            sb.AppendLine("");

            // Build maps
            var expectedMap = expected.Events.ToDictionary(e => e.Cycle, e => e.Value);
            var actualMap = actual.ToDictionary(a => a.Cycle, a => a.Value);

            // Get all cycles (union of expected and actual)
            var allCycles = expectedMap.Keys.Union(actualMap.Keys).OrderBy(c => c).ToList();

            sb.AppendLine("Cycle | Expected | Actual");
            sb.AppendLine("------|----------|-------");

            foreach (var cycle in allCycles)
            {
                var expectedValue = expectedMap.TryGetValue(cycle, out var exp) ? exp.ToString() : "-";
                var actualValue = actualMap.TryGetValue(cycle, out var act) ? act.ToString() : "-";
                var marker = expectedValue != actualValue ? " ✗" : "";

                sb.AppendLine($"{cycle,5} | {expectedValue,8} | {actualValue,6}{marker}");
            }

            return sb.ToString();
        }

        /// <summary>
        /// Renders a diff for order-only mismatch.
        /// </summary>
        public string RenderOrderOnlyDiff(
            ExpectedOutput expected,
            List<SimulatorHarness.PortOutput> actual,
            string streamId)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"Stream '{streamId}' (order-only):");
            sb.AppendLine("");

            var actualValues = actual.OrderBy(a => a.Cycle).Select(a => a.Value).ToList();

            sb.AppendLine($"Expected: [{string.Join(", ", expected.Values)}]");
            sb.AppendLine($"Actual:   [{string.Join(", ", actualValues)}]");
            sb.AppendLine("");

            // Show side-by-side comparison
            var maxLen = System.Math.Max(expected.Values.Count, actualValues.Count);
            sb.AppendLine("Index | Expected | Actual");
            sb.AppendLine("------|----------|-------");

            for (int i = 0; i < maxLen; i++)
            {
                var expectedVal = i < expected.Values.Count ? expected.Values[i].ToString() : "-";
                var actualVal = i < actualValues.Count ? actualValues[i].ToString() : "-";
                var marker = expectedVal != actualVal ? " ✗" : "";

                sb.AppendLine($"{i,5} | {expectedVal,8} | {actualVal,6}{marker}");
            }

            return sb.ToString();
        }
    }
}

