using System;
using Sio.Simulator.Cpu;
using Sio.Simulator.Isa;
using Sio.Simulator.Isa.Instructions;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Trace;

namespace Sio.Simulator.Runtime
{
    /// <summary>
    /// Orchestrates deterministic execution of a program.
    /// </summary>
    public sealed class StepEngine
    {
        private readonly CpuState _cpu;
        private readonly PortBus _ports;
        private readonly CycleController _cycles;
        private readonly Tracer _tracer;
        private readonly ProgramParser.ExecutableProgram _program;

        public StepEngine(
            CpuState cpu,
            PortBus ports,
            CycleController cycles,
            Tracer tracer,
            ProgramParser.ExecutableProgram program)
        {
            _cpu = cpu ?? throw new ArgumentNullException(nameof(cpu));
            _ports = ports ?? throw new ArgumentNullException(nameof(ports));
            _cycles = cycles ?? throw new ArgumentNullException(nameof(cycles));
            _tracer = tracer;
            _program = program ?? throw new ArgumentNullException(nameof(program));
        }

        /// <summary>
        /// Executes one step of the program.
        /// </summary>
        /// <returns>True if execution should continue, false if it should stop</returns>
        public bool Step()
        {
            // Check if cycle limit reached
            if (_cycles.IsLimitReached)
                return false;

            // Check if program counter is out of bounds
            if (_cpu.Pc < 0 || _cpu.Pc >= _program.Instructions.Count)
                return false;

            // Check if CPU is sleeping
            if (_cpu.IsSleeping)
            {
                _cpu.SleepCyclesRemaining--;
                if (_cpu.SleepCyclesRemaining <= 0)
                {
                    _cpu.IsSleeping = false;
                }
                _cycles.Advance(1);
                return true;
            }

            // Check if waiting for XBus
            if (_cpu.IsWaitingForXBus && _cpu.WaitingXBusPin.HasValue)
            {
                var pinIndex = _cpu.WaitingXBusPin.Value;
                if (_ports.HasInputAvailable(pinIndex))
                {
                    _cpu.IsWaitingForXBus = false;
                    _cpu.WaitingXBusPin = null;
                }
                else
                {
                    _cycles.Advance(1);
                    return true;
                }
            }

            // Get current instruction
            var instruction = _program.Instructions[_cpu.Pc];
            var originalPc = _cpu.Pc;

            // Handle labels (they don't execute, just advance PC)
            if (string.IsNullOrEmpty(instruction.Instruction))
            {
                _cpu.Pc++;
                return true;
            }

            // Check conditional execution
            if (instruction.IsConditional)
            {
                // If in equal state (from tcp), both + and - are disabled
                if (_cpu.ConditionalEqualState)
                {
                    // Skip this instruction
                    _cpu.Pc++;
                    return true;
                }

                var shouldExecute = instruction.ConditionalPositive
                    ? _cpu.ConditionalPositiveEnabled
                    : !_cpu.ConditionalPositiveEnabled;

                if (!shouldExecute)
                {
                    // Skip this instruction
                    _cpu.Pc++;
                    return true;
                }
            }

            // Get instruction handler
            var handler = InstructionRegistry.GetInstruction(instruction.Instruction);
            if (handler == null)
            {
                throw new InvalidOperationException($"Unsupported instruction: {instruction.Instruction} at line {instruction.LineNumber}");
            }

            // Create execution context
            var context = new ExecutionContext
            {
                Cpu = _cpu,
                Ports = _ports,
                Cycles = _cycles,
                Tracer = _tracer,
                Program = _program,
                Instruction = instruction
            };

            // Execute instruction
            var cyclesConsumed = handler.Execute(context);
            _cycles.Advance(cyclesConsumed);

            // Advance program counter (unless instruction modified it, like jmp)
            // If PC wasn't modified by the instruction, advance it
            if (_cpu.Pc == originalPc)
            {
                _cpu.Pc++;
            }

            return true;
        }

        /// <summary>
        /// Runs the program until completion or cycle limit.
        /// </summary>
        public void Run()
        {
            while (Step())
            {
                // Continue execution
            }
        }
    }
}

