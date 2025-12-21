using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// slp R/I - Sleep for the number of time units specified by the operand.
    /// </summary>
    public sealed class Slp : IInstruction
    {
        public string Name => "slp";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("slp requires 1 operand");

            var sleepCycles = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            if (sleepCycles < 0)
                sleepCycles = 0;

            context.Cpu.IsSleeping = true;
            context.Cpu.SleepCyclesRemaining = sleepCycles;

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "slp",
                context.Instruction.Operands[0]
            );

            // slp itself takes 1 cycle to execute, then sleep happens
            return 1;
        }
    }
}

