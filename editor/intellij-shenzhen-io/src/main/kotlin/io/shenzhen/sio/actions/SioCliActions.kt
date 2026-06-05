package io.shenzhen.sio.actions

import com.intellij.execution.RunContentExecutor
import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.OSProcessHandler
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.vfs.VirtualFile
import io.shenzhen.sio.ShenzhenIoFileType
import io.shenzhen.sio.SioPaths

/** Base for actions that run the `sio` CLI on the active .asm file. */
abstract class SioCliAction(private val title: String) : AnAction() {

    /** Arguments after the input file path (the file path is inserted first). */
    protected abstract fun extraArgs(inputPath: String): List<String>

    /** The sio subcommand, e.g. "assemble". */
    protected abstract val subcommand: String

    override fun getActionUpdateThread(): ActionUpdateThread = ActionUpdateThread.BGT

    override fun update(e: AnActionEvent) {
        val file = e.getData(CommonDataKeys.VIRTUAL_FILE)
        e.presentation.isEnabledAndVisible = file != null && file.fileType == ShenzhenIoFileType
    }

    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        val file = e.getData(CommonDataKeys.VIRTUAL_FILE) ?: return

        // Persist edits so the CLI sees current content.
        FileDocumentManager.getInstance().saveAllDocuments()

        val cli = SioPaths.cli(project) ?: run {
            Messages.showErrorDialog(
                project,
                "sio CLI not found. Build it or set the SIO_CLI environment variable.",
                title
            )
            return
        }

        val commandLine = buildCommandLine(project, cli, file)
        val handler = OSProcessHandler(commandLine)
        RunContentExecutor(project, handler)
            .withTitle(title)
            .withActivateToolWindow(true)
            .run()
    }

    private fun buildCommandLine(project: Project, cli: String, file: VirtualFile): GeneralCommandLine {
        val inputPath = file.path
        val cmd = GeneralCommandLine()
        // The repo wrapper is a shell script on *nix; an .exe needs mono.
        if (!SioPaths.isWindows() && cli.endsWith(".exe")) {
            cmd.exePath = SioPaths.mono()
            cmd.addParameter(cli)
        } else {
            cmd.exePath = cli
        }
        cmd.addParameter(subcommand)
        cmd.addParameter(inputPath)
        cmd.addParameters(extraArgs(inputPath))
        project.basePath?.let { cmd.setWorkDirectory(it) }
        return cmd
    }
}

class SioAssembleAction : SioCliAction("sio assemble") {
    override val subcommand = "assemble"
    override fun extraArgs(inputPath: String): List<String> =
        listOf("-o", inputPath.removeSuffix(".asm") + ".out.txt")
}

class SioSimulateAction : SioCliAction("sio simulate") {
    override val subcommand = "simulate"
    override fun extraArgs(inputPath: String): List<String> = listOf("--trace")
}

class SioTestAction : SioCliAction("sio test") {
    override val subcommand = "test"
    override fun extraArgs(inputPath: String): List<String> = emptyList()
}
