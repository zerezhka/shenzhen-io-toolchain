using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// teq R/I R/I - Test if the value of the first operand (A) is equal to the value of the second operand (B).
    /// If A == B: enables '+' instructions, disables '-' instructions
    /// If A != B: disables '+' instructions, enables '-' instructions
    /// </summary>
    public sealed class Teq : IInstruction
    {
        public string Name => "teq";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("teq requires 2 operands");

            // Resolve both operands
            var operandA = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            var operandB = Decoder.ResolveOperand(
                context.Instruction.Operands[1],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Set conditional execution state based on equality
            context.Cpu.ConditionalPositiveEnabled = (operandA == operandB);
            context.Cpu.ConditionalEqualState = false; // Clear equal state

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "teq",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1; // teq takes 1 cycle
        }
    }
}

