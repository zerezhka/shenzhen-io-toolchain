using System.Collections.Generic;

namespace Sio.EditorSupport.Server
{
    /// <summary>In-memory store of open document text, keyed by URI.</summary>
    public sealed class DocumentStore
    {
        private readonly Dictionary<string, string> _docs = new Dictionary<string, string>();

        public void Set(string uri, string text) => _docs[uri] = text ?? string.Empty;

        public void Remove(string uri) => _docs.Remove(uri);

        public bool TryGet(string uri, out string text) => _docs.TryGetValue(uri, out text);
    }
}
