import sys
import csv
import sqlite3
import pymysql
import psycopg2
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QTextEdit, QPushButton, QMessageBox, QLineEdit, QHBoxLayout, QTableWidget, QTableWidgetItem, QMenu, QFileDialog, QInputDialog, QComboBox, QSplitter
from PySide6.QtGui import QAction, QKeySequence

class SQLClient(QMainWindow):
    def __init__(self):
        super().__init__()
        self.connection = None
        self.cursor = None
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("SQL Client")
        self.setGeometry(100, 100, 800, 600)

        central_widget = QSplitter(self)
        self.setCentralWidget(central_widget)

        # 上部分布局
        top_widget = QWidget()
        top_layout = QVBoxLayout(top_widget)

        # 输入区域布局
        input_layout = QHBoxLayout()
        top_layout.addLayout(input_layout)

        self.query_text = QTextEdit()
        input_layout.addWidget(self.query_text)

        execute_button = QPushButton("Execute")
        execute_button.clicked.connect(self.execute_query)
        input_layout.addWidget(execute_button)

        # 设置上部分为可伸缩部件
        top_widget.setLayout(top_layout)
        central_widget.addWidget(top_widget)

        # 下部分布局
        bottom_widget = QWidget()
        bottom_layout = QVBoxLayout(bottom_widget)


        # 结果区域布局
        self.result_table = QTableWidget()
        self.result_table.setEditTriggers(QTableWidget.DoubleClicked)
        self.result_table.setSelectionBehavior(QTableWidget.SelectRows)
        bottom_layout.addWidget(self.result_table)

        # 连接区域布局
        connection_layout = QHBoxLayout()
        bottom_layout.addLayout(connection_layout)


        splitter_handle = QSplitter(Qt.Vertical)
        splitter_handle.addWidget(top_widget)
        splitter_handle.addWidget(bottom_widget)
        central_widget.addWidget(splitter_handle)


        self.db_type_input = QComboBox()
        self.db_type_input.addItems(["mysql", "sqlite", "pgsql"])
        self.db_type_input.setPlaceholderText("Database Type")
        connection_layout.addWidget(self.db_type_input)


        self.db_host_input = QLineEdit()
        self.db_host_input.setPlaceholderText("Host")
        connection_layout.addWidget(self.db_host_input)

        self.db_user_input = QLineEdit()
        self.db_user_input.setPlaceholderText("Username")
        connection_layout.addWidget(self.db_user_input)

        self.db_password_input = QLineEdit()
        self.db_password_input.setEchoMode(QLineEdit.Password)
        self.db_password_input.setPlaceholderText("Password")
        connection_layout.addWidget(self.db_password_input)

        self.db_name_input = QLineEdit()
        self.db_name_input.setPlaceholderText("Database Name")
        connection_layout.addWidget(self.db_name_input)

        self.connect_button = QPushButton("Connect")
        self.connect_button.clicked.connect(self.connect_to_database)
        connection_layout.addWidget(self.connect_button)

        self.statusBar()

        self.create_menu()

    def create_menu(self):
        # 创建菜单栏
        menu_bar = self.menuBar()

        # 创建文件菜单
        file_menu = menu_bar.addMenu("File")

        # 创建退出子菜单
        exit_action = QAction("Exit", self)
        file_menu.addAction(exit_action)

        # 连接退出子菜单的信号槽
        exit_action.triggered.connect(self.close)

        # 创建插入菜单
        insert_menu = menu_bar.addMenu("Insert")

        # 创建插入子菜单项
        insert_action = QAction("INSERT INTO", self)
        insert_menu.addAction(insert_action)
        delete_action = QAction("DELETE FROM", self)
        insert_menu.addAction(delete_action)
        update_action = QAction("UPDATE", self)
        insert_menu.addAction(update_action)
        select_action = QAction("SELECT", self)
        insert_menu.addAction(select_action)
        create_action = QAction("CREATE DATABASE", self)
        insert_menu.addAction(create_action)
        show_action = QAction("SHOW TABLES", self)
        insert_menu.addAction(show_action)

        # 连接插入子菜单项的信号槽
        insert_action.triggered.connect(lambda: self.insert_sql("INSERT INTO"))
        delete_action.triggered.connect(lambda: self.insert_sql("DELETE FROM"))
        update_action.triggered.connect(lambda: self.insert_sql("UPDATE"))
        select_action.triggered.connect(lambda: self.insert_sql("SELECT"))
        create_action.triggered.connect(lambda: self.insert_sql("CREATE DATABASE"))
        show_action.triggered.connect(lambda: self.insert_sql("SHOW TABLES"))

        # 创建执行菜单
        execute_menu = menu_bar.addMenu("执行")

        # 创建执行动作
        execute_action = QAction("执行", self)
        execute_action.triggered.connect(self.execute_query)
        execute_action.setShortcut(QKeySequence(Qt.Key_F5))
        # 将执行动作添加到执行菜单中
        execute_menu.addAction(execute_action)

    def insert_sql(self, sql_type):
        if sql_type:
            # 根据SQL语句类型生成相应的语句
            if sql_type == "INSERT INTO":
                sql = "INSERT INTO table_name (column1, column2) VALUES (?, ?)"
            elif sql_type == "DELETE FROM":
                sql = "DELETE FROM table_name WHERE condition"
            elif sql_type == "UPDATE":
                sql = "UPDATE table_name SET column1 = value1 WHERE condition"
            elif sql_type == "SELECT":
                sql = "SELECT * FROM table_name WHERE condition"
            elif sql_type == "CREATE DATABASE":
                sql = "CREATE DATABASE database_name"
            elif sql_type == "SHOW TABLES":
                if isinstance(self.connection, sqlite3.Connection):
                    sql = "SELECT name FROM sqlite_master WHERE type='table'"
                else:
                    sql = "SHOW TABLES"
    
            # 将语句插入到输入框中
            cursor = self.query_text.textCursor()
            cursor.insertText(sql)


    def connect_to_database(self):
        db_type = self.db_type_input.currentText()
        db_host = self.db_host_input.text()
        db_user = self.db_user_input.text()
        db_password = self.db_password_input.text()
        db_name = self.db_name_input.text()

        try:
            if db_type.lower() == "mysql":
                self.connection = pymysql.connect(host=db_host, user=db_user, password=db_password, db=db_name)
                self.cursor = self.connection.cursor()
            elif db_type.lower() == "sqlite":
                self.connection = sqlite3.connect(db_name)
                self.cursor = self.connection.cursor()
            elif db_type.lower() == "pgsql":
                self.connection = psycopg2.connect(host=db_host, user=db_user, password=db_password, dbname=db_name)
                self.cursor = self.connection.cursor()
            else:
                raise ValueError("Invalid database type")

            self.statusBar().showMessage("Connected to database" + " " + db_name)
        except (sqlite3.Error, pymysql.Error, psycopg2.Error) as e:
            QMessageBox.critical(self, "Error", str(e))
            self.statusBar().showMessage("Connection failed")

    def execute_query(self):
        if not self.connection:
            QMessageBox.warning(self, "Warning", "Not connected to a database")
            return

        # 获取当前光标对象
        cursor = self.query_text.textCursor()

        # 判断是否有选中内容
        if cursor.hasSelection():
            # 获取选中的文本
            selected_text = cursor.selectedText()
            query = selected_text
        else:
            # 获取整个输入框的文本
            query = self.query_text.toPlainText()

        try:
            self.cursor.execute(query)

            # 获取查询结果
            result = self.cursor.fetchall()

            # 设置表格行列数
            num_rows = len(result)
            num_columns = len(self.cursor.description)
            self.result_table.setRowCount(num_rows)
            self.result_table.setColumnCount(num_columns)

            # 设置表头
            header = [field[0] for field in self.cursor.description]
            self.result_table.setHorizontalHeaderLabels(header)

            # 填充结果到表格
            for row_idx, row_data in enumerate(result):
                for col_idx, col_data in enumerate(row_data):
                    item = QTableWidgetItem(str(col_data))
                    item.setTextAlignment(Qt.AlignLeft | Qt.AlignVCenter)
                    self.result_table.setItem(row_idx, col_idx, item)

            self.result_table.setContextMenuPolicy(Qt.CustomContextMenu)
            self.result_table.customContextMenuRequested.connect(self.show_context_menu)

            self.statusBar().showMessage("Query executed successfully")
        except (sqlite3.Error, pymysql.Error, psycopg2.Error) as e:
            QMessageBox.critical(self, "Error", str(e))
            self.statusBar().showMessage("Query execution failed")

    def show_context_menu(self, pos):
        if self.result_table.selectionModel().hasSelection():
            menu = QMenu(self)
            update_action = QAction("Update to Database", self)
            update_action.triggered.connect(self.update_to_database)
            menu.addAction(update_action)

            # 导出为CSV菜单项
            export_csv_action = QAction("Export as CSV", self)
            export_csv_action.triggered.connect(self.export_as_csv)
            menu.addAction(export_csv_action)

            menu.exec(self.result_table.viewport().mapToGlobal(pos))

    def get_target_table_name(self):
        table_name, ok = QInputDialog.getText(self, "Target Table", "Enter the target table name:")
        if ok:
            return table_name
        else:
            return None

    def update_to_database(self):
        if not self.connection:
            QMessageBox.warning(self, "Warning", "Not connected to a database")
            return

        table_name = self.get_target_table_name()
        if not table_name:
            return

        try:
            self.cursor.execute(f"DELETE FROM {table_name}")

            for row in range(self.result_table.rowCount()):
                values = []
                for col in range(self.result_table.columnCount()):
                    item = self.result_table.item(row, col)
                    value = item.text()
                    values.append(value)
                placeholders = ", ".join(["%s"] * len(values))
                query = f"INSERT INTO {table_name} VALUES ({placeholders})"
                self.cursor.execute(query, values)

            self.connection.commit()
            self.statusBar().showMessage("Updated to database successfully")
        except (sqlite3.Error, pymysql.Error, psycopg2.Error) as e:
            QMessageBox.critical(self, "Error", str(e))
            self.statusBar().showMessage("Update to database failed")


    def export_as_csv(self):
        file_dialog = QFileDialog()
        file_path, _ = file_dialog.getSaveFileName(self, "Export as CSV", "", "CSV Files (*.csv)")

        if file_path:
            try:
                with open(file_path, "w", newline="") as file:
                    writer = csv.writer(file)
                    header_data = [self.result_table.horizontalHeaderItem(col).text() for col in
                                   range(self.result_table.columnCount())]
                    writer.writerow(header_data)
                    for row in range(self.result_table.rowCount()):
                        row_data = [self.result_table.item(row, col).text() for col in
                                    range(self.result_table.columnCount())]
                        writer.writerow(row_data)
                self.statusBar().showMessage("Exported as CSV successfully")
            except IOError as e:
                QMessageBox.critical(self, "Error", str(e))
                self.statusBar().showMessage("Export as CSV failed")


    def closeEvent(self, event):
        if self.connection:
            self.connection.close()

        event.accept()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    sql_client = SQLClient()
    sql_client.show()
    sys.exit(app.exec())
