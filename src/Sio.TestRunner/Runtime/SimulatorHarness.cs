using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Sio.Simulator.Cpu;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Runtime;
using Sio.Simulator.Trace;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.Runtime
{
    /// <summary>
    /// Wraps the simulator to run test cases with input streams and collect outputs.
    /// </summary>
    public sealed class SimulatorHarness
    {
        public sealed class RunResult
        {
            public Dictionary<int, List<PortOutput>> PortOutputs { get; set; }
            public long CyclesConsumed { get; set; }
            public bool CycleLimitReached { get; set; }

            public RunResult()
            {
                PortOutputs = new Dictionary<int, List<PortOutput>>();
            }
        }

        public sealed class PortOutput
        {
            public long Cycle { get; set; }
            public int Value { get; set; }
        }

        /// <summary>
        /// Runs a test case and collects outputs.
        /// </summary>
        public RunResult Run(TestCase testCase, PortMapping portMapping, string testFileDirectory = null)
        {
            if (testCase == null)
                throw new ArgumentNullException(nameof(testCase));
            if (portMapping == null)
                throw new ArgumentNullException(nameof(portMapping));

            // Resolve program path (handle relative paths)
            var programPath = testCase.Program.Path;
            if (!Path.IsPathRooted(programPath) && !string.IsNullOrEmpty(testFileDirectory))
            {
                programPath = Path.Combine(testFileDirectory, programPath);
            }

            // Load program
            if (!File.Exists(programPath))
            {
                throw new FileNotFoundException($"Program file not found: {programPath}");
            }

            var programText = File.ReadAllText(programPath);
            var parser = new ProgramParser();
            var program = parser.Parse(programText);

            // Create simulation components
            var cpu = new CpuState(hasDatRegister: true); // Default to MC6000
            var ports = new PortBus(testCase.Ports.Count);
            var cycles = new CycleController(testCase.CycleLimit);
            var tracer = new Tracer(enabled: false); // Don't trace during test runs
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // Queue input streams
            var inputQueues = new Dictionary<string, Queue<int>>();
            foreach (var inputStream in testCase.Inputs)
            {
                var queue = new Queue<int>(inputStream.Samples);
                inputQueues[inputStream.Id] = queue;

                // Map stream to port and queue inputs
                var portIndex = portMapping.GetPortIndex(inputStream.Id);
                if (portIndex.HasValue)
                {
                    foreach (var sample in inputStream.Samples)
                    {
                        ports.QueueInput(portIndex.Value, sample);
                    }
                }
            }

            // Track port outputs
            var portOutputs = new Dictionary<int, List<PortOutput>>();
            var lastPortWriteGeneration = new Dictionary<int, int>();
            
            // Initialize write generations to avoid recording initial state
            for (int i = 0; i < ports.PortCount; i++)
            {
                lastPortWriteGeneration[i] = ports.GetWriteGeneration(i);
            }

            // Run simulation
            while (true)
            {
                // Capture cycle BEFORE step (this is the cycle when the instruction will execute)
                var cycleBeforeStep = cycles.CurrentCycle;
                
                if (!engine.Step())
                {
                    break;
                }

                // Check for port writes by comparing write generation
                // Use the cycle BEFORE the step, since that's when the instruction executed
                for (int i = 0; i < ports.PortCount; i++)
                {
                    if (!ports.IsInputMode(i))
                    {
                        var currentGeneration = ports.GetWriteGeneration(i);
                        if (!lastPortWriteGeneration.TryGetValue(i, out var lastGeneration) || currentGeneration > lastGeneration)
                        {
                            // Port was written to, record output
                            if (!portOutputs.ContainsKey(i))
                            {
                                portOutputs[i] = new List<PortOutput>();
                            }
                            portOutputs[i].Add(new PortOutput
                            {
                                Cycle = cycleBeforeStep,
                                Value = ports.GetOutputValue(i)
                            });
                            lastPortWriteGeneration[i] = currentGeneration;
                        }
                    }
                }

                if (cycles.IsLimitReached)
                {
                    break;
                }
            }

            return new RunResult
            {
                PortOutputs = portOutputs,
                CyclesConsumed = cycles.CurrentCycle,
                CycleLimitReached = cycles.IsLimitReached
            };
        }
    }
}

