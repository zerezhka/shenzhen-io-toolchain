using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// not - If the value in acc is 0, store a value of 100 in acc. Otherwise, store a value of 0 in acc.
    /// </summary>
    public sealed class Not : IInstruction
    {
        public string Name => "not";

        public int Execute(ExecutionContext context)
        {
            if (context.Cpu.Acc == 0)
            {
                context.Cpu.SetAcc(100);
            }
            else
            {
                context.Cpu.SetAcc(0);
            }

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "not",
                ""
            );

            return 1;
        }
    }
}

