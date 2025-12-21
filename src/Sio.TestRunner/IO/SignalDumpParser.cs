using System;
using System.Collections.Generic;
using System.IO;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.IO
{
    public static class SignalDumpParser
    {
        // Format: <stream-id>:<rate>,<sample0>,<sample1>,...
        public static SignalStream ParseLine(string line)
        {
            if (line == null) throw new ArgumentNullException(nameof(line));
            line = line.Trim();
            if (line.Length == 0) throw new FormatException("Empty line");

            var colon = line.IndexOf(':');
            if (colon <= 0) throw new FormatException("Missing ':' separator");

            var id = line.Substring(0, colon).Trim();
            var rest = line.Substring(colon + 1).Trim();
            if (id.Length == 0) throw new FormatException("Missing stream id");

            var parts = rest.Split(new[] { ',' }, StringSplitOptions.None);
            if (parts.Length < 1) throw new FormatException("Missing rate/samples");

            if (!int.TryParse(parts[0].Trim(), out var rate) || rate <= 0)
                throw new FormatException("Invalid rate");

            var samples = new List<int>(Math.Max(0, parts.Length - 1));
            for (var i = 1; i < parts.Length; i++)
            {
                var s = parts[i].Trim();
                if (s.Length == 0) continue;
                if (!int.TryParse(s, out var v))
                    throw new FormatException("Invalid sample: " + s);
                samples.Add(v);
            }

            return new SignalStream(id, samples, rate);
        }

        public static IList<SignalStream> ParseFile(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("path is required", nameof(path));
            var streams = new List<SignalStream>();
            foreach (var raw in File.ReadAllLines(path))
            {
                var line = (raw ?? "").Trim();
                if (line.Length == 0) continue;
                streams.Add(ParseLine(line));
            }
            return streams;
        }
    }
}


