using System.Collections.Generic;
using System.Linq;
using System.Text;
using Sio.TestRunner.Model;
using Sio.TestRunner.Runtime;

namespace Sio.TestRunner.Assert
{
    /// <summary>
    /// Matches outputs by order only (ignoring cycle timestamps).
    /// </summary>
    public sealed class OrderOnlyMatcher : IMatcher
    {
        public bool Match(ExpectedOutput expected, List<SimulatorHarness.PortOutput> actual, out string failureReason)
        {
            if (expected.Mode != "order-only")
            {
                failureReason = "OrderOnlyMatcher can only match order-only mode";
                return false;
            }

            if (expected.Values == null || expected.Values.Count == 0)
            {
                failureReason = "No expected values defined";
                return false;
            }

            // Extract actual values in order (by cycle)
            var actualValues = actual.OrderBy(a => a.Cycle).Select(a => a.Value).ToList();

            // Compare sequences - actual can have MORE values than expected (e.g., infinite loops)
            if (actualValues.Count < expected.Values.Count)
            {
                failureReason = $"Expected at least {expected.Values.Count} values, got {actualValues.Count}";
                return false;
            }

            // Only compare the first N values (where N = expected count)
            var mismatches = new List<int>();
            for (int i = 0; i < expected.Values.Count; i++)
            {
                if (expected.Values[i] != actualValues[i])
                {
                    mismatches.Add(i);
                }
            }

            if (mismatches.Count > 0)
            {
                var sb = new StringBuilder();
                sb.AppendLine("Order-only mismatch:");
                sb.AppendLine($"  Expected: [{string.Join(", ", expected.Values)}]");
                sb.AppendLine($"  Actual (first {expected.Values.Count}): [{string.Join(", ", actualValues.Take(expected.Values.Count))}]");
                sb.AppendLine($"  Mismatches at indices: {string.Join(", ", mismatches)}");
                failureReason = sb.ToString();
                return false;
            }

            failureReason = null;
            return true;
        }
    }
}

