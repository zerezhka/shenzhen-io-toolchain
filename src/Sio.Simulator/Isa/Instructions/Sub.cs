using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// sub R/I - Subtract the value of the operand from the value of the acc register and store the result in acc.
    /// </summary>
    public sealed class Sub : IInstruction
    {
        public string Name => "sub";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("sub requires 1 operand");

            // Resolve operand value
            var operandValue = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Subtract from acc and clamp
            var result = context.Cpu.Acc - operandValue;
            context.Cpu.SetAcc(result);

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "sub",
                context.Instruction.Operands[0]
            );

            return 1; // sub takes 1 cycle
        }
    }
}

