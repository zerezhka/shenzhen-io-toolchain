using System;
using System.IO;
using System.Linq;
using Sio.Cli.Output;
using Sio.TestRunner.IO;
using Sio.TestRunner.Runtime;

namespace Sio.Cli.Commands
{
    public sealed class TestCommand
    {
        private readonly ConsoleWriter _writer;

        public TestCommand(ConsoleWriter writer)
        {
            _writer = writer ?? throw new ArgumentNullException(nameof(writer));
        }

        public int Execute(string[] args)
        {
            if (args == null || args.Length < 1)
            {
                _writer.WriteErrorLine("sio test: missing test file");
                _writer.WriteErrorLine("Usage: sio test <test.yaml|test.json>");
                return ExitCodes.Usage;
            }

            var testFile = args[0];

            try
            {
                // Load test suite
                var loader = new TestLoader();
                var testSuite = loader.Load(testFile);

                _writer.WriteInfoLine($"Loaded test suite (format version: {testSuite.FormatVersion})");
                _writer.WriteInfoLine($"Running {testSuite.Cases.Count} test case(s)...");
                _writer.WriteInfoLine("");

                // Execute tests
                var executor = new TestExecutor();
                var testFileDirectory = Path.GetDirectoryName(Path.GetFullPath(testFile));
                var results = testSuite.Cases.Select(testCase => executor.Execute(testCase, testFileDirectory)).ToList();

                // Report results
                var passed = results.Count(r => r.Passed);
                var failed = results.Count - passed;

                foreach (var result in results)
                {
                    if (result.Passed)
                    {
                        _writer.WriteSuccessLine($"✓ {result.TestName} (cycles: {result.CyclesConsumed})");
                    }
                    else
                    {
                        _writer.WriteErrorLine($"✗ {result.TestName}");
                        if (!string.IsNullOrEmpty(result.FailureReason))
                        {
                            _writer.WriteErrorLine($"  {result.FailureReason}");
                        }
                        if (!string.IsNullOrEmpty(result.Diff))
                        {
                            _writer.WriteInfoLine("");
                            _writer.WriteInfoLine(result.Diff);
                        }
                    }
                }

                _writer.WriteInfoLine("");
                _writer.WriteInfoLine($"Results: {passed} passed, {failed} failed");

                // Return non-zero exit code if any test failed
                return failed > 0 ? ExitCodes.Error : ExitCodes.Ok;
            }
            catch (Exception ex)
            {
                _writer.WriteErrorLine($"sio test: error: {ex.Message}");
                return ExitCodes.Error;
            }
        }
    }
}

