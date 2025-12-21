using System;
using System.Collections.Generic;
using System.Linq;

namespace Sio.TestRunner.IO
{
    /// <summary>
    /// Parses the [traces] section from Shenzhen I/O save files.
    /// Traces are encoded as hex characters representing wire connections.
    /// </summary>
    public sealed class TracesParser
    {
        [Flags]
        public enum TraceDirection : byte
        {
            None = 0,
            Bottom = 0x1,
            Right = 0x2,
            Top = 0x4,
            Left = 0x8
        }

        public sealed class TraceCell
        {
            public int X { get; set; }
            public int Y { get; set; }
            public TraceDirection Directions { get; set; }

            public bool HasBottom => (Directions & TraceDirection.Bottom) != 0;
            public bool HasRight => (Directions & TraceDirection.Right) != 0;
            public bool HasTop => (Directions & TraceDirection.Top) != 0;
            public bool HasLeft => (Directions & TraceDirection.Left) != 0;
        }

        public sealed class TraceGrid
        {
            public int Width { get; set; }
            public int Height { get; set; }
            public TraceCell[,] Cells { get; set; }

            public TraceCell GetCell(int x, int y)
            {
                if (x < 0 || x >= Width || y < 0 || y >= Height)
                    return null;
                return Cells[y, x];
            }
        }

        /// <summary>
        /// Parses a trace grid from ASCII hex representation.
        /// </summary>
        /// <param name="traceLines">Lines from the [traces] section</param>
        public TraceGrid Parse(IList<string> traceLines)
        {
            if (traceLines == null || traceLines.Count == 0)
                return new TraceGrid { Width = 0, Height = 0, Cells = new TraceCell[0, 0] };

            // Filter out empty lines and find the maximum width
            var nonEmptyLines = traceLines.Where(line => !string.IsNullOrWhiteSpace(line)).ToList();
            if (nonEmptyLines.Count == 0)
                return new TraceGrid { Width = 0, Height = 0, Cells = new TraceCell[0, 0] };

            var width = nonEmptyLines.Max(line => line.Length);
            var height = nonEmptyLines.Count;

            var cells = new TraceCell[height, width];

            for (int y = 0; y < height; y++)
            {
                var line = nonEmptyLines[y];
                
                // Pad line to width if needed
                if (line.Length < width)
                {
                    line = line.PadRight(width, '.');
                }

                for (int x = 0; x < width; x++)
                {
                    var ch = line[x];
                    var direction = DecodeTraceChar(ch);
                    
                    cells[y, x] = new TraceCell
                    {
                        X = x,
                        Y = y,
                        Directions = direction
                    };
                }
            }

            return new TraceGrid
            {
                Width = width,
                Height = height,
                Cells = cells
            };
        }

        /// <summary>
        /// Decodes a single hex character to trace directions.
        /// Format: bits are [Left][Top][Right][Bottom] = 0x8, 0x4, 0x2, 0x1
        /// </summary>
        private TraceDirection DecodeTraceChar(char ch)
        {
            // '.' means no connection
            if (ch == '.')
                return TraceDirection.None;

            // Convert hex digit to 4-bit value
            int value;
            if (ch >= '0' && ch <= '9')
                value = ch - '0';
            else if (ch >= 'A' && ch <= 'F')
                value = ch - 'A' + 10;
            else if (ch >= 'a' && ch <= 'f')
                value = ch - 'a' + 10;
            else
                throw new FormatException($"Invalid trace character: '{ch}'. Expected hex digit or '.'");

            return (TraceDirection)value;
        }

        /// <summary>
        /// Finds connected cells by following traces from a starting point.
        /// </summary>
        public List<TraceCell> FindConnectedPath(TraceGrid grid, int startX, int startY)
        {
            var path = new List<TraceCell>();
            var visited = new HashSet<(int, int)>();
            var queue = new Queue<(int x, int y)>();

            queue.Enqueue((startX, startY));
            visited.Add((startX, startY));

            while (queue.Count > 0)
            {
                var (x, y) = queue.Dequeue();
                var cell = grid.GetCell(x, y);
                
                if (cell == null || cell.Directions == TraceDirection.None)
                    continue;

                path.Add(cell);

                // Explore neighbors
                if (cell.HasBottom)
                    EnqueueIfValid(grid, x, y + 1, visited, queue);
                if (cell.HasTop)
                    EnqueueIfValid(grid, x, y - 1, visited, queue);
                if (cell.HasRight)
                    EnqueueIfValid(grid, x + 1, y, visited, queue);
                if (cell.HasLeft)
                    EnqueueIfValid(grid, x - 1, y, visited, queue);
            }

            return path;
        }

        private void EnqueueIfValid(TraceGrid grid, int x, int y, HashSet<(int, int)> visited, Queue<(int x, int y)> queue)
        {
            if (x < 0 || x >= grid.Width || y < 0 || y >= grid.Height)
                return;

            if (visited.Contains((x, y)))
                return;

            visited.Add((x, y));
            queue.Enqueue((x, y));
        }
    }
}

