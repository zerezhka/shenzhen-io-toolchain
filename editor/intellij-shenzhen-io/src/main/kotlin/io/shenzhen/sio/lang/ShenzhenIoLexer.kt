package io.shenzhen.sio.lang

import com.intellij.lexer.LexerBase
import com.intellij.psi.TokenType
import com.intellij.psi.tree.IElementType

/**
 * A lexer (a.k.a. tokenizer) splits raw text into a flat stream of tokens.
 *
 * How IntelliJ drives it:
 *   1. It calls [start] once with the text and the range to scan.
 *   2. It reads [getTokenType] / [getTokenStart] / [getTokenEnd] for the
 *      *current* token.
 *   3. It calls [advance] to move to the next token, and repeats step 2 until
 *      [getTokenType] returns null (end of input).
 *
 * So the whole job is: "given a position in the text, figure out where the next
 * token ends and what kind it is." All of that lives in [scan] below.
 *
 * Two examples (whitespace and line comments) are implemented for you. Fill in
 * the TODOs for the rest. You can run the plugin after each change to watch the
 * colors appear.
 */
class ShenzhenIoLexer : LexerBase() {

    private var text: CharSequence = ""
    private var endOffset = 0

    // The current token spans [tokenStart, tokenEnd); tokenType is its kind.
    private var tokenStart = 0
    private var tokenEnd = 0
    private var tokenType: IElementType? = null

    override fun start(buffer: CharSequence, startOffset: Int, endOffset: Int, initialState: Int) {
        this.text = buffer
        this.endOffset = endOffset
        this.tokenStart = startOffset
        this.tokenEnd = startOffset
        scan() // compute the first token
    }

    override fun advance() = scan()

    override fun getTokenType(): IElementType? = tokenType
    override fun getTokenStart(): Int = tokenStart
    override fun getTokenEnd(): Int = tokenEnd
    override fun getState(): Int = 0
    override fun getBufferSequence(): CharSequence = text
    override fun getBufferEnd(): Int = endOffset

    /**
     * Computes the next token: sets [tokenStart], [tokenEnd], and [tokenType].
     * When there's nothing left, sets [tokenType] to null.
     */
    private fun scan() {
        tokenStart = tokenEnd
        if (tokenStart >= endOffset) {
            tokenType = null
            return
        }

        val c = text[tokenStart]

        when {
            // --- worked example 1: whitespace (spaces, tabs, newlines) ---
            c.isWhitespace() -> {
                tokenEnd = consumeWhile { it.isWhitespace() }
                // Use the platform's whitespace type so the editor treats it right.
                tokenType = TokenType.WHITE_SPACE
            }

            // --- worked example 2: line comment starting with # or ; ---
            c == '#' || c == ';' -> {
                tokenEnd = consumeWhile { it != '\n' && it != '\r' }
                tokenType = ShenzhenIoTokenTypes.COMMENT
            }

            // TODO: block comments  /* ... */   -> ShenzhenIoTokenTypes.COMMENT
            //   Hint: once you see "/*", keep consuming until you find "*/".

            // TODO: numbers (e.g. 100, -5)       -> ShenzhenIoTokenTypes.NUMBER
            //   Hint: an optional '-' followed by one or more digits.

            // TODO: words (letters/underscores) -> classify them:
            //   - if followed by ':'            -> ShenzhenIoTokenTypes.LABEL
            //   - if it's an instruction        -> ShenzhenIoTokenTypes.INSTRUCTION
            //     (see Mnemonics below)
            //   - if it looks like a register   -> ShenzhenIoTokenTypes.REGISTER
            //     (acc, dat, null, p0..p9, x0..x9)
            //   - otherwise                     -> ShenzhenIoTokenTypes.IDENTIFIER

            // --- fallback: consume a single unknown character so we never get stuck ---
            else -> {
                tokenEnd = tokenStart + 1
                tokenType = TokenType.BAD_CHARACTER
            }
        }
    }

    /**
     * Advances from [tokenStart] while [predicate] holds, and returns the new
     * end offset. Always advances at least one character.
     */
    private inline fun consumeWhile(predicate: (Char) -> Boolean): Int {
        var i = tokenStart
        while (i < endOffset && predicate(text[i])) i++
        return if (i == tokenStart) tokenStart + 1 else i
    }

    companion object {
        /** The Shenzhen I/O instruction mnemonics, handy for classifying words. */
        val Mnemonics = setOf(
            "nop", "mov", "jmp", "slp", "slx",
            "teq", "tgt", "tlt", "tcp",
            "add", "sub", "mul", "not", "dgt", "dst",
            "gen"
        )
    }
}
