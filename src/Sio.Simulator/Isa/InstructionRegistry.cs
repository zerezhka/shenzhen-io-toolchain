using System;
using System.Collections.Generic;
using System.Linq;
using Sio.Simulator.Isa.Instructions;

namespace Sio.Simulator.Isa
{
    /// <summary>
    /// Registry of instruction implementations.
    /// </summary>
    public static class InstructionRegistry
    {
        private static readonly Dictionary<string, IInstruction> _instructions = new Dictionary<string, IInstruction>(StringComparer.OrdinalIgnoreCase);

        static InstructionRegistry()
        {
            // Register all instructions
            Register(new Nop());
            Register(new Mov());
            Register(new Add());
            Register(new Sub());
            Register(new Mul());
            Register(new Not());
            Register(new Dgt());
            Register(new Dst());
            Register(new Jmp());
            Register(new Teq());
            Register(new Tgt());
            Register(new Tlt());
            Register(new Tcp());
            Register(new Slp());
            Register(new Slx());
            // Register(new Slp());
            // Register(new Slx());
            // Register(new Tgt());
            // Register(new Tlt());
            // Register(new Tcp());
            // Register(new Mul());
            // Register(new Not());
            // Register(new Dgt());
            // Register(new Dst());
        }

        private static void Register(IInstruction instruction)
        {
            if (instruction == null)
                throw new ArgumentNullException(nameof(instruction));
            
            _instructions[instruction.Name] = instruction;
        }

        /// <summary>
        /// Gets an instruction handler by name.
        /// </summary>
        public static IInstruction GetInstruction(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return null;
            
            _instructions.TryGetValue(name, out var instruction);
            return instruction;
        }

        /// <summary>
        /// Gets all registered instruction names.
        /// </summary>
        public static IEnumerable<string> GetAllInstructionNames()
        {
            return _instructions.Keys;
        }

        /// <summary>
        /// Checks if an instruction is implemented.
        /// </summary>
        public static bool IsImplemented(string name)
        {
            return GetInstruction(name) != null;
        }
    }
}

