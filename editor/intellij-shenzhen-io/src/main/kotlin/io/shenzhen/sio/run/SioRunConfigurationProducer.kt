package io.shenzhen.sio.run

import com.intellij.execution.actions.ConfigurationContext
import com.intellij.execution.actions.LazyRunConfigurationProducer
import com.intellij.execution.configurations.ConfigurationFactory
import com.intellij.openapi.util.Ref
import com.intellij.psi.PsiElement
import io.shenzhen.sio.ShenzhenIoFileType

class SioRunConfigurationProducer : LazyRunConfigurationProducer<SioRunConfiguration>() {

    override fun getConfigurationFactory(): ConfigurationFactory =
        SioConfigurationType.getInstance().factory

    override fun setupConfigurationFromContext(
        configuration: SioRunConfiguration,
        context: ConfigurationContext,
        sourceElement: Ref<PsiElement>
    ): Boolean {
        val file = context.psiLocation?.containingFile?.virtualFile ?: return false
        if (file.fileType != ShenzhenIoFileType) return false
        configuration.filePath = file.path
        configuration.command = "simulate"
        configuration.extraArgs = "--trace"
        configuration.name = file.name
        return true
    }

    override fun isConfigurationFromContext(
        configuration: SioRunConfiguration,
        context: ConfigurationContext
    ): Boolean {
        val file = context.psiLocation?.containingFile?.virtualFile ?: return false
        return file.fileType == ShenzhenIoFileType && file.path == configuration.filePath
    }
}
