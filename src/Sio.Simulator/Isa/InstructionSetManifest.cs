using System;
using System.Collections.Generic;
using System.Linq;

namespace Sio.Simulator.Isa
{
    /// <summary>
    /// Canonical instruction set manifest - single source of truth for all supported instructions.
    /// Based on Shenzhen I/O manual specification.
    /// </summary>
    public static class InstructionSetManifest
    {
        public const string Version = "1.0.0";
        public const string Date = "2025-12-21";

        /// <summary>
        /// All valid instruction names in the Shenzhen I/O instruction set.
        /// </summary>
        public static readonly IReadOnlyList<string> AllInstructions = new[]
        {
            // Basic Instructions
            "nop",
            "mov",
            "jmp",
            "slp",
            "slx",
            
            // Test Instructions
            "teq",
            "tgt",
            "tlt",
            "tcp",
            
            // Arithmetic Instructions
            "add",
            "sub",
            "mul",
            "not",
            "dgt",
            "dst"
        };

        /// <summary>
        /// Instructions grouped by category for documentation and organization.
        /// </summary>
        public static readonly Dictionary<string, IReadOnlyList<string>> InstructionsByCategory = new Dictionary<string, IReadOnlyList<string>>
        {
            ["Basic"] = new[] { "nop", "mov", "jmp", "slp", "slx" },
            ["Test"] = new[] { "teq", "tgt", "tlt", "tcp" },
            ["Arithmetic"] = new[] { "add", "sub", "mul", "not", "dgt", "dst" }
        };

        /// <summary>
        /// Verifies that an instruction name is valid.
        /// </summary>
        public static bool IsValidInstruction(string instruction)
        {
            if (string.IsNullOrWhiteSpace(instruction))
                return false;
            
            return AllInstructions.Contains(instruction, StringComparer.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Gets the category of an instruction, or null if not found.
        /// </summary>
        public static string GetCategory(string instruction)
        {
            foreach (var category in InstructionsByCategory)
            {
                if (category.Value.Contains(instruction, StringComparer.OrdinalIgnoreCase))
                    return category.Key;
            }
            return null;
        }
    }
}

