using System;
using System.Collections.Generic;
using System.Linq;

namespace Sio.Assembler.Parse
{
    public sealed class Parser
    {
        // Valid Shenzhen I/O instructions per manual
        // Basic: nop, mov, jmp, slp, slx
        // Test: teq, tgt, tlt, tcp
        // Arithmetic: add, sub, mul, not, dgt, dst
        // Undocumented: gen, @
        private static readonly string[] ValidInstructions = {
            // Basic instructions
            "nop", "mov", "jmp", "slp", "slx",
            // Test instructions
            "teq", "tgt", "tlt", "tcp",
            // Arithmetic instructions
            "add", "sub", "mul", "not", "dgt", "dst",
            // Undocumented instructions (in-game email; absent from both manual PDFs)
            "gen", "@"
        };

        public Program Parse(string input)
        {
            var tokenizer = new Tokenizer();
            var tokens = tokenizer.Tokenize(input);
            var program = new Program();
            var i = 0;

            while (i < tokens.Count)
            {
                var token = tokens[i];

                if (token.Type == TokenType.EndOfFile)
                    break;

                if (token.Type == TokenType.Newline)
                {
                    i++;
                    continue;
                }

                // Handle label
                if (token.IsLabel && i + 1 < tokens.Count && tokens[i + 1].Type == TokenType.Colon)
                {
                    var statement = new Statement
                    {
                        IsLabel = true,
                        Label = token.Value
                    };
                    program.Statements.Add(statement);
                    i += 2; // Skip label and colon
                    continue;
                }

                // Handle conditional prefix (+ or -)
                if (token.Type == TokenType.Identifier && (token.Value == "+" || token.Value == "-"))
                {
                    var conditionalPrefix = token.Value;
                    i++; // Skip conditional prefix
                    
                    // Next token should be the instruction
                    if (i >= tokens.Count || tokens[i].Type != TokenType.Identifier)
                    {
                        throw new ParseException($"Expected instruction after '{conditionalPrefix}'", token.Line, token.Column);
                    }
                    
                    var instructionToken = tokens[i];
                    if (!IsValidInstruction(instructionToken.Value))
                    {
                        throw new ParseException($"Unknown instruction: {instructionToken.Value}", instructionToken.Line, instructionToken.Column);
                    }
                    
                    var statement = new Statement
                    {
                        Instruction = instructionToken.Value,
                        ConditionalPrefix = conditionalPrefix
                    };
                    i++; // Skip instruction
                    
                    // Collect operands
                    while (i < tokens.Count)
                    {
                        var nextToken = tokens[i];
                        if (nextToken.Type == TokenType.Newline || nextToken.Type == TokenType.EndOfFile)
                            break;

                        if (nextToken.Type == TokenType.Identifier || nextToken.Type == TokenType.Number)
                        {
                            statement.Operands.Add(nextToken.Value);
                            i++;
                        }
                        else
                        {
                            break;
                        }
                    }
                    
                    program.Statements.Add(statement);
                    continue;
                }

                // Handle instruction
                if (token.Type == TokenType.Identifier && IsValidInstruction(token.Value))
                {
                    var statement = new Statement
                    {
                        Instruction = token.Value
                    };
                    i++; // Skip instruction

                    // Collect operands
                    while (i < tokens.Count)
                    {
                        var nextToken = tokens[i];
                        if (nextToken.Type == TokenType.Newline || nextToken.Type == TokenType.EndOfFile)
                            break;

                        if (nextToken.Type == TokenType.Identifier || nextToken.Type == TokenType.Number)
                        {
                            statement.Operands.Add(nextToken.Value);
                            i++;
                        }
                        else
                        {
                            break;
                        }
                    }

                    program.Statements.Add(statement);
                    continue;
                }

                // Unknown token - throw error
                throw new ParseException($"Unexpected token: {token.Value}", token.Line, token.Column);
            }

            return program;
        }

        private bool IsValidInstruction(string value)
        {
            return ValidInstructions.Contains(value, StringComparer.OrdinalIgnoreCase);
        }
    }
}

