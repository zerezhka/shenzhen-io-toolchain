package io.shenzhen.sio

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.openapi.project.Project

/** Builds the `sio` CLI command line, shared by editor actions and run configs. */
object SioCommand {
    /** Returns null if the CLI cannot be located. */
    fun build(
        project: Project,
        subcommand: String,
        filePath: String,
        extraArgs: List<String>
    ): GeneralCommandLine? {
        val cli = SioPaths.cli(project) ?: return null
        val cmd = GeneralCommandLine()
        // The repo wrapper is a shell script on *nix; an .exe needs mono.
        if (!SioPaths.isWindows() && cli.endsWith(".exe")) {
            cmd.exePath = SioPaths.mono()
            cmd.addParameter(cli)
        } else {
            cmd.exePath = cli
        }
        cmd.addParameter(subcommand)
        cmd.addParameter(filePath)
        cmd.addParameters(extraArgs)
        project.basePath?.let { cmd.setWorkDirectory(it) }
        return cmd
    }

    /** Splits a free-form argument string into individual arguments. */
    fun splitArgs(args: String): List<String> =
        args.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
}
