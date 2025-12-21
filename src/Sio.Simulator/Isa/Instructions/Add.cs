using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// add R/I - Add the value of the operand to the value of the acc register and store the result in acc.
    /// </summary>
    public sealed class Add : IInstruction
    {
        public string Name => "add";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("add requires 1 operand");

            // Resolve operand value
            var operandValue = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Add to acc and clamp
            var result = context.Cpu.Acc + operandValue;
            context.Cpu.SetAcc(result);

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "add",
                context.Instruction.Operands[0]
            );

            return 1; // add takes 1 cycle
        }
    }
}

