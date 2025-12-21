using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// mul R/I - Multiply the value of the operand by the value of the acc register and store the result in acc.
    /// </summary>
    public sealed class Mul : IInstruction
    {
        public string Name => "mul";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("mul requires 1 operand");

            var operandValue = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            var result = context.Cpu.Acc * operandValue;
            context.Cpu.SetAcc(result);

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "mul",
                context.Instruction.Operands[0]
            );

            return 1;
        }
    }
}

