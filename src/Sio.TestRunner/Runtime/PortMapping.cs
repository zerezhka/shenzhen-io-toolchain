using System;
using System.Collections.Generic;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.Runtime
{
    /// <summary>
    /// Resolves port mappings between port IDs (p0, p1, etc.) and stream IDs.
    /// </summary>
    public sealed class PortMapping
    {
        private readonly Dictionary<int, string> _portToStream = new Dictionary<int, string>();
        private readonly Dictionary<string, int> _streamToPort = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// Creates a port mapping from a test case's port mappings.
        /// </summary>
        public PortMapping(TestCase testCase)
        {
            if (testCase == null)
                throw new ArgumentNullException(nameof(testCase));

            // Build bidirectional mapping
            foreach (var kvp in testCase.PortMappings)
            {
                var portId = ParsePortId(kvp.Key);
                var streamId = kvp.Value;

                _portToStream[portId] = streamId;
                _streamToPort[streamId] = portId;
            }
        }

        /// <summary>
        /// Gets the stream ID for a port index.
        /// </summary>
        public string GetStreamId(int portIndex)
        {
            _portToStream.TryGetValue(portIndex, out var streamId);
            return streamId;
        }

        /// <summary>
        /// Gets the port index for a stream ID.
        /// </summary>
        public int? GetPortIndex(string streamId)
        {
            if (_streamToPort.TryGetValue(streamId, out var portIndex))
            {
                return portIndex;
            }
            return null;
        }

        /// <summary>
        /// Checks if a port is mapped to a stream.
        /// </summary>
        public bool IsPortMapped(int portIndex)
        {
            return _portToStream.ContainsKey(portIndex);
        }

        private static int ParsePortId(string portId)
        {
            if (string.IsNullOrWhiteSpace(portId))
                throw new ArgumentException("Port ID cannot be empty", nameof(portId));

            portId = portId.Trim().ToLowerInvariant();

            // Parse p0, p1, etc.
            if (portId.StartsWith("p") && portId.Length > 1)
            {
                if (int.TryParse(portId.Substring(1), out var index))
                {
                    return index;
                }
            }

            // Parse x0, x1, etc.
            if (portId.StartsWith("x") && portId.Length > 1)
            {
                if (int.TryParse(portId.Substring(1), out var index))
                {
                    return index;
                }
            }

            throw new ArgumentException($"Invalid port ID format: {portId}", nameof(portId));
        }
    }
}

