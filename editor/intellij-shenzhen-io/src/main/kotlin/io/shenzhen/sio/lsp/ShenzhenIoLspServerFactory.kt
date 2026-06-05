package io.shenzhen.sio.lsp

import com.intellij.openapi.project.Project
import com.redhat.devtools.lsp4ij.LanguageServerFactory
import com.redhat.devtools.lsp4ij.server.ProcessStreamConnectionProvider
import com.redhat.devtools.lsp4ij.server.StreamConnectionProvider
import io.shenzhen.sio.SioPaths

class ShenzhenIoLspServerFactory : LanguageServerFactory {
    override fun createConnectionProvider(project: Project): StreamConnectionProvider =
        ShenzhenIoConnectionProvider(project)
}

private class ShenzhenIoConnectionProvider(project: Project) : ProcessStreamConnectionProvider() {
    init {
        val server = SioPaths.languageServer(project)
            ?: throw IllegalStateException(
                "sio-langserver.exe not found. Build it with `dotnet build src/Sio.EditorSupport` " +
                    "or set the SIO_LANGSERVER environment variable."
            )
        val commands = if (SioPaths.isWindows()) {
            mutableListOf(server)
        } else {
            mutableListOf(SioPaths.mono(), server)
        }
        super.setCommands(commands)
        project.basePath?.let { super.setWorkingDirectory(it) }
    }
}
