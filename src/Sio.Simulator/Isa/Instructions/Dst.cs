using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// dst R/I R/I - Set the digit of acc specified by the first operand to the value of the second operand.
    /// Digit 0 = ones place, 1 = tens place, 2 = hundreds place.
    /// </summary>
    public sealed class Dst : IInstruction
    {
        public string Name => "dst";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("dst requires 2 operands");

            var digitIndex = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            var digitValue = Decoder.ResolveOperand(
                context.Instruction.Operands[1],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Clamp digit index and value
            if (digitIndex < 0) digitIndex = 0;
            if (digitIndex > 2) digitIndex = 2;
            if (digitValue < 0) digitValue = 0;
            if (digitValue > 9) digitValue = 9;

            var currentValue = context.Cpu.Acc;
            var absValue = System.Math.Abs(currentValue);
            var sign = currentValue < 0 ? -1 : 1;

            int result = 0;
            switch (digitIndex)
            {
                case 0: // ones place
                    result = (absValue / 10) * 10 + digitValue;
                    break;
                case 1: // tens place
                    var ones = absValue % 10;
                    var hundreds = (absValue / 100) * 100;
                    result = hundreds + (digitValue * 10) + ones;
                    break;
                case 2: // hundreds place
                    var lower = absValue % 100;
                    result = (digitValue * 100) + lower;
                    break;
            }

            // Preserve sign
            result *= sign;
            context.Cpu.SetAcc(result);

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "dst",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1;
        }
    }
}

