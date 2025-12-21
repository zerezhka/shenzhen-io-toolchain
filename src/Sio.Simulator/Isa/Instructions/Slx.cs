using Sio.Simulator.Isa.Instructions;
using Sio.Simulator.Ports;

namespace Sio.Simulator.Isa.Instructions
{
    /// <summary>
    /// slx P - Sleep until data is available to be read on the XBus pin specified by the operand.
    /// </summary>
    public sealed class Slx : IInstruction
    {
        public string Name => "slx";

        public int Execute(ExecutionContext context)
        {
            if (context.Instruction.Operands.Count < 1)
                throw new System.ArgumentException("slx requires 1 operand (pin)");

            // Resolve pin operand (should be x0, x1, etc. or p0, p1, etc.)
            var pinOperand = context.Instruction.Operands[0].Trim().ToLowerInvariant();
            int pinIndex = -1;

            // Parse XBus pin (x0, x1, x2, x3)
            if (pinOperand.StartsWith("x") && pinOperand.Length > 1)
            {
                if (int.TryParse(pinOperand.Substring(1), out pinIndex))
                {
                    // XBus pins - for now we'll use them as regular port indices
                    // In a full implementation, we'd distinguish XBus from simple I/O
                }
            }
            // Parse simple I/O pin (p0, p1, etc.)
            else if (PortId.TryParse(pinOperand, out var portId))
            {
                pinIndex = portId.Index;
            }
            else
            {
                throw new System.ArgumentException($"Invalid pin operand for slx: {pinOperand}");
            }

            if (pinIndex < 0 || pinIndex >= context.Ports.PortCount)
            {
                throw new System.ArgumentException($"Pin index {pinIndex} out of range");
            }

            // Check if data is already available
            if (context.Ports.HasInputAvailable(pinIndex))
            {
                // Data available, don't sleep
                context.Cpu.IsWaitingForXBus = false;
                context.Cpu.WaitingXBusPin = null;
            }
            else
            {
                // No data available, enter sleep state
                context.Cpu.IsWaitingForXBus = true;
                context.Cpu.WaitingXBusPin = pinIndex;
            }

            context.Tracer?.TraceInstruction(
                context.Cycles.CurrentCycle,
                context.Cpu.Pc,
                "slx",
                pinOperand
            );

            return 1;
        }
    }
}

