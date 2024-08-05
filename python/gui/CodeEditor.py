import sys
import re
from PySide6.QtCore import Qt, QFile, QIODevice
from PySide6.QtGui import QIcon, QTextCursor, QTextCharFormat, QColor, QFont, QSyntaxHighlighter, QAction
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTextEdit, \
    QFileDialog, QFontDialog, QColorDialog, QMessageBox


class CodeEditorHighlighter(QSyntaxHighlighter):
    def __init__(self, parent):
        super().__init__(parent)
        self.parent = parent

        self.keyword_format = QTextCharFormat()
        self.keyword_format.setForeground(Qt.darkBlue)
        self.keyword_format.setFontWeight(QFont.Bold)

        self.string_format = QTextCharFormat()
        self.string_format.setForeground(Qt.darkGreen)

        self.comment_format = QTextCharFormat()
        self.comment_format.setForeground(Qt.gray)

        self.highlight_rules = [
            (r"\bint\b", self.keyword_format),
            (r"\bfloat\b", self.keyword_format),
            (r"\bstring\b", self.keyword_format),
            (r"\bif\b", self.keyword_format),
            (r"\belse\b", self.keyword_format),
            (r"\".*\"", self.string_format),
            (r"#[^\n]*", self.comment_format),
        ]

    def highlightBlock(self, text):
        for pattern, format_ in self.highlight_rules:
            expression = re.compile(pattern)
            matches = expression.finditer(text)
            for match in matches:
                start_index, end_index = match.span()
                self.setFormat(start_index, end_index - start_index, format_)


class CodeEditorApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Code Editor")
        self.setGeometry(100, 100, 800, 600)

        self.text_edit = QTextEdit()
        self.setCentralWidget(self.text_edit)

        self.highlighter = CodeEditorHighlighter(self.text_edit.document())

        self.create_actions()
        self.create_menus()
        self.create_toolbars()

    def create_actions(self):
        self.new_action = QAction(QIcon(), "New", self)
        self.new_action.setShortcut("Ctrl+N")
        self.new_action.triggered.connect(self.new_file)

        self.open_action = QAction(QIcon(), "Open", self)
        self.open_action.setShortcut("Ctrl+O")
        self.open_action.triggered.connect(self.open_file)

        self.save_action = QAction(QIcon(), "Save", self)
        self.save_action.setShortcut("Ctrl+S")
        self.save_action.triggered.connect(self.save_file)

        self.save_as_action = QAction(QIcon(), "Save As", self)
        self.save_as_action.setShortcut("Ctrl+Shift+S")
        self.save_as_action.triggered.connect(self.save_file_as)

        self.copy_action = QAction(QIcon(), "Copy", self)
        self.copy_action.setShortcut("Ctrl+C")
        self.copy_action.triggered.connect(self.copy_text)

        self.cut_action = QAction(QIcon(), "Cut", self)
        self.cut_action.setShortcut("Ctrl+X")
        self.cut_action.triggered.connect(self.cut_text)

        self.paste_action = QAction(QIcon(), "Paste", self)
        self.paste_action.setShortcut("Ctrl+V")
        self.paste_action.triggered.connect(self.paste_text)

        self.undo_action = QAction(QIcon(), "Undo", self)
        self.undo_action.setShortcut("Ctrl+Z")
        self.undo_action.triggered.connect(self.text_edit.undo)

        self.redo_action = QAction(QIcon(), "Redo", self)
        self.redo_action.setShortcut("Ctrl+Y")
        self.redo_action.triggered.connect(self.text_edit.redo)

        self.font_action = QAction(QIcon(), "Font", self)
        self.font_action.setShortcut("Ctrl+T")
        self.font_action.triggered.connect(self.select_font)

        self.color_action = QAction(QIcon(), "Color", self)
        self.color_action.setShortcut("Ctrl+L")
        self.color_action.triggered.connect(self.select_color)

    def create_menus(self):
        self.file_menu = self.menuBar().addMenu("File")
        self.file_menu.addAction(self.new_action)
        self.file_menu.addAction(self.open_action)
        self.file_menu.addAction(self.save_action)
        self.file_menu.addAction(self.save_as_action)

        self.edit_menu = self.menuBar().addMenu("Edit")
        self.edit_menu.addAction(self.undo_action)
        self.edit_menu.addAction(self.redo_action)
        self.edit_menu.addAction(self.copy_action)
        self.edit_menu.addAction(self.cut_action)
        self.edit_menu.addAction(self.paste_action)

        self.format_menu = self.menuBar().addMenu("Format")
        self.format_menu.addAction(self.font_action)
        self.format_menu.addAction(self.color_action)

    def create_toolbars(self):
        self.file_toolbar = self.addToolBar("File")
        self.file_toolbar.addAction(self.new_action)
        self.file_toolbar.addAction(self.open_action)
        self.file_toolbar.addAction(self.save_action)

        self.edit_toolbar = self.addToolBar("Edit")
        self.edit_toolbar.addAction(self.undo_action)
        self.edit_toolbar.addAction(self.redo_action)
        self.edit_toolbar.addAction(self.copy_action)
        self.edit_toolbar.addAction(self.cut_action)
        self.edit_toolbar.addAction(self.paste_action)

        self.format_toolbar = self.addToolBar("Format")
        self.format_toolbar.addAction(self.font_action)
        self.format_toolbar.addAction(self.color_action)

    def new_file(self):
        self.text_edit.clear()

    def open_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Open File")
        if file_path:
            file = QFile(file_path)
            if file.open(QIODevice.ReadOnly | QIODevice.Text):
                content = file.readAll().data().decode()
                self.text_edit.setPlainText(content)
                file.close()

    def save_file(self):
        if self.current_file_path:
            file = QFile(self.current_file_path)
            if file.open(QIODevice.WriteOnly | QIODevice.Text):
                content = self.text_edit.toPlainText()
                file.write(content.encode())
                file.close()
        else:
            self.save_file_as()

    def save_file_as(self):
        file_path, _ = QFileDialog.getSaveFileName(self, "Save File")
        if file_path:
            self.current_file_path = file_path
            self.save_file()

    def copy_text(self):
        cursor = self.text_edit.textCursor()
        selected_text = cursor.selectedText()
        self.text_edit.copy()

    def cut_text(self):
        cursor = self.text_edit.textCursor()
        selected_text = cursor.selectedText()
        self.text_edit.cut()

    def paste_text(self):
        self.text_edit.paste()

    def select_font(self):
        current_font = self.text_edit.currentFont()
        font, ok = QFontDialog.getFont(current_font, self)
        if ok:
            self.text_edit.setCurrentFont(font)

    def select_color(self):
        current_color = self.text_edit.textColor()
        color = QColorDialog.getColor(current_color, self)
        if color.isValid():
            self.text_edit.setTextColor(color)

    def closeEvent(self, event):
        if self.text_edit.document().isModified():
            answer = QMessageBox.question(self, "Save Changes", "Do you want to save changes before exiting?",
                                          QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel)
            if answer == QMessageBox.Yes:
                self.save_file()
                event.accept()
            elif answer == QMessageBox.No:
                event.accept()
            else:
                event.ignore()
        else:
            event.accept()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    code_editor = CodeEditorApp()
    code_editor.show()
    sys.exit(app.exec())
