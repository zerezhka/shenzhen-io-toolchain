using System;
using System.Collections.Generic;
using System.Linq;

namespace Sio.Simulator.Parse
{
    /// <summary>
    /// Parses vanilla Shenzhen I/O assembly into an executable program representation.
    /// </summary>
    public sealed class ProgramParser
    {
        /// <summary>
        /// Represents a single executable instruction in the program.
        /// </summary>
        public sealed class ExecutableInstruction
        {
            public string Instruction { get; set; }
            public IList<string> Operands { get; set; }
            public bool IsConditional { get; set; }
            public bool ConditionalPositive { get; set; } // true for '+', false for '-'
            public int LineNumber { get; set; }

            public ExecutableInstruction()
            {
                Operands = new List<string>();
            }
        }

        /// <summary>
        /// Represents a parsed program ready for execution.
        /// </summary>
        public sealed class ExecutableProgram
        {
            public IList<ExecutableInstruction> Instructions { get; }
            public Dictionary<string, int> Labels { get; }

            public ExecutableProgram()
            {
                Instructions = new List<ExecutableInstruction>();
                Labels = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            }
        }

        /// <summary>
        /// Parses vanilla assembly text into an executable program.
        /// </summary>
        public ExecutableProgram Parse(string assemblyText)
        {
            if (string.IsNullOrEmpty(assemblyText))
                throw new ArgumentException("Assembly text cannot be empty", nameof(assemblyText));

            var program = new ExecutableProgram();
            var lines = assemblyText.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
            int instructionIndex = 0;

            // First pass: collect labels and build instruction list
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (string.IsNullOrWhiteSpace(trimmed))
                    continue;

                // Check for comment-only line (starts with #)
                if (trimmed.StartsWith("#"))
                    continue;

                // Check for label
                string labelName = null;
                if (trimmed.Contains(":"))
                {
                    var colonIndex = trimmed.IndexOf(':');
                    labelName = trimmed.Substring(0, colonIndex).Trim();
                    trimmed = trimmed.Substring(colonIndex + 1).Trim();
                    
                    // If line is just a label with optional comment, handle it
                    var commentIndex = trimmed.IndexOf('#');
                    if (commentIndex >= 0)
                    {
                        trimmed = trimmed.Substring(0, commentIndex).Trim();
                    }
                    
                    if (!string.IsNullOrWhiteSpace(labelName))
                    {
                        program.Labels[labelName] = instructionIndex;
                    }
                    
                    // If nothing after label, create empty instruction entry for label
                    if (string.IsNullOrWhiteSpace(trimmed))
                    {
                        var labelInstruction = new ExecutableInstruction
                        {
                            Instruction = "", // Empty instruction = label only
                            LineNumber = instructionIndex + 1
                        };
                        program.Instructions.Add(labelInstruction);
                        instructionIndex++;
                        continue;
                    }
                }

                // Check for conditional prefix (+ or -)
                bool isConditional = false;
                bool conditionalPositive = false;
                if (trimmed.StartsWith("+"))
                {
                    isConditional = true;
                    conditionalPositive = true;
                    trimmed = trimmed.Substring(1).Trim();
                }
                else if (trimmed.StartsWith("-"))
                {
                    isConditional = true;
                    conditionalPositive = false;
                    trimmed = trimmed.Substring(1).Trim();
                }

                // Check for comment
                var commentIndex2 = trimmed.IndexOf('#');
                if (commentIndex2 >= 0)
                {
                    trimmed = trimmed.Substring(0, commentIndex2).Trim();
                }

                if (string.IsNullOrWhiteSpace(trimmed))
                    continue;

                // Parse instruction and operands
                var parts = trimmed.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length == 0)
                    continue;

                var instruction = new ExecutableInstruction
                {
                    Instruction = parts[0],
                    IsConditional = isConditional,
                    ConditionalPositive = conditionalPositive,
                    LineNumber = instructionIndex + 1
                };

                for (int i = 1; i < parts.Length; i++)
                {
                    instruction.Operands.Add(parts[i]);
                }

                program.Instructions.Add(instruction);
                instructionIndex++;
            }

            return program;
        }
    }
}

