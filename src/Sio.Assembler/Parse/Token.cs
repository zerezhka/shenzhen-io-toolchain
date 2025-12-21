namespace Sio.Assembler.Parse
{
    public sealed class Token
    {
        public string Value { get; }
        public TokenType Type { get; }
        public bool IsLabel { get; }
        public int Line { get; }
        public int Column { get; }

        public Token(string value, TokenType type, int line, int column, bool isLabel = false)
        {
            Value = value;
            Type = type;
            IsLabel = isLabel;
            Line = line;
            Column = column;
        }
    }

    public enum TokenType
    {
        Identifier,
        Number,
        Label,
        Colon,
        Newline,
        EndOfFile
    }
}

