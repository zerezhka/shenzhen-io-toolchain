using System;
using System.IO;
using System.Linq;
using Sio.Assembler.IO;
using Sio.Assembler.Model;
using Sio.Assembler.Preprocessor;
using Sio.Assembler.Parse;
using Sio.Assembler.Emit;
using Sio.Cli.Output;

namespace Sio.Cli.Commands
{
    public sealed class AssembleCommand
    {
        private readonly ConsoleWriter _writer;

        public AssembleCommand(ConsoleWriter writer)
        {
            _writer = writer ?? throw new ArgumentNullException(nameof(writer));
        }

        public int Execute(string[] args)
        {
            if (args == null || args.Length < 1)
            {
                _writer.WriteErrorLine("sio assemble: missing input file");
                _writer.WriteErrorLine("Usage: sio assemble <input.asm> [-o <output.asm>]");
                return ExitCodes.Usage;
            }

            var inputFile = args[0];
            string outputFile = null;

            // Parse -o option
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "-o" && i + 1 < args.Length)
                {
                    outputFile = args[i + 1];
                    i++;
                }
            }

            try
            {
                // Load source files
                var loader = new SourceLoader();
                var includePaths = new[] { Path.GetDirectoryName(Path.GetFullPath(inputFile)) };
                var project = loader.Load(inputFile, includePaths);

                // Preprocess
                var preprocessor = new Preprocessor();
                var preprocessed = preprocessor.Process(project);

                // Parse and emit (for validation and normalization)
                var parser = new Parser();
                var program = parser.Parse(preprocessed);
                var emitter = new VanillaEmitter();
                var output = emitter.Emit(program);

                // Write output
                if (string.IsNullOrEmpty(outputFile))
                {
                    _writer.WriteInfoLine(output);
                }
                else
                {
                    File.WriteAllText(outputFile, output);
                }

                return ExitCodes.Ok;
            }
            catch (FileNotFoundException ex)
            {
                _writer.WriteErrorLine($"sio assemble: file not found: {ex.Message}");
                return ExitCodes.Error;
            }
            catch (Exception ex)
            {
                _writer.WriteErrorLine($"sio assemble: error: {ex.Message}");
                return ExitCodes.Error;
            }
        }
    }
}

