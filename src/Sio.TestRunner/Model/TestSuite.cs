using System;
using System.Collections.Generic;

namespace Sio.TestRunner.Model
{
    /// <summary>
    /// Represents a test suite containing multiple test cases.
    /// </summary>
    public sealed class TestSuite
    {
        public string FormatVersion { get; set; }
        public List<TestCase> Cases { get; set; }

        public TestSuite()
        {
            Cases = new List<TestCase>();
        }
    }

    /// <summary>
    /// Represents a single test case.
    /// </summary>
    public sealed class TestCase
    {
        public string Name { get; set; }
        
        // Single-chip mode (format version 1.0)
        public ProgramReference Program { get; set; }
        public PortConfiguration Ports { get; set; }
        public Dictionary<string, string> PortMappings { get; set; }
        
        // Multi-chip mode (format version 2.0)
        public string SaveFile { get; set; }  // Path to save file (auto-extracts chips + connections)
        public List<ChipDefinition> Chips { get; set; }
        public List<ConnectionDefinition> Connections { get; set; }
        
        // Common properties
        public int CycleLimit { get; set; }
        public List<SignalStream> Inputs { get; set; }
        public List<ExpectedOutput> ExpectedOutputs { get; set; }
        public Dictionary<string, string> MetadataRefs { get; set; }

        public TestCase()
        {
            PortMappings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            Chips = new List<ChipDefinition>();
            Connections = new List<ConnectionDefinition>();
            Inputs = new List<SignalStream>();
            ExpectedOutputs = new List<ExpectedOutput>();
            MetadataRefs = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }
        
        public bool IsMultiChip => !string.IsNullOrEmpty(SaveFile) || (Chips != null && Chips.Count > 0);
    }

    public sealed class ProgramReference
    {
        public string Path { get; set; }
    }

    public sealed class PortConfiguration
    {
        public int Count { get; set; }
    }
    
    /// <summary>
    /// Defines a single chip in a multi-chip test configuration.
    /// </summary>
    public sealed class ChipDefinition
    {
        public string Id { get; set; }
        public string Type { get; set; }  // "MC4000", "MC6000", "MC4000X"
        public string Program { get; set; }
    }
    
    /// <summary>
    /// Defines a connection between two chips.
    /// </summary>
    public sealed class ConnectionDefinition
    {
        public string From { get; set; }  // e.g., "chip1.p0"
        public string To { get; set; }    // e.g., "chip2.x0"
        public string Type { get; set; }  // "simple" or "xbus"
    }
}

