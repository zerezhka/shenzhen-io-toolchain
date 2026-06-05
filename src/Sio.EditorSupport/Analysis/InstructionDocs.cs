using System;
using System.Collections.Generic;

namespace Sio.EditorSupport.Analysis
{
    public sealed class InstructionDoc
    {
        public string Name { get; set; }
        public string Signature { get; set; }
        public string Category { get; set; }
        public string Summary { get; set; }
        public int Cycles { get; set; }
    }

    /// <summary>
    /// Rich, human-readable documentation for each instruction, used for hover
    /// and completion. The instruction list mirrors
    /// <see cref="Sio.Simulator.Isa.InstructionSetManifest"/> plus the
    /// undocumented instructions the assembler parser accepts (gen, @).
    /// </summary>
    public static class InstructionDocs
    {
        private static readonly Dictionary<string, InstructionDoc> _docs =
            new Dictionary<string, InstructionDoc>(StringComparer.OrdinalIgnoreCase);

        static InstructionDocs()
        {
            Add("nop", "nop", "Basic", 1,
                "No operation. Has no effect other than consuming a cycle.");
            Add("mov", "mov R/I R", "Basic", 1,
                "Copy the value of the first operand into the second operand.");
            Add("jmp", "jmp L", "Basic", 1,
                "Jump to the instruction following the specified label.");
            Add("slp", "slp R/I", "Basic", 1,
                "Sleep for the number of time units specified by the operand.");
            Add("slx", "slx P", "Basic", 1,
                "Sleep until data is available to be read on the XBus pin specified by the operand.");

            Add("teq", "teq R/I R/I", "Test", 1,
                "Test if the value of the first operand (A) is equal to the value of the second operand (B). " +
                "Enables `+` instructions when true and `-` instructions when false.");
            Add("tgt", "tgt R/I R/I", "Test", 1,
                "Test if the value of the first operand (A) is greater than the value of the second operand (B).");
            Add("tlt", "tlt R/I R/I", "Test", 1,
                "Test if the value of the first operand (A) is less than the value of the second operand (B).");
            Add("tcp", "tcp R/I R/I", "Test", 1,
                "Compare A to B: enables `+` if A > B and `-` if A < B (neither when equal).");

            Add("add", "add R/I", "Arithmetic", 1,
                "Add the value of the operand to acc and store the result in acc.");
            Add("sub", "sub R/I", "Arithmetic", 1,
                "Subtract the value of the operand from acc and store the result in acc.");
            Add("mul", "mul R/I", "Arithmetic", 1,
                "Multiply acc by the value of the operand and store the result in acc.");
            Add("not", "not", "Arithmetic", 1,
                "If acc is 0, store 100 in acc; otherwise store 0 in acc.");
            Add("dgt", "dgt R/I", "Arithmetic", 1,
                "Isolate the specified digit of acc and store the result in acc.");
            Add("dst", "dst R/I R/I", "Arithmetic", 1,
                "Set the digit of acc specified by the first operand to the value of the second operand.");

            Add("gen", "gen P R/I R/I", "Undocumented", 1,
                "Generate a pulse on a simple I/O pin: drive it high for the first duration, low for the second. (Undocumented.)");
            Add("@", "@ <instruction>", "Undocumented", 1,
                "Prefix marking an instruction for a single execution pass. (Undocumented.)");
        }

        private static void Add(string name, string signature, string category, int cycles, string summary)
        {
            _docs[name] = new InstructionDoc
            {
                Name = name,
                Signature = signature,
                Category = category,
                Cycles = cycles,
                Summary = summary
            };
        }

        public static bool TryGet(string name, out InstructionDoc doc)
        {
            doc = null;
            if (string.IsNullOrWhiteSpace(name))
                return false;
            return _docs.TryGetValue(name, out doc);
        }

        public static IEnumerable<InstructionDoc> All => _docs.Values;

        /// <summary>Markdown rendering of an instruction's docs, for hover.</summary>
        public static string ToMarkdown(InstructionDoc doc)
        {
            return "```\n" + doc.Signature + "\n```\n\n" +
                   doc.Summary + "\n\n" +
                   "*Category: " + doc.Category + " · " + doc.Cycles + " cycle(s)*";
        }
    }

    /// <summary>
    /// Register/pin documentation for hover and completion.
    /// </summary>
    public static class RegisterDocs
    {
        private static readonly Dictionary<string, string> _docs =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["acc"] = "Accumulator register. The primary working register for arithmetic.",
            ["dat"] = "General-purpose data register (MC6000 only).",
            ["null"] = "Pseudo-register: reads as 0, writes are discarded.",
            ["p0"] = "Simple I/O pin p0 (0–100 analog value).",
            ["p1"] = "Simple I/O pin p1 (0–100 analog value).",
            ["x0"] = "XBus pin x0 (blocking packet I/O).",
            ["x1"] = "XBus pin x1 (blocking packet I/O).",
            ["x2"] = "XBus pin x2 (blocking packet I/O).",
            ["x3"] = "XBus pin x3 (blocking packet I/O).",
        };

        public static bool TryGet(string name, out string summary) =>
            _docs.TryGetValue(name ?? string.Empty, out summary);

        public static IEnumerable<KeyValuePair<string, string>> All => _docs;
    }
}
