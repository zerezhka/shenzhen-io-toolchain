package io.shenzhen.sio.lang

import com.intellij.lexer.LexerBase
import com.intellij.psi.tree.IElementType

/**
 * Trivial lexer that treats the whole file as a single CONTENT token. The real
 * language semantics are provided by the LSP server; this exists only so the
 * platform can build a PSI tree for the file.
 */
class ShenzhenIoLexer : LexerBase() {
    private var buffer: CharSequence = ""
    private var endOffset = 0
    private var tokenStart = 0
    private var tokenEnd = 0

    override fun start(buffer: CharSequence, startOffset: Int, endOffset: Int, initialState: Int) {
        this.buffer = buffer
        this.endOffset = endOffset
        this.tokenStart = startOffset
        this.tokenEnd = endOffset
    }

    override fun getState(): Int = 0

    override fun getTokenType(): IElementType? =
        if (tokenStart < tokenEnd) ShenzhenIoTokenTypes.CONTENT else null

    override fun getTokenStart(): Int = tokenStart

    override fun getTokenEnd(): Int = tokenEnd

    override fun advance() {
        tokenStart = tokenEnd
    }

    override fun getBufferSequence(): CharSequence = buffer

    override fun getBufferEnd(): Int = endOffset
}
