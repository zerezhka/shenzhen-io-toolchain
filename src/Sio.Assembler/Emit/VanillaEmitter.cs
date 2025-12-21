using System.Text;
using Sio.Assembler.Parse;

namespace Sio.Assembler.Emit
{
    public sealed class VanillaEmitter
    {
        public string Emit(Program program)
        {
            var result = new StringBuilder();

            foreach (var statement in program.Statements)
            {
                if (statement.IsLabel)
                {
                    result.Append(statement.Label);
                    result.Append(":\n");
                }
                else if (!string.IsNullOrEmpty(statement.Instruction))
                {
                    if (!string.IsNullOrEmpty(statement.ConditionalPrefix))
                    {
                        result.Append(statement.ConditionalPrefix);
                        result.Append(" ");
                    }
                    result.Append(statement.Instruction);
                    foreach (var operand in statement.Operands)
                    {
                        result.Append(" ");
                        result.Append(operand);
                    }
                    result.Append("\n");
                }
            }

            var output = result.ToString().TrimEnd('\n');
            // Ensure trailing newline (standard for text files)
            return output + "\n";
        }
    }
}
