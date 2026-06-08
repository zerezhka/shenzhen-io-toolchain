package io.shenzhen.sio.lang

import com.intellij.lexer.Lexer
import com.intellij.openapi.editor.DefaultLanguageHighlighterColors
import com.intellij.openapi.editor.HighlighterColors
import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.fileTypes.SyntaxHighlighterBase
import com.intellij.openapi.fileTypes.SyntaxHighlighterFactory
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.psi.TokenType
import com.intellij.psi.tree.IElementType

/**
 * Maps each token type from [ShenzhenIoLexer] to a color.
 *
 * The right-hand `DefaultLanguageHighlighterColors.*` values are *semantic*
 * defaults that respect the user's theme (instructions look like keywords,
 * numbers like numbers, and so on). Adjust the mapping to taste; the colors
 * update as soon as the lexer tags a token with a given type.
 */
class ShenzhenIoSyntaxHighlighter : SyntaxHighlighterBase() {

    override fun getHighlightingLexer(): Lexer = ShenzhenIoLexer()

    override fun getTokenHighlights(tokenType: IElementType): Array<TextAttributesKey> =
        when (tokenType) {
            ShenzhenIoTokenTypes.COMMENT -> COMMENT_KEYS
            ShenzhenIoTokenTypes.INSTRUCTION -> INSTRUCTION_KEYS
            ShenzhenIoTokenTypes.REGISTER -> REGISTER_KEYS
            ShenzhenIoTokenTypes.LABEL -> LABEL_KEYS
            ShenzhenIoTokenTypes.NUMBER -> NUMBER_KEYS
            ShenzhenIoTokenTypes.IDENTIFIER -> EMPTY_KEYS // leave identifiers default
            ShenzhenIoTokenTypes.CONDITIONAL -> CONDITIONAL_KEYS
            TokenType.BAD_CHARACTER -> BAD_CHAR_KEYS
            else -> EMPTY_KEYS
        }

    companion object {
        private fun key(name: String, fallback: TextAttributesKey) =
            TextAttributesKey.createTextAttributesKey("SIO_$name", fallback)

        val COMMENT = key("COMMENT", DefaultLanguageHighlighterColors.LINE_COMMENT)
        val INSTRUCTION = key("INSTRUCTION", DefaultLanguageHighlighterColors.KEYWORD)
        val REGISTER = key("REGISTER", DefaultLanguageHighlighterColors.INSTANCE_FIELD)
        val LABEL = key("LABEL", DefaultLanguageHighlighterColors.FUNCTION_DECLARATION)
        val NUMBER = key("NUMBER", DefaultLanguageHighlighterColors.NUMBER)
        val CONDITIONAL = key("CONDITIONAL", DefaultLanguageHighlighterColors.NUMBER)
        val BAD_CHAR = key("BAD_CHARACTER", HighlighterColors.BAD_CHARACTER)

        private val COMMENT_KEYS = arrayOf(COMMENT)
        private val INSTRUCTION_KEYS = arrayOf(INSTRUCTION)
        private val REGISTER_KEYS = arrayOf(REGISTER)
        private val LABEL_KEYS = arrayOf(LABEL)
        private val NUMBER_KEYS = arrayOf(NUMBER)
        private val BAD_CHAR_KEYS = arrayOf(BAD_CHAR)
        private val CONDITIONAL_KEYS = arrayOf(CONDITIONAL)
        private val EMPTY_KEYS = emptyArray<TextAttributesKey>()
    }
}

/** Registers the highlighter with the platform (wired in plugin.xml). */
class ShenzhenIoSyntaxHighlighterFactory : SyntaxHighlighterFactory() {
    override fun getSyntaxHighlighter(project: Project?, virtualFile: VirtualFile?): SyntaxHighlighter =
        ShenzhenIoSyntaxHighlighter()
}
