package io.shenzhen.sio

import com.intellij.icons.AllIcons
import com.intellij.openapi.fileTypes.LanguageFileType
import javax.swing.Icon

object ShenzhenIoFileType : LanguageFileType(ShenzhenIoLanguage) {
    override fun getName(): String = "Shenzhen I/O"
    override fun getDescription(): String = "Shenzhen I/O assembly"
    override fun getDefaultExtension(): String = "asm"
    override fun getIcon(): Icon = AllIcons.FileTypes.Custom
}
