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
        private readonly MultiChipCoordinator _multiChipCoordinator;
        private readonly CycleExactMatcher _cycleExactMatcher;
        private readonly OrderOnlyMatcher _orderOnlyMatcher;
        private readonly DiffRenderer _diffRenderer;

        public TestExecutor()
        {
            _harness = new SimulatorHarness();
            _multiChipCoordinator = new MultiChipCoordinator();
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
                // Check if this is a multi-chip test
                if (testCase.IsMultiChip)
                {
                    return ExecuteMultiChip(testCase, testFileDirectory);
                }
                else
                {
                    return ExecuteSingleChip(testCase, testFileDirectory);
                }
            }
            catch (Exception ex)
            {
                result.Passed = false;
                result.FailureReason = $"Test execution failed: {ex.Message}";
                return result;
            }
        }

        private TestResult ExecuteSingleChip(TestCase testCase, string testFileDirectory)
        {
            var result = new TestResult
            {
                TestName = testCase.Name
            };

            // Create port mapping
            var portMapping = new PortMapping(testCase);

            // Run simulation
            var runResult = _harness.Run(testCase, portMapping, testFileDirectory);
            result.CyclesConsumed = runResult.CyclesConsumed;
            result.CycleLimitReached = runResult.CycleLimitReached;

            // Validate outputs
            ValidateOutputs(testCase, runResult.PortOutputs, portMapping, result);
            return result;
        }

        private TestResult ExecuteMultiChip(TestCase testCase, string testFileDirectory)
        {
            var result = new TestResult
            {
                TestName = testCase.Name
            };

            // Run multi-chip simulation
            var runResult = _multiChipCoordinator.Run(testCase, testFileDirectory);
            result.CyclesConsumed = runResult.CyclesConsumed;
            result.CycleLimitReached = runResult.CycleLimitReached;

            // Validate outputs (multi-chip version)
            ValidateMultiChipOutputs(testCase, runResult.PortOutputs, result);
            return result;
        }

        private void ValidateOutputs(TestCase testCase, Dictionary<int, List<SimulatorHarness.PortOutput>> actualOutputs, PortMapping portMapping, TestResult result)
        {
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
                if (!actualOutputs.TryGetValue(portIndex.Value, out var portActualOutputs))
                {
                    portActualOutputs = new List<SimulatorHarness.PortOutput>();
                }

                // Match based on mode
                IMatcher matcher = expectedOutput.Mode == "cycle-exact"
                    ? (IMatcher)_cycleExactMatcher
                    : _orderOnlyMatcher;

                if (!matcher.Match(expectedOutput, portActualOutputs, out var failureReason))
                {
                    allPassed = false;
                    failures.Add(failureReason);

                    // Generate diff
                    var diff = expectedOutput.Mode == "cycle-exact"
                        ? _diffRenderer.RenderCycleExactDiff(expectedOutput, portActualOutputs, expectedOutput.StreamId)
                        : _diffRenderer.RenderOrderOnlyDiff(expectedOutput, portActualOutputs, expectedOutput.StreamId);
                    result.Diff = diff;
                }
            }

            result.Passed = allPassed;
            if (!allPassed)
            {
                result.FailureReason = string.Join("\n", failures);
            }
        }

        private void ValidateMultiChipOutputs(TestCase testCase, Dictionary<string, List<MultiChipCoordinator.PortOutput>> actualOutputs, TestResult result)
        {
            var allPassed = true;
            var failures = new List<string>();

            foreach (var expectedOutput in testCase.ExpectedOutputs)
            {
                var portRef = expectedOutput.Source ?? expectedOutput.StreamId;

                // Get actual outputs for this port
                if (!actualOutputs.TryGetValue(portRef, out var portActualOutputs))
                {
                    portActualOutputs = new List<MultiChipCoordinator.PortOutput>();
                }

                // Convert MultiChipCoordinator.PortOutput to SimulatorHarness.PortOutput for matcher
                var convertedOutputs = portActualOutputs.Select(po => new SimulatorHarness.PortOutput
                {
                    Cycle = po.Cycle,
                    Value = po.Value
                }).ToList();

                // Match based on mode
                IMatcher matcher = expectedOutput.Mode == "cycle-exact"
                    ? (IMatcher)_cycleExactMatcher
                    : _orderOnlyMatcher;

                if (!matcher.Match(expectedOutput, convertedOutputs, out var failureReason))
                {
                    allPassed = false;
                    failures.Add(failureReason);

                    // Generate diff
                    var diff = expectedOutput.Mode == "cycle-exact"
                        ? _diffRenderer.RenderCycleExactDiff(expectedOutput, convertedOutputs, portRef)
                        : _diffRenderer.RenderOrderOnlyDiff(expectedOutput, convertedOutputs, portRef);
                    result.Diff = diff;
                }
            }

            result.Passed = allPassed;
            if (!allPassed)
            {
                result.FailureReason = string.Join("\n", failures);
            }
        }
    }
}

