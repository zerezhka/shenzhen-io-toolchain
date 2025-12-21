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
        public ProgramReference Program { get; set; }
        public int CycleLimit { get; set; }
        public PortConfiguration Ports { get; set; }
        public Dictionary<string, string> PortMappings { get; set; }
        public List<SignalStream> Inputs { get; set; }
        public List<ExpectedOutput> ExpectedOutputs { get; set; }
        public Dictionary<string, string> MetadataRefs { get; set; }

        public TestCase()
        {
            PortMappings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            Inputs = new List<SignalStream>();
            ExpectedOutputs = new List<ExpectedOutput>();
            MetadataRefs = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }
    }

    public sealed class ProgramReference
    {
        public string Path { get; set; }
    }

    public sealed class PortConfiguration
    {
        public int Count { get; set; }
    }
}

