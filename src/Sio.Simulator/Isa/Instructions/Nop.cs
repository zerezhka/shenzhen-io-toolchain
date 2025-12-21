using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// nop - No operation (has no effect).
    /// </summary>
    public sealed class Nop : IInstruction
    {
        public string Name => "nop";

        public int Execute(ExecutionContext context)
        {
            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "nop",
                ""
            );

            return 1; // nop takes 1 cycle
        }
    }
}

