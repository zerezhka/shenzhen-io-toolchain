using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using Sio.Assembler.Emit;
using Sio.Assembler.Parse;

namespace Sio.Cli.Commands
{
    internal sealed class BenchRealCommand
    {
        private static readonly string[] SolutionsDirs = {
            "tests/extracted-solutions",
            "tests/extracted-solutions-stinkingbanana",
            "tests/extracted-solutions-shiawasenahikari",
        };

        private const int TargetIterations = 100_000;

        public int Execute()
        {
            var sources = new List<string>();
            foreach (var dir in SolutionsDirs)
            {
                if (!Directory.Exists(dir)) continue;
                foreach (var file in Directory.GetFiles(dir, "*.asm", SearchOption.AllDirectories))
                    sources.Add(File.ReadAllText(file));
            }

            Console.WriteLine($"loaded {sources.Count} files");

            var parser = new Parser();
            var emitter = new VanillaEmitter();

            var sw = Stopwatch.StartNew();
            var count = 0;

            while (count < TargetIterations)
            {
                foreach (var src in sources)
                {
                    try
                    {
                        var program = parser.Parse(src);
                        _ = emitter.Emit(program);
                    }
                    catch { }
                    count++;
                    if (count >= TargetIterations) break;
                }
            }

            sw.Stop();

            var elapsedMs = sw.ElapsedMilliseconds;
            var throughput = count * 1000L / (elapsedMs + 1);

            Console.WriteLine($"iterations: {count}");
            Console.WriteLine($"time:       {elapsedMs} ms");
            Console.WriteLine($"throughput: {throughput} ops/sec");

            return 0;
        }
    }
}
