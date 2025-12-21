using Sio.Simulator.Cpu;
using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// mov R/I R - Copy the value of the first operand into the second operand.
    /// </summary>
    public sealed class Mov : IInstruction
    {
        public string Name => "mov";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 2)
                throw new System.ArgumentException("mov requires 2 operands");

            // Resolve source value
            var sourceValue = Decoder.ResolveOperand(
                context.Instruction.Operands[0],
                context.Cpu,
                context.Ports,
                context.Program
            );

            // Resolve write target
            var target = Decoder.ResolveWriteTarget(
                context.Instruction.Operands[1],
                context.Cpu,
                context.Ports
            );

            // Write to target
            switch (target.Type)
            {
                case Decoder.WriteTargetType.Acc:
                    context.Cpu.SetAcc(sourceValue);
                    break;
                case Decoder.WriteTargetType.Dat:
                    context.Cpu.SetDat(sourceValue);
                    break;
                case Decoder.WriteTargetType.Port:
                    if (target.PortIndex.HasValue)
                    {
                        context.Ports.WritePort(target.PortIndex.Value, sourceValue);
                        context.Tracer?.TracePortWrite(context.Cycles.CurrentCycle, 
                            new Ports.PortId(target.PortIndex.Value), sourceValue);
                    }
                    break;
                case Decoder.WriteTargetType.Null:
                    // Writing to null has no effect
                    break;
            }

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "mov",
                $"{context.Instruction.Operands[0]} {context.Instruction.Operands[1]}"
            );

            return 1; // mov takes 1 cycle
        }
    }
}

