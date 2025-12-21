using System;
using System.Collections.Generic;
using System.Linq;

namespace Sio.TestRunner.IO
{
    /// <summary>
    /// Resolves connections between chips based on trace grid and chip positions.
    /// </summary>
    public sealed class ConnectionResolver
    {
        public sealed class Connection
        {
            public string FromChipId { get; set; }
            public string FromPort { get; set; }
            public string ToChipId { get; set; }
            public string ToPort { get; set; }
            public string Type { get; set; }  // "simple" or "xbus"
        }

        private readonly TracesParser _tracesParser;

        public ConnectionResolver()
        {
            _tracesParser = new TracesParser();
        }

        /// <summary>
        /// Resolves connections from a save file.
        /// </summary>
        public List<Connection> Resolve(SaveFileParser.SaveFile saveFile)
        {
            if (saveFile.TraceLines == null || saveFile.TraceLines.Count == 0)
                return new List<Connection>();

            // Parse trace grid
            var grid = _tracesParser.Parse(saveFile.TraceLines);

            // Build chip position map
            var chipPositions = new Dictionary<(int x, int y), SaveFileParser.ChipInfo>();
            foreach (var chip in saveFile.Chips)
            {
                chipPositions[(chip.X, chip.Y)] = chip;
            }

            var connections = new List<Connection>();

            // For each chip, check which of its ports are connected
            foreach (var chip in saveFile.Chips)
            {
                // Skip puzzle-provided chips (they're typically just I/O or ROM)
                if (chip.IsPuzzleProvided)
                    continue;

                // Skip non-programmable chips
                if (chip.GetSimulatorType() == null)
                    continue;

                // Check each potential port location
                // Chip layout (simplified):
                //   - Simple ports (p0, p1) are typically on sides
                //   - XBus ports (x0, x1, x2) are on bottom
                //   - Exact positions depend on chip size, which varies
                
                // For now, we'll use a simplified heuristic:
                // - Check cells adjacent to chip position
                // - If there's a trace, follow it to see if it connects to another chip

                CheckAdjacentConnections(grid, chip, chipPositions, connections);
            }

            return connections;
        }

        private void CheckAdjacentConnections(
            TracesParser.TraceGrid grid,
            SaveFileParser.ChipInfo chip,
            Dictionary<(int x, int y), SaveFileParser.ChipInfo> chipPositions,
            List<Connection> connections)
        {
            // Check cells around the chip
            // Chips typically occupy a 3x3 grid, so check the perimeter

            var offsets = new[]
            {
                (-1, 0, "left"),   // Left side
                (1, 0, "right"),   // Right side
                (0, -1, "top"),    // Top side
                (0, 1, "bottom")   // Bottom side
            };

            foreach (var (dx, dy, side) in offsets)
            {
                var checkX = chip.X + dx;
                var checkY = chip.Y + dy;

                var cell = grid.GetCell(checkX, checkY);
                if (cell == null || cell.Directions == TracesParser.TraceDirection.None)
                    continue;

                // Follow the trace to see where it goes
                var path = _tracesParser.FindConnectedPath(grid, checkX, checkY);
                
                // Check if the path connects to another chip
                foreach (var pathCell in path)
                {
                    // Check cells adjacent to this path cell for chips
                    foreach (var (odx, ody, _) in offsets)
                    {
                        var targetX = pathCell.X + odx;
                        var targetY = pathCell.Y + ody;

                        if (chipPositions.TryGetValue((targetX, targetY), out var targetChip))
                        {
                            if (targetChip.Id != chip.Id && !targetChip.IsPuzzleProvided)
                            {
                                // Found a connection!
                                var fromPort = GuessPortName(side, chip.Type);
                                var toPort = GuessPortName(GetOppositeSide(side), targetChip.Type);

                                // Determine connection type (simple vs xbus)
                                var connType = IsXBusPort(fromPort) || IsXBusPort(toPort) ? "xbus" : "simple";

                                connections.Add(new Connection
                                {
                                    FromChipId = chip.Id,
                                    FromPort = fromPort,
                                    ToChipId = targetChip.Id,
                                    ToPort = toPort,
                                    Type = connType
                                });

                                return; // Found one connection from this side
                            }
                        }
                    }
                }
            }
        }

        private string GuessPortName(string side, string chipType)
        {
            // This is a heuristic - real game layout is more complex
            // For now, use simple rules:
            // - UC4/UC6 have p0, p1 on sides
            // - x0, x1, x2 on bottom

            switch (side)
            {
                case "left":
                    return "p0";
                case "right":
                    return "p1";
                case "bottom":
                case "top":
                    return "x0"; // Assume XBus for vertical connections
                default:
                    return "p0";
            }
        }

        private string GetOppositeSide(string side)
        {
            switch (side)
            {
                case "left": return "right";
                case "right": return "left";
                case "top": return "bottom";
                case "bottom": return "top";
                default: return side;
            }
        }

        private bool IsXBusPort(string portName)
        {
            return portName.StartsWith("x");
        }
    }
}

