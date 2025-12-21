using System.Collections.Generic;

namespace Sio.Assembler.Parse
{
    public sealed class Statement
    {
        public bool IsLabel { get; set; }
        public string Label { get; set; }
        public string Instruction { get; set; }
        public IList<string> Operands { get; set; }
        public string ConditionalPrefix { get; set; } // "+" or "-" or null

        public Statement()
        {
            Operands = new List<string>();
        }
    }
}

