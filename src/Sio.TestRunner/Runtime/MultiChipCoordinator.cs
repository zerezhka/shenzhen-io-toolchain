using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Sio.Simulator.Cpu;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Runtime;
using Sio.Simulator.Trace;
using Sio.TestRunner.IO;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.Runtime
{
    /// <summary>
    /// Coordinates execution of multiple chips connected together.
    /// </summary>
    public sealed class MultiChipCoordinator
    {
        private sealed class ChipInstance
        {
            public string Id { get; set; }
            public CpuState Cpu { get; set; }
            public PortBus Ports { get; set; }
            public StepEngine Engine { get; set; }
            public Dictionary<string, int> PortNameToIndex { get; set; }
        }

        private sealed class Connection
        {
            public ChipInstance FromChip { get; set; }
            public int FromPort { get; set; }
            public ChipInstance ToChip { get; set; }
            public int ToPort { get; set; }
            public string Type { get; set; }  // "simple" or "xbus"
        }

        public sealed class RunResult
        {
            public Dictionary<string, List<PortOutput>> PortOutputs { get; set; }
            public long CyclesConsumed { get; set; }
            public bool CycleLimitReached { get; set; }

            public RunResult()
            {
                PortOutputs = new Dictionary<string, List<PortOutput>>();
            }
        }

        public sealed class PortOutput
        {
            public long Cycle { get; set; }
            public int Value { get; set; }
        }

        public RunResult Run(TestCase testCase, string testFileDirectory = null)
        {
            if (testCase == null)
                throw new ArgumentNullException(nameof(testCase));

            if (!testCase.IsMultiChip)
                throw new InvalidOperationException("Test case is not configured for multi-chip mode");

            // Check if we need to load from save file
            List<ChipDefinition> chips;
            List<ConnectionDefinition> connections;

            if (!string.IsNullOrEmpty(testCase.SaveFile))
            {
                // Load from save file
                var saveFilePath = testCase.SaveFile;
                if (!Path.IsPathRooted(saveFilePath) && !string.IsNullOrEmpty(testFileDirectory))
                {
                    saveFilePath = Path.Combine(testFileDirectory, saveFilePath);
                }

                var (loadedChips, loadedConnections) = LoadFromSaveFile(saveFilePath, testFileDirectory);
                chips = loadedChips;
                connections = loadedConnections;
            }
            else
            {
                // Use explicitly defined chips and connections
                chips = testCase.Chips;
                connections = testCase.Connections ?? new List<ConnectionDefinition>();
            }

            // Create cycle controller (shared by all chips)
            var cycles = new CycleController(testCase.CycleLimit);

            // Create chip instances
            var chipInstances = new Dictionary<string, ChipInstance>();
            foreach (var chipDef in chips)
            {
                var instance = CreateChipInstance(chipDef, cycles, testFileDirectory);
                chipInstances[chipDef.Id] = instance;
            }

            // Parse and create connections
            var connectionList = new List<Connection>();
            foreach (var connDef in connections)
            {
                var conn = ParseConnection(connDef, chipInstances);
                connectionList.Add(conn);
            }

            // Queue external inputs
            foreach (var inputStream in testCase.Inputs)
            {
                var (chipId, portName) = ParsePortReference(inputStream.Target ?? inputStream.Id);
                if (!chipInstances.TryGetValue(chipId, out var chip))
                    throw new InvalidOperationException($"Unknown chip: {chipId}");

                if (!chip.PortNameToIndex.TryGetValue(portName, out var portIndex))
                    throw new InvalidOperationException($"Unknown port: {chipId}.{portName}");

                foreach (var sample in inputStream.Samples)
                {
                    chip.Ports.QueueInput(portIndex, sample);
                }
            }

            // Track outputs
            var portOutputs = new Dictionary<string, List<PortOutput>>();
            var lastWriteGenerations = new Dictionary<string, int>();

            // Initialize write generations for output ports
            foreach (var expectedOutput in testCase.ExpectedOutputs)
            {
                var portRef = expectedOutput.Source ?? expectedOutput.StreamId;
                var (chipId, portName) = ParsePortReference(portRef);
                
                if (!chipInstances.TryGetValue(chipId, out var chip))
                    throw new InvalidOperationException($"Unknown chip: {chipId}");
                
                if (!chip.PortNameToIndex.TryGetValue(portName, out var portIndex))
                    throw new InvalidOperationException($"Unknown port: {chipId}.{portName}");

                var key = $"{chipId}.{portName}";
                lastWriteGenerations[key] = chip.Ports.GetWriteGeneration(portIndex);
                portOutputs[key] = new List<PortOutput>();
            }

            // Run simulation
            while (true)
            {
                // Step all chips once
                var anyProgress = false;
                foreach (var chip in chipInstances.Values)
                {
                    try
                    {
                        chip.Engine.Step();
                        anyProgress = true;
                    }
                    catch (Exception)
                    {
                        // Chip halted or errored, continue with others
                    }
                }

                // Transfer values through connections
                foreach (var conn in connectionList)
                {
                    TransferConnection(conn);
                }

                // Record outputs
                foreach (var expectedOutput in testCase.ExpectedOutputs)
                {
                    var portRef = expectedOutput.Source ?? expectedOutput.StreamId;
                    var (chipId, portName) = ParsePortReference(portRef);
                    var chip = chipInstances[chipId];
                    var portIndex = chip.PortNameToIndex[portName];
                    var key = $"{chipId}.{portName}";

                    var currentGen = chip.Ports.GetWriteGeneration(portIndex);
                    if (currentGen != lastWriteGenerations[key])
                    {
                        var value = chip.Ports.ReadPort(portIndex);
                        portOutputs[key].Add(new PortOutput
                        {
                            Cycle = cycles.CurrentCycle,
                            Value = value
                        });
                        lastWriteGenerations[key] = currentGen;
                    }
                }

                // Advance cycle
                cycles.Advance(1);

                // Check termination conditions
                if (!anyProgress || cycles.IsLimitReached)
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

        private ChipInstance CreateChipInstance(ChipDefinition chipDef, CycleController cycles, string testFileDirectory)
        {
            // Resolve program path
            var programPath = chipDef.Program;
            if (!Path.IsPathRooted(programPath) && !string.IsNullOrEmpty(testFileDirectory))
            {
                programPath = Path.Combine(testFileDirectory, programPath);
            }

            if (!File.Exists(programPath))
            {
                throw new FileNotFoundException($"Program file not found: {programPath}");
            }

            // Parse program
            var programText = File.ReadAllText(programPath);
            var parser = new ProgramParser();
            var program = parser.Parse(programText);

            // Determine chip capabilities
            bool hasDatRegister = chipDef.Type == "MC6000";
            int portCount = chipDef.Type == "MC4000" ? 4 : 6;  // MC4000: p0-p1, x0-x1; MC6000: p0-p1, x0-x2

            // Create components
            var cpu = new CpuState(hasDatRegister);
            var ports = new PortBus(portCount);
            var tracer = new Tracer(enabled: false);
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // Build port name mapping
            var portNameToIndex = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            portNameToIndex["p0"] = 0;
            portNameToIndex["p1"] = 1;
            portNameToIndex["x0"] = 2;
            portNameToIndex["x1"] = 3;
            if (chipDef.Type == "MC6000")
            {
                portNameToIndex["x2"] = 4;
            }

            return new ChipInstance
            {
                Id = chipDef.Id,
                Cpu = cpu,
                Ports = ports,
                Engine = engine,
                PortNameToIndex = portNameToIndex
            };
        }

        private Connection ParseConnection(ConnectionDefinition connDef, Dictionary<string, ChipInstance> chips)
        {
            var (fromChipId, fromPortName) = ParsePortReference(connDef.From);
            var (toChipId, toPortName) = ParsePortReference(connDef.To);

            if (!chips.TryGetValue(fromChipId, out var fromChip))
                throw new InvalidOperationException($"Unknown chip: {fromChipId}");
            
            if (!chips.TryGetValue(toChipId, out var toChip))
                throw new InvalidOperationException($"Unknown chip: {toChipId}");

            if (!fromChip.PortNameToIndex.TryGetValue(fromPortName, out var fromPort))
                throw new InvalidOperationException($"Unknown port: {fromChipId}.{fromPortName}");

            if (!toChip.PortNameToIndex.TryGetValue(toPortName, out var toPort))
                throw new InvalidOperationException($"Unknown port: {toChipId}.{toPortName}");

            return new Connection
            {
                FromChip = fromChip,
                FromPort = fromPort,
                ToChip = toChip,
                ToPort = toPort,
                Type = connDef.Type ?? "simple"
            };
        }

        private (string chipId, string portName) ParsePortReference(string portRef)
        {
            // Format: "chip1.p0" or "chip1.x1"
            var parts = portRef.Split('.');
            if (parts.Length != 2)
                throw new ArgumentException($"Invalid port reference: {portRef}. Expected format: 'chipId.portName'");

            return (parts[0], parts[1]);
        }

        private void TransferConnection(Connection conn)
        {
            // For simple connections, just copy the value
            // For XBus, this is a simplified model (real XBus requires blocking coordination)
            
            try
            {
                // Check if source port has a value available
                var value = conn.FromChip.Ports.ReadPort(conn.FromPort);
                
                // Write to destination port (queue as input)
                conn.ToChip.Ports.QueueInput(conn.ToPort, value);
            }
            catch
            {
                // Port not ready or no value - skip this transfer
            }
        }

        private (List<ChipDefinition>, List<ConnectionDefinition>) LoadFromSaveFile(string saveFilePath, string testFileDirectory)
        {
            var saveFileParser = new SaveFileParser();
            var saveFile = saveFileParser.Parse(saveFilePath);

            // Convert chips
            var chips = new List<ChipDefinition>();
            var tempDir = Path.GetTempPath();
            var sessionId = Guid.NewGuid().ToString("N").Substring(0, 8);

            foreach (var chipInfo in saveFile.Chips)
            {
                // Skip puzzle-provided chips (they're typically ROM or I/O)
                if (chipInfo.IsPuzzleProvided)
                    continue;

                // Skip non-programmable components (BRIDGE, NOTE, ROM, etc.)
                var simulatorType = chipInfo.GetSimulatorType();
                if (simulatorType == null)
                    continue;

                // Write chip code to temporary file
                var tempFileName = $"temp_{sessionId}_{chipInfo.Id}.asm";
                var tempFilePath = Path.Combine(tempDir, tempFileName);
                File.WriteAllLines(tempFilePath, chipInfo.CodeLines);

                chips.Add(new ChipDefinition
                {
                    Id = chipInfo.Id,
                    Type = simulatorType,
                    Program = tempFilePath
                });
            }

            // Resolve connections from traces
            var connectionResolver = new ConnectionResolver();
            var resolvedConnections = connectionResolver.Resolve(saveFile);

            var connections = resolvedConnections.Select(c => new ConnectionDefinition
            {
                From = $"{c.FromChipId}.{c.FromPort}",
                To = $"{c.ToChipId}.{c.ToPort}",
                Type = c.Type
            }).ToList();

            return (chips, connections);
        }
    }
}

