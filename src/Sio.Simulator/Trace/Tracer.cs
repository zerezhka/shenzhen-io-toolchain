using System.Collections.Generic;
using Sio.Simulator.Ports;

namespace Sio.Simulator.Trace
{
    /// <summary>
    /// Emits trace events during simulation for debugging.
    /// </summary>
    public sealed class Tracer
    {
        private readonly List<TraceEvent> _events = new List<TraceEvent>();
        private readonly bool _enabled;

        /// <summary>
        /// All trace events collected so far.
        /// </summary>
        public IReadOnlyList<TraceEvent> Events => _events;

        /// <summary>
        /// Creates a new tracer.
        /// </summary>
        /// <param name="enabled">Whether tracing is enabled</param>
        public Tracer(bool enabled = false)
        {
            _enabled = enabled;
        }

        /// <summary>
        /// Records an instruction execution.
        /// </summary>
        public void TraceInstruction(long cycle, int programCounter, string instruction, string operands = "")
        {
            if (!_enabled) return;
            
            var message = $"{instruction} {operands}".Trim();
            _events.Add(new TraceEvent(cycle, TraceEventType.Instruction, message, programCounter));
        }

        /// <summary>
        /// Records a port read operation.
        /// </summary>
        public void TracePortRead(long cycle, PortId port, int value)
        {
            if (!_enabled) return;
            
            _events.Add(new TraceEvent(cycle, TraceEventType.PortRead, $"read {port} = {value}", null, port, value));
        }

        /// <summary>
        /// Records a port write operation.
        /// </summary>
        public void TracePortWrite(long cycle, PortId port, int value)
        {
            if (!_enabled) return;
            
            _events.Add(new TraceEvent(cycle, TraceEventType.PortWrite, $"write {port} = {value}", null, port, value));
        }

        /// <summary>
        /// Records a general info message.
        /// </summary>
        public void TraceInfo(long cycle, string message)
        {
            if (!_enabled) return;
            
            _events.Add(new TraceEvent(cycle, TraceEventType.Info, message));
        }

        /// <summary>
        /// Clears all trace events.
        /// </summary>
        public void Clear()
        {
            _events.Clear();
        }
    }
}

