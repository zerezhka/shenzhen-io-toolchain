using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// dgt R/I - Isolate the specified digit of the value in the acc register and store the result in acc.
    /// Digit 0 = ones place, 1 = tens place, 2 = hundreds place.
    /// </summary>
    public sealed class Dgt : IInstruction
    {
        public string Name => "dgt";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("dgt requires 1 operand");

            var digitIndex = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Clamp digit index to valid range (0-2)
            if (digitIndex < 0) digitIndex = 0;
            if (digitIndex > 2) digitIndex = 2;

            var value = System.Math.Abs(context.Cpu.Acc);
            int result = 0;

            switch (digitIndex)
            {
                case 0: // ones place
                    result = value % 10;
                    break;
                case 1: // tens place
                    result = (value / 10) % 10;
                    break;
                case 2: // hundreds place
                    result = (value / 100) % 10;
                    break;
            }

            context.Cpu.SetAcc(result);

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "dgt",
                context.Instruction.Operands[0]
            );

            return 1;
        }
    }
}

