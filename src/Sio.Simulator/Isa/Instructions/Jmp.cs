using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// jmp L - Jump to the instruction following the specified label.
    /// </summary>
    public sealed class Jmp : IInstruction
    {
        public string Name => "jmp";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("jmp requires 1 operand (label)");

            var labelName = context.Instruction.Operands[0];

            // Resolve label to program counter
            if (!context.Program.Labels.TryGetValue(labelName, out var targetPc))
            {
                throw new System.ArgumentException($"Label '{labelName}' not found");
            }

            // Set program counter to target
            context.Cpu.Pc = targetPc;

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "jmp",
                labelName
            );

            return 1; // jmp takes 1 cycle
        }
    }
}

