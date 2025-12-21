using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    public enum ExpectedOutputMode
    {
        CycleExact,
        OrderOnly
    }

    public readonly struct TimedValue
    {
        public long Cycle { get; }
        public int Value { get; }

        public TimedValue(long cycle, int value)
        {
            if (cycle < 0) throw new ArgumentOutOfRangeException(nameof(cycle));
            Cycle = cycle;
            Value = value;
        }
    }

    public sealed class ExpectedOutput
    {
        public string StreamId { get; }
        public ExpectedOutputMode Mode { get; }

        public IReadOnlyList<TimedValue> Events { get; }
        public IReadOnlyList<int> Values { get; }

        public ExpectedOutput(string streamId, ExpectedOutputMode mode, IReadOnlyList<TimedValue> events, IReadOnlyList<int> values)
        {
            if (string.IsNullOrWhiteSpace(streamId)) throw new ArgumentException("streamId is required", nameof(streamId));
            StreamId = streamId.Trim();
            Mode = mode;
            Events = events ?? Array.Empty<TimedValue>();
            Values = values ?? Array.Empty<int>();
        }
    }
}


