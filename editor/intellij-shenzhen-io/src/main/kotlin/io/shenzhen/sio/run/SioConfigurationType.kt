package io.shenzhen.sio.run

import com.intellij.execution.configurations.ConfigurationFactory
import com.intellij.execution.configurations.ConfigurationType
import com.intellij.execution.configurations.ConfigurationTypeBase
import com.intellij.execution.configurations.RunConfiguration
import com.intellij.execution.configurations.ConfigurationTypeUtil
import com.intellij.icons.AllIcons
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.NotNullLazyValue

class SioConfigurationType : ConfigurationTypeBase(
    ID,
    "Shenzhen I/O",
    "Run Shenzhen I/O toolchain commands",
    NotNullLazyValue.createValue { AllIcons.Actions.Execute }
) {
    init {
        addFactory(SioConfigurationFactory(this))
    }

    val factory: ConfigurationFactory
        get() = configurationFactories.first()

    companion object {
        const val ID = "ShenzhenIoRunConfiguration"

        fun getInstance(): SioConfigurationType =
            ConfigurationTypeUtil.findConfigurationType(SioConfigurationType::class.java)
    }
}

class SioConfigurationFactory(type: ConfigurationType) : ConfigurationFactory(type) {
    override fun getId(): String = SioConfigurationType.ID

    override fun createTemplateConfiguration(project: Project): RunConfiguration =
        SioRunConfiguration(project, this, "Shenzhen I/O")
}
