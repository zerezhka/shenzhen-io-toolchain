using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// tgt R/I R/I - Test if the value of the first operand (A) is greater than the value of the second operand (B).
    /// If A > B: enables '+' instructions, disables '-' instructions
    /// If A <= B: disables '+' instructions, enables '-' instructions
    /// </summary>
    public sealed class Tgt : IInstruction
    {
        public string Name => "tgt";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("tgt requires 2 operands");

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

            context.Cpu.ConditionalPositiveEnabled = (operandA > operandB);
            context.Cpu.ConditionalEqualState = false; // Clear equal state

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "tgt",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1;
        }
    }
}

