package io.shenzhen.sio.lang

import com.intellij.psi.tree.IElementType
import com.intellij.psi.tree.IFileElementType
import io.shenzhen.sio.ShenzhenIoLanguage

object ShenzhenIoTokenTypes {
    @JvmField
    val CONTENT = IElementType("SIO_CONTENT", ShenzhenIoLanguage)

    @JvmField
    val FILE = IFileElementType(ShenzhenIoLanguage)
}
