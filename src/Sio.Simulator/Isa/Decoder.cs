using System;
using Sio.Simulator.Cpu;
using Sio.Simulator.Ports;
using Sio.Simulator.Parse;

namespace Sio.Simulator.Isa
{
    /// <summary>
    /// Decodes operands and resolves values for instruction execution.
    /// </summary>
    public sealed class Decoder
    {
        /// <summary>
        /// Resolves an operand to an integer value.
        /// Can be a register name, port name, or literal integer.
        /// </summary>
        public static int ResolveOperand(string operand, CpuState cpu, PortBus ports, Parse.ProgramParser.ExecutableProgram program)
        {
            if (string.IsNullOrWhiteSpace(operand))
                throw new ArgumentException("Operand cannot be empty", nameof(operand));

            operand = operand.Trim();

            // Try parsing as integer first
            if (int.TryParse(operand, out var intValue))
            {
                return CpuState.ClampValue(intValue);
            }

            // Check for registers
            switch (operand.ToLowerInvariant())
            {
                case "acc":
                    return cpu.Acc;
                case "dat":
                    if (!cpu.Dat.HasValue)
                        throw new InvalidOperationException("dat register not available on this MCU");
                    return cpu.Dat.Value;
                case "null":
                    return 0;
                default:
                    break;
            }

            // Check for port (p0, p1, etc.)
            if (PortId.TryParse(operand, out var portId))
            {
                return ports.ReadPort(portId.Index);
            }

            // Check for XBus port (x0, x1, etc.)
            if (operand.Length >= 2 && operand[0] == 'x' && char.IsDigit(operand[1]))
            {
                if (int.TryParse(operand.Substring(1), out var xPortIndex))
                {
                    // XBus ports are typically higher indices, but for now treat as regular ports
                    // In a full implementation, we'd distinguish XBus from simple I/O
                    return ports.ReadPort(xPortIndex);
                }
            }

            // Check for label (for jmp instruction)
            if (program != null && program.Labels.TryGetValue(operand, out var labelPc))
            {
                return labelPc;
            }

            throw new ArgumentException($"Unknown operand: {operand}", nameof(operand));
        }

        /// <summary>
        /// Resolves an operand to a target (register or port) for write operations.
        /// </summary>
        public static WriteTarget ResolveWriteTarget(string operand, CpuState cpu, PortBus ports)
        {
            if (string.IsNullOrWhiteSpace(operand))
                throw new ArgumentException("Operand cannot be empty", nameof(operand));

            operand = operand.Trim();

            // Check for registers
            switch (operand.ToLowerInvariant())
            {
                case "acc":
                    return new WriteTarget { Type = WriteTargetType.Acc };
                case "dat":
                    if (!cpu.Dat.HasValue)
                        throw new InvalidOperationException("dat register not available on this MCU");
                    return new WriteTarget { Type = WriteTargetType.Dat };
                case "null":
                    return new WriteTarget { Type = WriteTargetType.Null }; // Writing to null has no effect
                default:
                    break;
            }

            // Check for port
            if (PortId.TryParse(operand, out var portId))
            {
                return new WriteTarget { Type = WriteTargetType.Port, PortIndex = portId.Index };
            }

            // Check for XBus port
            if (operand.Length >= 2 && operand[0] == 'x' && char.IsDigit(operand[1]))
            {
                if (int.TryParse(operand.Substring(1), out var xPortIndex))
                {
                    return new WriteTarget { Type = WriteTargetType.Port, PortIndex = xPortIndex };
                }
            }

            throw new ArgumentException($"Invalid write target: {operand}", nameof(operand));
        }

        public enum WriteTargetType
        {
            Acc,
            Dat,
            Port,
            Null
        }

        public sealed class WriteTarget
        {
            public WriteTargetType Type { get; set; }
            public int? PortIndex { get; set; }
        }
    }
}

