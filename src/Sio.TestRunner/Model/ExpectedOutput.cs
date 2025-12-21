using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    public sealed class ExpectedOutput
    {
        public string StreamId { get; set; }
        public string Mode { get; set; } // "cycle-exact" or "order-only"
        public List<OutputEvent> Events { get; set; } // For cycle-exact
        public List<int> Values { get; set; } // For order-only

        public ExpectedOutput()
        {
            Events = new List<OutputEvent>();
            Values = new List<int>();
        }
    }

    public sealed class OutputEvent
    {
        public long Cycle { get; set; }
        public int Value { get; set; }
    }
}


