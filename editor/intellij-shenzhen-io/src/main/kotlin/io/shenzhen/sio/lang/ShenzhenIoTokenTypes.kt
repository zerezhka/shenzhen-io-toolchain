package io.shenzhen.sio.lang

import com.intellij.psi.tree.IElementType
import com.intellij.psi.tree.IFileElementType
import io.shenzhen.sio.ShenzhenIoLanguage

/**
 * The "vocabulary" your lexer speaks: every chunk of text the lexer recognizes
 * is tagged with one of these [IElementType]s. The syntax highlighter then maps
 * each type to a color (see ShenzhenIoSyntaxHighlighter).
 *
 * Add or remove types freely as you design your lexer. For whitespace and
 * unrecognized characters, prefer the platform's built-ins
 * `com.intellij.psi.TokenType.WHITE_SPACE` and `...BAD_CHARACTER` — the editor
 * treats those specially.
 */
object ShenzhenIoTokenTypes {
    // A small starter vocabulary. Tweak to taste.
    @JvmField val COMMENT = IElementType("SIO_COMMENT", ShenzhenIoLanguage)
    @JvmField val INSTRUCTION = IElementType("SIO_INSTRUCTION", ShenzhenIoLanguage)
    @JvmField val REGISTER = IElementType("SIO_REGISTER", ShenzhenIoLanguage)
    @JvmField val LABEL = IElementType("SIO_LABEL", ShenzhenIoLanguage)
    @JvmField val NUMBER = IElementType("SIO_NUMBER", ShenzhenIoLanguage)
    @JvmField val IDENTIFIER = IElementType("SIO_IDENTIFIER", ShenzhenIoLanguage)
    @JvmField val CONDITIONAL = IElementType("SIO_CONDITIONAL", ShenzhenIoLanguage)

    // TODO: consider adding types as you go, e.g.:
    //   COLON (the ':' after a label), STRING, etc.

    /** The root node type for a whole .asm file. You won't usually touch this. */
    @JvmField val FILE = IFileElementType(ShenzhenIoLanguage)
}
