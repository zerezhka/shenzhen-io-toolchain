using System;
using System.Collections.Generic;
using System.Linq;
using Sio.TestRunner.Assert;
using Sio.TestRunner.Model;
using Sio.TestRunner.Output;

namespace Sio.TestRunner.Runtime
{
    /// <summary>
    /// Executes test cases and validates results.
    /// </summary>
    public sealed class TestExecutor
    {
        private readonly SimulatorHarness _harness;
        private readonly CycleExactMatcher _cycleExactMatcher;
        private readonly OrderOnlyMatcher _orderOnlyMatcher;
        private readonly DiffRenderer _diffRenderer;

        public TestExecutor()
        {
            _harness = new SimulatorHarness();
            _cycleExactMatcher = new CycleExactMatcher();
            _orderOnlyMatcher = new OrderOnlyMatcher();
            _diffRenderer = new DiffRenderer();
        }

        public sealed class TestResult
        {
            public string TestName { get; set; }
            public bool Passed { get; set; }
            public string FailureReason { get; set; }
            public string Diff { get; set; }
            public long CyclesConsumed { get; set; }
            public bool CycleLimitReached { get; set; }
        }

        /// <summary>
        /// Executes a test case and returns the result.
        /// </summary>
        public TestResult Execute(TestCase testCase, string testFileDirectory = null)
        {
            if (testCase == null)
                throw new ArgumentNullException(nameof(testCase));

            var result = new TestResult
            {
                TestName = testCase.Name
            };

            try
            {
                // Create port mapping
                var portMapping = new PortMapping(testCase);

                // Run simulation
                var runResult = _harness.Run(testCase, portMapping, testFileDirectory);
                result.CyclesConsumed = runResult.CyclesConsumed;
                result.CycleLimitReached = runResult.CycleLimitReached;

                // Note: Don't fail immediately on cycle limit - check outputs first!
                // The cycle limit is a safety timeout, not a strict requirement.
                // A program can pass if it produces correct outputs before hitting the limit,
                // or if it hits the limit but has already produced all expected outputs.

                // Validate each expected output
                var allPassed = true;
                var failures = new List<string>();

                foreach (var expectedOutput in testCase.ExpectedOutputs)
                {
                    // Get port index for this stream
                    var portIndex = portMapping.GetPortIndex(expectedOutput.StreamId);
                    if (!portIndex.HasValue)
                    {
                        failures.Add($"Stream '{expectedOutput.StreamId}' not mapped to any port");
                        allPassed = false;
                        continue;
                    }

                    // Get actual outputs for this port
                    if (!runResult.PortOutputs.TryGetValue(portIndex.Value, out var actualOutputs))
                    {
                        actualOutputs = new List<SimulatorHarness.PortOutput>();
                    }

                    // Match based on mode
                    IMatcher matcher = expectedOutput.Mode == "cycle-exact"
                        ? (IMatcher)_cycleExactMatcher
                        : _orderOnlyMatcher;

                    if (!matcher.Match(expectedOutput, actualOutputs, out var failureReason))
                    {
                        allPassed = false;
                        failures.Add(failureReason);

                        // Generate diff
                        var diff = expectedOutput.Mode == "cycle-exact"
                            ? _diffRenderer.RenderCycleExactDiff(expectedOutput, actualOutputs, expectedOutput.StreamId)
                            : _diffRenderer.RenderOrderOnlyDiff(expectedOutput, actualOutputs, expectedOutput.StreamId);
                        result.Diff = diff;
                    }
                }

                result.Passed = allPassed;
                if (!allPassed)
                {
                    result.FailureReason = string.Join("\n", failures);
                }

                return result;
            }
            catch (Exception ex)
            {
                result.Passed = false;
                result.FailureReason = $"Test execution failed: {ex.Message}";
                return result;
            }
        }
    }
}

