using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// tlt R/I R/I - Test if the value of the first operand (A) is less than the value of the second operand (B).
    /// If A < B: enables '+' instructions, disables '-' instructions
    /// If A >= B: disables '+' instructions, enables '-' instructions
    /// </summary>
    public sealed class Tlt : IInstruction
    {
        public string Name => "tlt";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("tlt requires 2 operands");

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

            context.Cpu.ConditionalPositiveEnabled = (operandA < operandB);
            context.Cpu.ConditionalEqualState = false; // Clear equal state

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "tlt",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1;
        }
    }
}

