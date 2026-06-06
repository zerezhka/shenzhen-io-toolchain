using System;
using System.IO;
using System.Linq;
using Sio.Cli.Output;
using Sio.Simulator.Cpu;
using Sio.Simulator.Isa;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Runtime;
using Sio.Simulator.Trace;

namespace Sio.Cli.Commands
{
    public sealed class SimulateCommand
    {
        private readonly ConsoleWriter _writer;

        public SimulateCommand(ConsoleWriter writer)
        {
            _writer = writer ?? throw new ArgumentNullException(nameof(writer));
        }

        public int Execute(string[] args)
        {
            if (args == null || args.Length < 1)
            {
                _writer.WriteErrorLine("sio simulate: missing input file");
                _writer.WriteErrorLine("Usage: sio simulate <program.asm> [--cycles <N>] [--trace]");
                return ExitCodes.Usage;
            }

            // Default cap so programs with infinite loops (e.g. `jmp loop`) still
            // terminate and produce output when no explicit limit is given.
            const long DefaultCycleLimit = 1000;

            var programFile = args[0];
            long? cycleLimit = null;
            bool traceEnabled = false;

            // Parse options
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "--cycles" && i + 1 < args.Length)
                {
                    if (long.TryParse(args[i + 1], out var cycles))
                    {
                        cycleLimit = cycles;
                        i++;
                    }
                }
                else if (args[i] == "--trace")
                {
                    traceEnabled = true;
                }
            }

            try
            {
                // Load and parse program
                if (!File.Exists(programFile))
                {
                    _writer.WriteErrorLine($"sio simulate: file not found: {programFile}");
                    return ExitCodes.Error;
                }

                var programText = File.ReadAllText(programFile);
                var parser = new ProgramParser();
                var program = parser.Parse(programText);

                // Create simulation components
                var cpu = new CpuState(hasDatRegister: true); // Default to MC6000
                var ports = new PortBus(6); // Default to 6 ports (MC6000)
                var effectiveLimit = cycleLimit ?? DefaultCycleLimit;
                var cycles = new CycleController(effectiveLimit);
                var tracer = traceEnabled ? new Tracer(enabled: true) : new Tracer(enabled: false);
                var engine = new StepEngine(cpu, ports, cycles, tracer, program);

                // Run simulation
                engine.Run();

                // Output results
                if (traceEnabled)
                {
                    _writer.WriteInfoLine("=== Trace ===");
                    foreach (var evt in tracer.Events)
                    {
                        _writer.WriteInfoLine(evt.ToString());
                    }
                    _writer.WriteInfoLine("");
                }

                _writer.WriteInfoLine($"=== Final State ===");
                _writer.WriteInfoLine($"Cycles: {cycles.CurrentCycle}");
                _writer.WriteInfoLine($"ACC: {cpu.Acc}");
                if (cpu.Dat.HasValue)
                {
                    _writer.WriteInfoLine($"DAT: {cpu.Dat.Value}");
                }

                // Output port values
                _writer.WriteInfoLine($"Port outputs:");
                for (int i = 0; i < ports.PortCount; i++)
                {
                    if (!ports.IsInputMode(i))
                    {
                        _writer.WriteInfoLine($"  p{i}: {ports.GetOutputValue(i)}");
                    }
                }

                if (cycles.IsLimitReached)
                {
                    if (cycleLimit.HasValue)
                    {
                        _writer.WriteErrorLine($"Cycle limit ({cycleLimit}) reached");
                        return ExitCodes.Error;
                    }

                    // Hit the implicit default limit: inform the user, not an error.
                    _writer.WriteInfoLine(
                        $"Stopped at default cycle limit ({DefaultCycleLimit}). Use --cycles <N> to run longer.");
                }

                return ExitCodes.Ok;
            }
            catch (Exception ex)
            {
                _writer.WriteErrorLine($"sio simulate: error: {ex.Message}");
                return ExitCodes.Error;
            }
        }
    }
}

