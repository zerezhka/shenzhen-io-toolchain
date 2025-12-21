using System;

namespace Sio.Assembler.Parse
{
    public sealed class ParseException : Exception
    {
        public int Line { get; }
        public int Column { get; }

        public ParseException(string message, int line, int column) : base(message)
        {
            Line = line;
            Column = column;
        }

        public ParseException(string message, int line, int column, Exception innerException) 
            : base(message, innerException)
        {
            Line = line;
            Column = column;
        }
    }
}

