using System;
using System.Collections.Generic;
using System.Text;

namespace Sio.Assembler.Parse
{
    public sealed class Tokenizer
    {
        public IList<Token> Tokenize(string input)
        {
            var tokens = new List<Token>();
            if (string.IsNullOrEmpty(input))
                return tokens;

            var lines = input.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
            int lineNumber = 1;

            foreach (var line in lines)
            {
                var column = 0;
                var i = 0;

                while (i < line.Length)
                {
                    // Skip whitespace
                    if (char.IsWhiteSpace(line[i]))
                    {
                        i++;
                        column++;
                        continue;
                    }

                    // Handle label (identifier followed by colon)
                    if (char.IsLetter(line[i]) || line[i] == '_')
                    {
                        var start = i;
                        while (i < line.Length && (char.IsLetterOrDigit(line[i]) || line[i] == '_'))
                        {
                            i++;
                            column++;
                        }
                        var identifier = line.Substring(start, i - start);
                        
                        // Check if followed by colon (label)
                        if (i < line.Length && line[i] == ':')
                        {
                            tokens.Add(new Token(identifier, TokenType.Label, lineNumber, column - identifier.Length, isLabel: true));
                            tokens.Add(new Token(":", TokenType.Colon, lineNumber, column));
                            i++;
                            column++;
                        }
                        else
                        {
                            tokens.Add(new Token(identifier, TokenType.Identifier, lineNumber, column - identifier.Length));
                        }
                        continue;
                    }

                    // Handle colon
                    if (line[i] == ':')
                    {
                        tokens.Add(new Token(":", TokenType.Colon, lineNumber, column));
                        i++;
                        column++;
                        continue;
                    }

                    // Handle conditional prefixes (+ or -)
                    // These must be followed by whitespace then an instruction
                    if ((line[i] == '+' || line[i] == '-') && 
                        i + 1 < line.Length && char.IsWhiteSpace(line[i + 1]))
                    {
                        tokens.Add(new Token(line[i].ToString(), TokenType.Identifier, lineNumber, column));
                        i++;
                        column++;
                        continue;
                    }

                    // Handle numbers (including negative numbers)
                    if (char.IsDigit(line[i]) || (line[i] == '-' && i + 1 < line.Length && char.IsDigit(line[i + 1])))
                    {
                        var start = i;
                        if (line[i] == '-')
                        {
                            i++;
                            column++;
                        }
                        while (i < line.Length && char.IsDigit(line[i]))
                        {
                            i++;
                            column++;
                        }
                        var number = line.Substring(start, i - start);
                        tokens.Add(new Token(number, TokenType.Number, lineNumber, column - number.Length));
                        continue;
                    }


                    // Unknown character - skip it
                    i++;
                    column++;
                }

                // Add newline token (except for last line if it's empty)
                if (lineNumber < lines.Length || line.Trim().Length > 0)
                {
                    tokens.Add(new Token("\n", TokenType.Newline, lineNumber, column));
                }

                lineNumber++;
            }

            tokens.Add(new Token("", TokenType.EndOfFile, lineNumber, 0));
            return tokens;
        }
    }
}

