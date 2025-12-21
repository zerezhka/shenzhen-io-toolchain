using System;
using System.Collections.Generic;
using System.Text;

namespace Sio.Assembler.Diagnostics
{
    public sealed class Diagnostic
    {
        public string Message { get; }
        public string File { get; }
        public int Line { get; }
        public int Column { get; }
        public IList<string> IncludeChain { get; }

        public Diagnostic(string message, string file, int line, int column, IList<string> includeChain = null)
        {
            Message = message ?? throw new ArgumentNullException(nameof(message));
            File = file;
            Line = line;
            Column = column;
            IncludeChain = includeChain ?? new List<string>();
        }

        public override string ToString()
        {
            var sb = new StringBuilder();
            if (!string.IsNullOrEmpty(File))
            {
                sb.Append(File);
                if (Line > 0)
                {
                    sb.Append(":");
                    sb.Append(Line);
                    if (Column > 0)
                    {
                        sb.Append(":");
                        sb.Append(Column);
                    }
                }
                sb.Append(": ");
            }
            sb.Append(Message);
            
            if (IncludeChain.Count > 0)
            {
                sb.Append(" (include chain: ");
                sb.Append(string.Join(" -> ", IncludeChain));
                sb.Append(")");
            }
            
            return sb.ToString();
        }
    }
}

