using System;
using System.Collections.Generic;

namespace Sio.Simulator.Ports
{
    /// <summary>
    /// Manages port I/O for a single MCU.
    /// </summary>
    public sealed class PortBus
    {
        private readonly Dictionary<int, int> _portValues = new Dictionary<int, int>();
        private readonly Dictionary<int, bool> _portInputMode = new Dictionary<int, bool>();
        private readonly Dictionary<int, Queue<int>> _portInputQueues = new Dictionary<int, Queue<int>>();
        private readonly Dictionary<int, int> _portWriteGeneration = new Dictionary<int, int>(); // Tracks write count per port

        /// <summary>
        /// Number of ports available.
        /// </summary>
        public int PortCount { get; }

        /// <summary>
        /// Creates a new port bus with the specified number of ports.
        /// </summary>
        public PortBus(int portCount)
        {
            if (portCount < 0)
                throw new ArgumentOutOfRangeException(nameof(portCount), "Port count must be >= 0");
            
            PortCount = portCount;
            
            // Initialize all ports to 0 in output mode
            for (int i = 0; i < portCount; i++)
            {
                _portValues[i] = 0;
                _portInputMode[i] = false;
                _portInputQueues[i] = new Queue<int>();
                _portWriteGeneration[i] = 0;
            }
        }

        /// <summary>
        /// Reads a value from a port. Puts the port into input mode.
        /// </summary>
        public int ReadPort(int portIndex)
        {
            ValidatePortIndex(portIndex);
            
            // Put port into input mode
            _portInputMode[portIndex] = true;
            
            // If there's a value in the queue, return it
            if (_portInputQueues[portIndex].Count > 0)
            {
                return _portInputQueues[portIndex].Dequeue();
            }
            
            // Otherwise return current value (or 0 if not set)
            return _portValues.TryGetValue(portIndex, out var value) ? value : 0;
        }

        /// <summary>
        /// Writes a value to a port. Puts the port into output mode.
        /// </summary>
        public void WritePort(int portIndex, int value)
        {
            ValidatePortIndex(portIndex);
            
            // Clamp value to valid range
            value = Cpu.CpuState.ClampValue(value);
            
            // Put port into output mode
            _portInputMode[portIndex] = false;
            
            // Store the output value
            _portValues[portIndex] = value;
            
            // Increment write generation to track that this port was explicitly written to
            _portWriteGeneration[portIndex]++;
        }

        /// <summary>
        /// Gets the write generation for a port (how many times it's been written to).
        /// </summary>
        public int GetWriteGeneration(int portIndex)
        {
            ValidatePortIndex(portIndex);
            return _portWriteGeneration[portIndex];
        }

        /// <summary>
        /// Queues an input value for a port (used for simulation inputs).
        /// </summary>
        public void QueueInput(int portIndex, int value)
        {
            ValidatePortIndex(portIndex);
            _portInputQueues[portIndex].Enqueue(Cpu.CpuState.ClampValue(value));
        }

        /// <summary>
        /// Checks if a port has queued input available.
        /// </summary>
        public bool HasInputAvailable(int portIndex)
        {
            ValidatePortIndex(portIndex);
            return _portInputQueues[portIndex].Count > 0;
        }

        /// <summary>
        /// Gets the current output value of a port.
        /// </summary>
        public int GetOutputValue(int portIndex)
        {
            ValidatePortIndex(portIndex);
            return _portValues.TryGetValue(portIndex, out var value) ? value : 0;
        }

        /// <summary>
        /// Checks if a port is in input mode.
        /// </summary>
        public bool IsInputMode(int portIndex)
        {
            ValidatePortIndex(portIndex);
            return _portInputMode.TryGetValue(portIndex, out var mode) && mode;
        }

        private void ValidatePortIndex(int portIndex)
        {
            if (portIndex < 0 || portIndex >= PortCount)
                throw new ArgumentOutOfRangeException(nameof(portIndex), $"Port index must be between 0 and {PortCount - 1}");
        }
    }
}

