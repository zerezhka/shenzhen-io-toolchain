using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    public sealed class SignalStream
    {
        public string Id { get; }
        public int? Rate { get; }
        public IReadOnlyList<int> Samples { get; }

        public SignalStream(string id, IReadOnlyList<int> samples, int? rate = null)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("Stream id is required", nameof(id));
            Id = id.Trim();
            Samples = samples ?? throw new ArgumentNullException(nameof(samples));
            Rate = rate;
        }
    }
}


