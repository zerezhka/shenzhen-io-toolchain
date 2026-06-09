using System;
using System.Linq;
using Sio.Cli.Commands;
using Sio.Cli.Output;

namespace Sio.Cli
{
    internal static class Program
    {
        public static int Main(string[] args)
        {
            if (args == null || args.Length == 0)
            {
                Console.Error.WriteLine("sio: missing command");
                Console.Error.WriteLine("Usage: sio <assemble|simulate|test> [args]");
                return ExitCodes.Usage;
            }

            var command = args[0];
            var commandArgs = args.Skip(1).ToArray();
            var writer = new ConsoleWriter();

            switch (command.ToLowerInvariant())
            {
                case "assemble":
                    var assembleCmd = new AssembleCommand(writer);
                    return assembleCmd.Execute(commandArgs);
                case "simulate":
                    var simulateCmd = new SimulateCommand(writer);
                    return simulateCmd.Execute(commandArgs);
                case "test":
                    var testCmd = new TestCommand(writer);
                    return testCmd.Execute(commandArgs);
                case "bench":
                    return new BenchCommand().Execute();
                case "bench-fs":
                    return new BenchFsCommand().Execute();
                default:
                    Console.Error.WriteLine($"sio: unknown command: {command}");
                    Console.Error.WriteLine("Usage: sio <assemble|simulate|test> [args]");
                    return ExitCodes.Usage;
            }
        }
    }
}


