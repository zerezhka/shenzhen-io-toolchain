using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    public sealed class SignalStream
    {
        public string Id { get; set; }
        public string Target { get; set; }  // For multi-chip: "chip1.p0"
        public int? Rate { get; set; }
        public List<int> Samples { get; set; }

        public SignalStream()
        {
            Samples = new List<int>();
        }
    }
}


