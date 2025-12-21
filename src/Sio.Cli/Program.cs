using System;

namespace Sio.Cli
{
    internal static class Program
    {
        // Placeholder command router (T003). Real commands wired in later tasks.
        public static int Main(string[] args)
        {
            if (args == null || args.Length == 0)
            {
                Console.Error.WriteLine("sio: missing command");
                Console.Error.WriteLine("Usage: sio <assemble|simulate|test> [args]");
                return 2;
            }

            Console.Error.WriteLine("sio: command not implemented yet: " + args[0]);
            return 2;
        }
    }
}


