using System;
using Sio.EditorSupport.JsonRpc;
using Sio.EditorSupport.Server;

namespace Sio.EditorSupport
{
    internal static class Program
    {
        public static int Main(string[] args)
        {
            // LSP communicates over stdio. Keep stdout exclusively for protocol
            // traffic; anything diagnostic must go to stderr.
            var stdin = Console.OpenStandardInput();
            var stdout = Console.OpenStandardOutput();

            var connection = new RpcConnection(stdin, stdout);
            var server = new LspServer(connection);
            return server.Run();
        }
    }
}
