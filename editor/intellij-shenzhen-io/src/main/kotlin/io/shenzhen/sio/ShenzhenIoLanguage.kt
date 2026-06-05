package io.shenzhen.sio

import com.intellij.lang.Language

object ShenzhenIoLanguage : Language("ShenzhenIO") {
    private fun readResolve(): Any = ShenzhenIoLanguage
    override fun getDisplayName(): String = "Shenzhen I/O"
}
