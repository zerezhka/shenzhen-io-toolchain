using System.Text;
using System.Text.RegularExpressions;

namespace Sio.Assembler.Preprocessor
{
    public sealed class CommentStripper
    {
        public string Strip(string input)
        {
            if (string.IsNullOrEmpty(input))
                return input;

            var result = new StringBuilder();
            var i = 0;
            var inBlockComment = false;

            while (i < input.Length)
            {
                if (inBlockComment)
                {
                    // Look for end of block comment */
                    if (i < input.Length - 1 && input[i] == '*' && input[i + 1] == '/')
                    {
                        inBlockComment = false;
                        i += 2;
                        continue;
                    }
                    i++;
                }
                else
                {
                    // Look for start of block comment /*
                    if (i < input.Length - 1 && input[i] == '/' && input[i + 1] == '*')
                    {
                        inBlockComment = true;
                        i += 2;
                        continue;
                    }

                    // Look for line comment # (Shenzhen I/O uses #, not ;)
                    if (input[i] == '#')
                    {
                        // Skip to end of line
                        while (i < input.Length && input[i] != '\n' && input[i] != '\r')
                        {
                            i++;
                        }
                        continue;
                    }
                    
                    // Also support ; as an extended feature (but # is canonical)
                    if (input[i] == ';')
                    {
                        // Skip to end of line
                        while (i < input.Length && input[i] != '\n' && input[i] != '\r')
                        {
                            i++;
                        }
                        continue;
                    }

                    result.Append(input[i]);
                    i++;
                }
            }

            return result.ToString();
        }
    }
}

