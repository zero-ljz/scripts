import sys
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLineEdit, QPushButton, \
    QListWidget, QTabWidget, QTextEdit, QStyleFactory, QFileDialog
from PySide6.QtGui import QAction
import subprocess

class CommandManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.commands = []
        self.tabs = {}

        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Command Manager")

        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        main_layout = QVBoxLayout(central_widget)

        input_widget = QWidget()
        input_layout = QHBoxLayout(input_widget)

        self.command_entry = QLineEdit()
        self.command_entry.setPlaceholderText("Enter command")
        self.command_entry.returnPressed.connect(self.add_command)  # 监听回车键事件
        input_layout.addWidget(self.command_entry)

        main_layout.addWidget(input_widget)

        self.command_listbox = QListWidget()
        self.command_listbox.itemDoubleClicked.connect(self.execute_selected_command)
        main_layout.addWidget(self.command_listbox)

        self.tab_control = QTabWidget()
        self.tab_control.setTabsClosable(True)  # 标签页支持关闭
        self.tab_control.tabCloseRequested.connect(self.close_tab)  # 监听关闭标签页事件
        main_layout.addWidget(self.tab_control)

        self.create_menu()

        self.setStyle(QStyleFactory.create("Fusion"))  # 设置主题为时尚风格

        self.show()

    def create_menu(self):
        # 创建菜单栏
        menu_bar = self.menuBar()
        file_menu = menu_bar.addMenu("File")

        # 添加保存命令到文件的动作
        save_action = QAction("Save Commands", self)
        save_action.triggered.connect(self.save_commands)
        file_menu.addAction(save_action)

        # 添加从文件加载命令的动作
        load_action = QAction("Load Commands", self)
        load_action.triggered.connect(self.load_commands)
        file_menu.addAction(load_action)

    def add_command(self):
        command = self.command_entry.text()
        if command:
            self.commands.append(command)
            self.command_listbox.addItem(command)
            self.command_entry.clear()

    def execute_selected_command(self, item):
        command = item.text()
        if command:
            self.execute_command(command)

    def execute_command(self, command):
        if command:
            try:
                result = subprocess.run(command, shell=True, capture_output=True, text=True)
                output = result.stdout
            except subprocess.CalledProcessError as e:
                output = e.output

            self.update_output_tab(command, output)

    def update_output_tab(self, command, output):
        if command in self.tabs:
            output_text = self.tabs[command]
            output_text.clear()
            output_text.setText(output)
        else:
            output_text = QTextEdit()
            output_text.setReadOnly(True)
            output_text.setText(output)

            self.tab_control.addTab(output_text, command)
            self.tab_control.setCurrentWidget(output_text)

            self.tabs[command] = output_text

    def close_tab(self, index):
        widget = self.tab_control.widget(index)
        if widget:
            command = self.tab_control.tabText(index)
            self.tab_control.removeTab(index)
            widget.deleteLater()
            del self.tabs[command]

    def save_commands(self):
        filename, _ = QFileDialog.getSaveFileName(self, "Save Commands", "", "Text Files (*.txt)")
        if filename:
            with open(filename, 'w') as file:
                file.write('\n'.join(self.commands))

    def load_commands(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Load Commands", "", "Text Files (*.txt)")
        if filename:
            with open(filename, 'r') as file:
                commands = file.read().splitlines()
                self.commands = commands
                self.command_listbox.clear()
                self.command_listbox.addItems(commands)

    def closeEvent(self, event):
        self.save_commands()
        event.accept()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    command_manager = CommandManager()
    sys.exit(app.exec())
