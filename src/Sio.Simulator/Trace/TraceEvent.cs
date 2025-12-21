using System;
using Sio.Simulator.Ports;

namespace Sio.Simulator.Trace
{
    public enum TraceEventType
    {
        Instruction,
        PortRead,
        PortWrite,
        Info
    }

    public sealed class TraceEvent
    {
        public long Cycle { get; }
        public TraceEventType Type { get; }
        public string Message { get; }

        public int? ProgramCounter { get; }
        public PortId? Port { get; }
        public int? Value { get; }

        public TraceEvent(long cycle, TraceEventType type, string message, int? programCounter = null, PortId? port = null, int? value = null)
        {
            if (cycle < 0) throw new ArgumentOutOfRangeException(nameof(cycle));
            Cycle = cycle;
            Type = type;
            Message = message ?? "";
            ProgramCounter = programCounter;
            Port = port;
            Value = value;
        }

        public override string ToString()
        {
            // Stable human-readable representation (deterministic).
            if (Port.HasValue && Value.HasValue)
            {
                return $"{Cycle}:{Type}:{Port.Value}:{Value.Value}:{Message}";
            }
            return $"{Cycle}:{Type}:{Message}";
        }
    }
}


