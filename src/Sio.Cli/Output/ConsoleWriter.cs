using System;
using System.Collections.Generic;

namespace Sio.Cli.Output
{
    public sealed class ConsoleWriter
    {
        public void WriteInfoLine(string line)
        {
            Console.Out.WriteLine(line ?? "");
        }

        public void WriteErrorLine(string line)
        {
            Console.Error.WriteLine(line ?? "");
        }

        public void WriteKeyValueLines(IDictionary<string, string> kv)
        {
            // Deterministic ordering: sort keys ordinal.
            if (kv == null) return;
            var keys = new List<string>(kv.Keys);
            keys.Sort(StringComparer.Ordinal);
            foreach (var k in keys)
            {
                WriteInfoLine(k + ": " + (kv[k] ?? ""));
            }
        }
    }
}


