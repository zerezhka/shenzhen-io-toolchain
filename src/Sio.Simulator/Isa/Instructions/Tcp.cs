using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// tcp R/I R/I - Compare the value of the first operand (A) to the value of the second operand (B).
    /// If A > B: enables '+' instructions, disables '-' instructions
    /// If A == B: disables both '+' and '-' instructions
    /// If A < B: disables '+' instructions, enables '-' instructions
    /// </summary>
    public sealed class Tcp : IInstruction
    {
        public string Name => "tcp";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("tcp requires 2 operands");

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

            if (operandA > operandB)
            {
                context.Cpu.ConditionalPositiveEnabled = true;
                context.Cpu.ConditionalEqualState = false;
            }
            else if (operandA < operandB)
            {
                context.Cpu.ConditionalPositiveEnabled = false;
                context.Cpu.ConditionalEqualState = false;
            }
            else // A == B
            {
                // Both disabled (neither + nor - execute)
                context.Cpu.ConditionalEqualState = true;
                context.Cpu.ConditionalPositiveEnabled = false;
            }

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "tcp",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1;
        }
    }
}

