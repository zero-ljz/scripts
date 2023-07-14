import sys
import os
import multiprocessing
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLineEdit, QPushButton, \
    QListWidget, QTabWidget, QTextEdit, QStyleFactory, QFileDialog, QMessageBox
from PySide6.QtGui import QAction
import subprocess

class CommandManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.commands = []
        self.tabs = {}

        self.init_ui()
        self.load_commands_file()

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

        self.show()

    def create_menu(self):
        # 创建菜单栏
        menu_bar = self.menuBar()
        file_menu = menu_bar.addMenu("File")

        # 添加保存命令到文件的动作
        save_action = QAction("Save Commands", self)
        save_action.triggered.connect(self.save_commands)
        file_menu.addAction(save_action)

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
                process = subprocess.Popen(["start", "cmd", "/k", command], shell=True, text=True)
                # process = subprocess.Popen(["start", "powershell", "-NoExit", "-Command", command], shell=True)

            except Exception as e:
                QMessageBox.critical(self, "Error", str(e))
                
            self.update_output_tab(command, "ProcessID: " + str(process.pid))


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
        filename = os.path.splitext(__file__)[0] + '.txt'
        with open(filename, 'w') as file:
            file.write('\n'.join(self.commands))

    def load_commands_file(self):
        filename = os.path.splitext(__file__)[0] + '.txt'
        if not os.path.isfile(filename):
            # 如果文件不存在，则创建一个空的txt文件
            with open(filename, 'w'):
                pass

        with open(filename, 'r') as file:
            commands = file.read().splitlines()
            self.commands = commands
            self.command_listbox.clear()
            self.command_listbox.addItems(commands)

    def closeEvent(self, event):
        reply = QMessageBox.question(
            self, "Save Commands", "Do you want to save the commands?",
            QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel
        )

        if reply == QMessageBox.Save:
            self.save_commands()
        elif reply == QMessageBox.Cancel:
            event.ignore()

        event.accept()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    command_manager = CommandManager()
    sys.exit(app.exec())
