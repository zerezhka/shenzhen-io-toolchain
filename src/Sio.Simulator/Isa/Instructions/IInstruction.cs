using Sio.Simulator.Cpu;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Runtime;
using Sio.Simulator.Trace;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// Represents the execution context for an instruction.
    /// </summary>
    public sealed class ExecutionContext
    {
        public CpuState Cpu { get; set; }
        public PortBus Ports { get; set; }
        public CycleController Cycles { get; set; }
        public Tracer Tracer { get; set; }
        public ProgramParser.ExecutableProgram Program { get; set; }
        public ProgramParser.ExecutableInstruction Instruction { get; set; }
    }

    /// <summary>
    /// Interface for instruction execution handlers.
    /// </summary>
    public interface IInstruction
    {
        /// <summary>
        /// Instruction name (e.g., "mov", "add").
        /// </summary>
        string Name { get; }

        /// <summary>
        /// Executes the instruction.
        /// </summary>
        /// <param name="context">Execution context</param>
        /// <returns>Number of cycles consumed (typically 1, but can vary)</returns>
        int Execute(ExecutionContext context);
    }
}

