using System;
using System.Diagnostics;
using Sio.Assembler.Emit;
using Sio.Assembler.Parse;

namespace Sio.Cli.Commands
{
    internal sealed class BenchCommand
    {
        private const string Sample =
            "loop:\n" +
            "mov acc 0\n" +
            "teq acc 5\n" +
            "+ jmp done\n" +
            "add acc 1\n" +
            "jmp loop\n" +
            "done:\n" +
            "mov p0 acc";

        private const int Iterations = 1_000_000;

        public int Execute()
        {
            var parser = new Parser();
            var emitter = new VanillaEmitter();

            var sw = Stopwatch.StartNew();

            for (var i = 0; i < Iterations; i++)
            {
                var program = parser.Parse(Sample);
                _ = emitter.Emit(program);
            }

            sw.Stop();

            var elapsedMs = sw.ElapsedMilliseconds;
            var throughput = Iterations * 1000L / (elapsedMs + 1);

            Console.WriteLine($"iterations: {Iterations}");
            Console.WriteLine($"time:       {elapsedMs} ms");
            Console.WriteLine($"throughput: {throughput} ops/sec");

            return 0;
        }
    }
}
