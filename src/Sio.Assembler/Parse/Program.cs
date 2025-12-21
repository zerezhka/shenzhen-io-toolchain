using System.Collections.Generic;

namespace Sio.Assembler.Parse
{
    public sealed class Program
    {
        public IList<Statement> Statements { get; }

        public Program()
        {
            Statements = new List<Statement>();
        }
    }
}

