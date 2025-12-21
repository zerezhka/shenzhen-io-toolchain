using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    public sealed class SignalStream
    {
        public string Id { get; set; }
        public int? Rate { get; set; }
        public List<int> Samples { get; set; }

        public SignalStream()
        {
            Samples = new List<int>();
        }
    }
}


