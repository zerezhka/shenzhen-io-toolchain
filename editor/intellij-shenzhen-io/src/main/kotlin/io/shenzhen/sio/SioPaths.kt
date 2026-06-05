package io.shenzhen.sio

import com.intellij.openapi.project.Project
import com.intellij.openapi.util.SystemInfo
import java.io.File

/**
 * Locates the toolchain executables relative to the open project (the repo root),
 * with environment-variable overrides for non-standard layouts.
 */
object SioPaths {
    private val SERVER_REL = listOf(
        "src", "Sio.EditorSupport", "bin", "Debug", "net472", "sio-langserver.exe"
    )

    /** Path to sio-langserver.exe, or null if it cannot be found. */
    fun languageServer(project: Project): String? {
        System.getenv("SIO_LANGSERVER")?.let { if (File(it).isFile) return it }
        val base = project.basePath ?: return null
        val candidate = File(base, SERVER_REL.joinToString(File.separator))
        return if (candidate.isFile) candidate.absolutePath else null
    }

    /** Path to the sio CLI wrapper/exe, or null if it cannot be found. */
    fun cli(project: Project): String? {
        System.getenv("SIO_CLI")?.let { if (File(it).isFile) return it }
        val base = project.basePath ?: return null
        val wrapper = File(base, "sio")
        return if (wrapper.isFile) wrapper.absolutePath else null
    }

    /** Mono runtime used to run .NET executables on non-Windows platforms. */
    fun mono(): String = System.getenv("SIO_MONO") ?: "mono"

    fun isWindows(): Boolean = SystemInfo.isWindows
}
