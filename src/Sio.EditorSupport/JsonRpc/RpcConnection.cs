using System;
using System.IO;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Sio.EditorSupport.JsonRpc
{
    /// <summary>
    /// Minimal LSP-style JSON-RPC transport over a pair of streams.
    /// Messages are framed with a "Content-Length" header followed by a blank
    /// line and a UTF-8 JSON payload, per the Language Server Protocol base spec.
    /// </summary>
    public sealed class RpcConnection
    {
        private readonly Stream _input;
        private readonly Stream _output;
        private readonly object _writeLock = new object();

        public RpcConnection(Stream input, Stream output)
        {
            _input = input ?? throw new ArgumentNullException(nameof(input));
            _output = output ?? throw new ArgumentNullException(nameof(output));
        }

        /// <summary>
        /// Reads the next message. Returns null on end of stream.
        /// </summary>
        public JObject ReadMessage()
        {
            int contentLength = -1;

            // Read headers line by line until the blank separator line.
            while (true)
            {
                var line = ReadHeaderLine();
                if (line == null)
                    return null; // EOF

                if (line.Length == 0)
                    break; // end of headers

                var idx = line.IndexOf(':');
                if (idx <= 0)
                    continue;

                var name = line.Substring(0, idx).Trim();
                var value = line.Substring(idx + 1).Trim();
                if (string.Equals(name, "Content-Length", StringComparison.OrdinalIgnoreCase))
                    int.TryParse(value, out contentLength);
            }

            if (contentLength < 0)
                throw new IOException("Missing Content-Length header.");

            var payload = ReadExact(contentLength);
            var json = Encoding.UTF8.GetString(payload);
            return JObject.Parse(json);
        }

        public void WriteMessage(JObject message)
        {
            var json = message.ToString(Formatting.None);
            var body = Encoding.UTF8.GetBytes(json);
            var header = Encoding.ASCII.GetBytes(
                "Content-Length: " + body.Length + "\r\n\r\n");

            lock (_writeLock)
            {
                _output.Write(header, 0, header.Length);
                _output.Write(body, 0, body.Length);
                _output.Flush();
            }
        }

        // Reads a single CRLF-terminated header line as ASCII. Returns null on EOF.
        private string ReadHeaderLine()
        {
            var sb = new StringBuilder();
            int prev = -1;
            while (true)
            {
                var b = _input.ReadByte();
                if (b == -1)
                    return sb.Length == 0 ? null : sb.ToString();

                if (prev == '\r' && b == '\n')
                {
                    // Drop the trailing '\r' that was appended.
                    sb.Length -= 1;
                    return sb.ToString();
                }

                sb.Append((char)b);
                prev = b;
            }
        }

        private byte[] ReadExact(int count)
        {
            var buffer = new byte[count];
            var offset = 0;
            while (offset < count)
            {
                var read = _input.Read(buffer, offset, count - offset);
                if (read <= 0)
                    throw new EndOfStreamException("Unexpected end of stream while reading message body.");
                offset += read;
            }
            return buffer;
        }
    }
}
