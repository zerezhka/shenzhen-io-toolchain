package io.shenzhen.sio.run

import com.intellij.openapi.fileChooser.FileChooserDescriptorFactory
import com.intellij.openapi.options.SettingsEditor
import com.intellij.openapi.ui.TextFieldWithBrowseButton
import com.intellij.ui.components.JBTextField
import com.intellij.util.ui.FormBuilder
import javax.swing.JComponent
import javax.swing.JPanel

class SioSettingsEditor : SettingsEditor<SioRunConfiguration>() {
    private val fileField = TextFieldWithBrowseButton()
    private val commandCombo = com.intellij.openapi.ui.ComboBox(arrayOf("assemble", "simulate", "test"))
    private val argsField = JBTextField()
    private val panel: JPanel

    init {
        fileField.addBrowseFolderListener(
            null,
            FileChooserDescriptorFactory.createSingleFileDescriptor("asm")
                .withTitle("Select Shenzhen I/O File")
        )
        panel = FormBuilder.createFormBuilder()
            .addLabeledComponent("File:", fileField)
            .addLabeledComponent("Command:", commandCombo)
            .addLabeledComponent("Extra arguments:", argsField)
            .panel
    }

    override fun resetEditorFrom(s: SioRunConfiguration) {
        fileField.text = s.filePath
        commandCombo.selectedItem = s.command
        argsField.text = s.extraArgs
    }

    override fun applyEditorTo(s: SioRunConfiguration) {
        s.filePath = fileField.text
        s.command = (commandCombo.selectedItem as? String) ?: "simulate"
        s.extraArgs = argsField.text
    }

    override fun createEditor(): JComponent = panel
}
