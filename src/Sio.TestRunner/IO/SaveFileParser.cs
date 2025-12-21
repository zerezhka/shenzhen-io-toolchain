using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Sio.TestRunner.Model;

namespace Sio.TestRunner.IO
{
    /// <summary>
    /// Parses Shenzhen I/O save files (.txt) to extract chips, code, and wiring.
    /// </summary>
    public sealed class SaveFileParser
    {
        public sealed class ChipInfo
        {
            public string Id { get; set; }  // Auto-generated: chip01, chip02, etc.
            public string Type { get; set; }  // UC4, UC4X, UC6, etc.
            public int X { get; set; }
            public int Y { get; set; }
            public List<string> CodeLines { get; set; }
            public bool IsPuzzleProvided { get; set; }

            public ChipInfo()
            {
                CodeLines = new List<string>();
            }

            /// <summary>
            /// Converts chip type to simulator type (MC4000, MC6000, etc.)
            /// </summary>
            public string GetSimulatorType()
            {
                switch (Type)
                {
                    case "UC4":
                        return "MC4000";
                    case "UC4X":
                        return "MC4000X";
                    case "UC6":
                        return "MC6000";
                    case "BRIDGE":
                    case "NOTE":
                    case "ROM":
                    case "RAM":
                    case "DX300":
                        // Non-programmable components - skip
                        return null;
                    default:
                        throw new NotSupportedException($"Unsupported chip type: {Type}");
                }
            }
        }

        public sealed class SaveFile
        {
            public string Name { get; set; }
            public string PuzzleId { get; set; }
            public List<ChipInfo> Chips { get; set; }
            public List<string> TraceLines { get; set; }
            public int ProductionCost { get; set; }
            public int PowerUsage { get; set; }
            public int LinesOfCode { get; set; }

            public SaveFile()
            {
                Chips = new List<ChipInfo>();
                TraceLines = new List<string>();
            }
        }

        /// <summary>
        /// Parses a Shenzhen I/O save file.
        /// </summary>
        public SaveFile Parse(string filePath)
        {
            if (!File.Exists(filePath))
                throw new FileNotFoundException($"Save file not found: {filePath}");

            var content = File.ReadAllText(filePath);
            return ParseContent(content);
        }

        /// <summary>
        /// Parses save file content from a string.
        /// </summary>
        public SaveFile ParseContent(string content)
        {
            var saveFile = new SaveFile();
            var lines = content.Split(new[] { '\r', '\n' }, StringSplitOptions.None);

            string currentSection = null;
            ChipInfo currentChip = null;
            var chipCounter = 1;

            for (int i = 0; i < lines.Length; i++)
            {
                var line = lines[i];

                // Detect section headers
                if (line.StartsWith("[") && line.Contains("]"))
                {
                    var match = Regex.Match(line, @"\[([^\]]+)\](.*)");
                    if (match.Success)
                    {
                        var sectionName = match.Groups[1].Value;
                        var sectionValue = match.Groups[2].Value.Trim();

                        switch (sectionName)
                        {
                            case "name":
                                saveFile.Name = sectionValue;
                                currentSection = null;
                                break;

                            case "puzzle":
                                saveFile.PuzzleId = sectionValue;
                                currentSection = null;
                                break;

                            case "production-cost":
                                saveFile.ProductionCost = int.Parse(sectionValue);
                                currentSection = null;
                                break;

                            case "power-usage":
                                saveFile.PowerUsage = int.Parse(sectionValue);
                                currentSection = null;
                                break;

                            case "lines-of-code":
                                saveFile.LinesOfCode = int.Parse(sectionValue);
                                currentSection = null;
                                break;

                            case "traces":
                                currentSection = "traces";
                                // The first non-section line after this will be trace data
                                // Skip processing the [traces] line itself
                                continue;

                            case "chip":
                                // Start new chip
                                if (currentChip != null)
                                {
                                    saveFile.Chips.Add(currentChip);
                                }
                                currentChip = new ChipInfo
                                {
                                    Id = $"chip{chipCounter:D2}"
                                };
                                chipCounter++;
                                currentSection = "chip";
                                break;

                            case "type":
                                if (currentChip != null)
                                    currentChip.Type = sectionValue;
                                break;

                            case "x":
                                if (currentChip != null)
                                    currentChip.X = int.Parse(sectionValue);
                                break;

                            case "y":
                                if (currentChip != null)
                                    currentChip.Y = int.Parse(sectionValue);
                                break;

                            case "is-puzzle-provided":
                                if (currentChip != null)
                                    currentChip.IsPuzzleProvided = true;
                                break;

                            case "code":
                                currentSection = "code";
                                break;

                            default:
                                // Other sections like [comment], [rom] - ignore
                                currentSection = null;
                                break;
                        }
                    }
                }
                else
                {
                    // Handle section content  
                    if (currentSection == "traces")
                    {
                        // Only add lines that are actual trace grid data
                        // They must have dots (at minimum)
                        if (line.Contains('.'))
                        {
                            saveFile.TraceLines.Add(line);
                        }
                    }
                    else if (currentSection == "code" && currentChip != null)
                    {
                        // Strip leading spaces and line numbers (e.g., "  1: mov p0 acc" -> "mov p0 acc")
                        var codeLine = line.TrimStart();
                        codeLine = Regex.Replace(codeLine, @"^\d+:", "");  // Remove line number prefix
                        codeLine = codeLine.TrimStart();

                        // Skip empty lines at the start, but preserve them once we have code
                        if (currentChip.CodeLines.Count > 0 || !string.IsNullOrWhiteSpace(codeLine))
                        {
                            currentChip.CodeLines.Add(codeLine);
                        }
                    }
                }
            }

            // Add last chip
            if (currentChip != null)
            {
                saveFile.Chips.Add(currentChip);
            }

            return saveFile;
        }
    }
}

