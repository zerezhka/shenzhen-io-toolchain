package io.shenzhen.sio.run

import com.intellij.execution.ExecutionException
import com.intellij.execution.Executor
import com.intellij.execution.configurations.ConfigurationFactory
import com.intellij.execution.configurations.CommandLineState
import com.intellij.execution.configurations.LocatableConfigurationBase
import com.intellij.execution.configurations.RunConfiguration
import com.intellij.execution.configurations.RunProfileState
import com.intellij.execution.process.KillableColoredProcessHandler
import com.intellij.execution.process.ProcessHandler
import com.intellij.execution.process.ProcessTerminatedListener
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.openapi.options.SettingsEditor
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.JDOMExternalizerUtil
import io.shenzhen.sio.SioCommand
import org.jdom.Element

class SioRunConfiguration(
    project: Project,
    factory: ConfigurationFactory,
    name: String
) : LocatableConfigurationBase<Element>(project, factory, name) {

    var filePath: String = ""
    var command: String = "simulate"
    var extraArgs: String = "--trace"

    override fun getConfigurationEditor(): SettingsEditor<out RunConfiguration> = SioSettingsEditor()

    override fun checkConfiguration() {
        if (filePath.isBlank()) {
            throw com.intellij.execution.configurations.RuntimeConfigurationError("No input file specified.")
        }
    }

    override fun getState(executor: Executor, environment: ExecutionEnvironment): RunProfileState =
        object : CommandLineState(environment) {
            @Throws(ExecutionException::class)
            override fun startProcess(): ProcessHandler {
                val cmd = SioCommand.build(project, command, filePath, SioCommand.splitArgs(extraArgs))
                    ?: throw ExecutionException(
                        "sio CLI not found. Build it or set the SIO_CLI environment variable."
                    )
                val handler = KillableColoredProcessHandler(cmd)
                ProcessTerminatedListener.attach(handler)
                return handler
            }
        }

    override fun writeExternal(element: Element) {
        super.writeExternal(element)
        JDOMExternalizerUtil.writeField(element, "filePath", filePath)
        JDOMExternalizerUtil.writeField(element, "command", command)
        JDOMExternalizerUtil.writeField(element, "extraArgs", extraArgs)
    }

    override fun readExternal(element: Element) {
        super.readExternal(element)
        filePath = JDOMExternalizerUtil.readField(element, "filePath", "")
        command = JDOMExternalizerUtil.readField(element, "command", "simulate")
        extraArgs = JDOMExternalizerUtil.readField(element, "extraArgs", "")
    }
}
