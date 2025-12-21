using System.Collections.Generic;

namespace Sio.Assembler.Model
{
    public sealed class SourceProject
    {
        public string EntryFile { get; }
        public IReadOnlyList<string> IncludePaths { get; }
        public ISet<string> Files { get; }

        public SourceProject(string entryFile, IReadOnlyList<string> includePaths, ISet<string> files)
        {
            EntryFile = entryFile;
            IncludePaths = includePaths;
            Files = files;
        }
    }
}

