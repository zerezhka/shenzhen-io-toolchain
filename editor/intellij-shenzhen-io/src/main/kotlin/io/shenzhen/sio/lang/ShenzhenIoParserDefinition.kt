package io.shenzhen.sio.lang

import com.intellij.extapi.psi.ASTWrapperPsiElement
import com.intellij.extapi.psi.PsiFileBase
import com.intellij.lang.ASTNode
import com.intellij.lang.ParserDefinition
import com.intellij.lang.PsiParser
import com.intellij.lexer.Lexer
import com.intellij.openapi.project.Project
import com.intellij.psi.FileViewProvider
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.tree.IFileElementType
import com.intellij.psi.tree.TokenSet
import io.shenzhen.sio.ShenzhenIoFileType
import io.shenzhen.sio.ShenzhenIoLanguage

class ShenzhenIoParserDefinition : ParserDefinition {
    override fun createLexer(project: Project?): Lexer = ShenzhenIoLexer()

    override fun createParser(project: Project?): PsiParser = PsiParser { root, builder ->
        val mark = builder.mark()
        while (!builder.eof()) {
            builder.advanceLexer()
        }
        mark.done(root)
        builder.treeBuilt
    }

    override fun getFileNodeType(): IFileElementType = ShenzhenIoTokenTypes.FILE

    override fun getCommentTokens(): TokenSet = TokenSet.EMPTY

    override fun getStringLiteralElements(): TokenSet = TokenSet.EMPTY

    override fun createElement(node: ASTNode): PsiElement = ASTWrapperPsiElement(node)

    override fun createFile(viewProvider: FileViewProvider): PsiFile = ShenzhenIoPsiFile(viewProvider)
}

class ShenzhenIoPsiFile(viewProvider: FileViewProvider) :
    PsiFileBase(viewProvider, ShenzhenIoLanguage) {
    override fun getFileType() = ShenzhenIoFileType
    override fun toString() = "Shenzhen I/O File"
}
