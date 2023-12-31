import sys
import csv
import re
import sqlite3
import pymysql
import psycopg2
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QTextEdit, QPushButton, QMessageBox, QLineEdit, QHBoxLayout, QTableWidget, QTableWidgetItem, QMenu, QFileDialog, QInputDialog, QComboBox, QSplitter, QPlainTextEdit
from PySide6.QtGui import QAction, QKeySequence, QPainter, QSyntaxHighlighter, QTextCharFormat, QBrush, QColor, QFont


class SQLTextEdit(QTextEdit):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.highlighter = SQLSyntaxHighlighter(self.document())

    def paintEvent(self, event):
        # 绘制文本框背景
        super().paintEvent(event)


class SQLSyntaxHighlighter(QSyntaxHighlighter):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.highlighting_rules = []

        keyword_format = QTextCharFormat()
        keyword_format.setForeground(Qt.darkBlue)
        keyword_format.setFontWeight(QFont.Bold)
        keywords = [
            "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES",
            "UPDATE", "SET", "DELETE", "CREATE", "TABLE", "DROP",
            "DATABASE", "ALTER", "ADD", "PRIMARY", "KEY", "FOREIGN",
            "REFERENCES", "INDEX", "IF", "NOT", "NULL", "AND", "OR",
            "AS", "LIKE", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER",
            "ASC", "DESC", "GROUP", "BY", "HAVING", "ORDER", "LIMIT",
            "OFFSET", "UNION", "ALL", "DISTINCT", "CASE", "WHEN",
            "THEN", "ELSE", "END"
        ]
        for keyword in keywords:
            pattern = r"\b" + re.escape(keyword) + r"\b"
            rule = (re.compile(pattern, re.IGNORECASE), keyword_format)
            self.highlighting_rules.append(rule)

        quotation_format = QTextCharFormat()
        quotation_format.setForeground(Qt.darkGreen)
        self.highlighting_rules.append((re.compile(r"'[^']*'"), quotation_format))
        self.highlighting_rules.append((re.compile(r'"[^"]*"'), quotation_format))

        comment_format = QTextCharFormat()
        comment_format.setForeground(Qt.darkGray)
        self.highlighting_rules.append((re.compile(r"--[^\n]*"), comment_format))

    def highlightBlock(self, text):
        for rule in self.highlighting_rules:
            expression, char_format = rule
    
            matches = expression.finditer(text)
            for match in matches:
                start, end = match.span()
                self.setFormat(start, end - start, char_format)


class SQLClient(QMainWindow):
    def __init__(self):
        super().__init__()
        self.connection = None
        self.cursor = None
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("SQL Client")
        self.setGeometry(100, 100, 800, 600)

        # 在主窗口中创建拆分器部件并设为中心部件
        central_widget = QSplitter(self)
        self.setCentralWidget(central_widget)

        # 上部分布局
        # 在新建的空部件中创建垂直布局
        top_widget = QWidget()
        top_layout = QVBoxLayout(top_widget)

        # 输入区域布局
        # 在垂直布局中创建水平布局
        input_layout = QHBoxLayout()
        top_layout.addLayout(input_layout)

        # 创建 SQL 输入框
        self.query_text = SQLTextEdit(self)
        input_layout.addWidget(self.query_text)

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
        self.db_type_input.addItems(["sqlite", "mysql", "pgsql"])
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

        # self.db_type_input.setCurrentText('mysql')
        # self.db_host_input.setText('127.0.0.1:3306')
        # self.db_user_input.setText('root')
        # self.db_password_input.setText('')
        # self.db_name_input.setText('')

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
        show_tables_action = QAction("SHOW TABLES", self)
        insert_menu.addAction(show_tables_action)
        show_dbs_action = QAction("SHOW DATABASES", self)
        insert_menu.addAction(show_dbs_action)
        create_table_action = QAction("CREATE TABLE", self)
        insert_menu.addAction(create_table_action)

        # 连接插入子菜单项的信号槽
        insert_action.triggered.connect(lambda: self.insert_sql("INSERT INTO"))
        delete_action.triggered.connect(lambda: self.insert_sql("DELETE FROM"))
        update_action.triggered.connect(lambda: self.insert_sql("UPDATE"))
        select_action.triggered.connect(lambda: self.insert_sql("SELECT"))
        create_action.triggered.connect(lambda: self.insert_sql("CREATE DATABASE"))
        show_tables_action.triggered.connect(lambda: self.insert_sql("SHOW TABLES"))
        show_dbs_action.triggered.connect(lambda: self.insert_sql("SHOW DATABASES"))
        create_table_action.triggered.connect(lambda: self.insert_sql("CREATE TABLE"))

        # 创建执行动作
        execute_action = QAction("Execute (F5)", self)
        execute_action.triggered.connect(self.execute_query)
        execute_action.setShortcut(QKeySequence(Qt.Key_F5))
        # 将执行动作添加到菜单栏
        menu_bar.addAction(execute_action)

    def insert_sql(self, sql_type):
        if sql_type:
            # 根据SQL语句类型生成相应的语句
            if sql_type == "INSERT INTO":
                sql = "INSERT INTO table_name (column1, column2) VALUES (?, ?)"
            elif sql_type == "DELETE FROM":
                sql = "DELETE FROM table_name WHERE 1=1"
            elif sql_type == "UPDATE":
                sql = "UPDATE table_name SET column1 = value1 WHERE 1=1"
            elif sql_type == "SELECT":
                if isinstance(self.connection, psycopg2.extensions.connection):
                    sql = "SELECT * FROM table_name WHERE 1=1 FETCH FIRST 1000 ROWS ONLY"
                else:
                    sql = "SELECT * FROM table_name WHERE 1=1 LIMIT 1000"
            elif sql_type == "CREATE DATABASE":
                sql = "CREATE DATABASE database_name"
            elif sql_type == "SHOW TABLES":
                if isinstance(self.connection, sqlite3.Connection):
                    sql = "SELECT name FROM sqlite_master WHERE type='table'"
                else:
                    sql = "SHOW TABLES"
            elif sql_type == "SHOW DATABASES":
                if isinstance(self.connection, sqlite3.Connection):
                    sql = "SELECT name FROM sqlite_master WHERE type='database'"
                elif isinstance(self.connection, psycopg2.extensions.connection):
                    sql = "SELECT datname FROM pg_database WHERE datistemplate = false"
                else:
                    sql = "SHOW DATABASES"
            elif sql_type == "CREATE TABLE":
                sql = """\
CREATE TABLE IF NOT EXISTS table_name (
    id INT PRIMARY KEY AUTO_INCREMENT,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    is_deleted BOOLEAN,
    name VARCHAR(255),
    username VARCHAR(255) NOT NULL UNIQUE,
    age INT,
    hire_date DATE,
    price DECIMAL(10, 2),
    content TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\
"""
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
                host_parts = db_host.split(':')
                host = host_parts[0]
                port = int(host_parts[1]) if len(host_parts) > 1 else 3306
                self.connection = pymysql.connect(host=host, port=port, user=db_user, password=db_password, db=db_name)
                self.cursor = self.connection.cursor()
            elif db_type.lower() == "sqlite":
                self.connection = sqlite3.connect(db_name)
                self.cursor = self.connection.cursor()
            elif db_type.lower() == "pgsql":
                host_parts = db_host.split(':')
                host = host_parts[0]
                port = int(host_parts[1]) if len(host_parts) > 1 else 5432
                self.connection = psycopg2.connect(host=host, port=port, user=db_user, password=db_password, dbname=db_name)
                self.cursor = self.connection.cursor()
            else:
                raise ValueError("Invalid database type")
            
            # 更新窗口标题
            title = f"SQLClient - {db_host}/{db_name}"
            self.setWindowTitle(title)

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
            # 使用分号分割多个 SQL 语句
            sql_statements = query.split(";")

            # 执行每个 SQL 语句
            for statement in sql_statements:
                # 忽略空语句
                if not statement.strip():
                    continue

                # 执行
                self.cursor.execute(statement)

            # 提交事务
            self.connection.commit()

            # 获取查询结果
            result = self.cursor.fetchall()

            self.result_table.clearContents()  # 清除表格中的所有单元格数据

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
                    if col_data:
                        col_data = str(col_data)
                        item = QTableWidgetItem(col_data)
                        item.setTextAlignment(Qt.AlignLeft | Qt.AlignVCenter)
                        # item.setBackground(Qt.gray)
                        item.setBackground(QBrush(QColor(200, 200, 200)))
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
        if ok and table_name:
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
            # 获取表的主键字段名
            primary_key_column = self.get_primary_key_column(table_name)
            if not primary_key_column:
                QMessageBox.warning(self, "Warning", "Table doesn't have a primary key column")
                return

            selected_rows = set(index.row() for index in self.result_table.selectionModel().selectedRows())
            for row in selected_rows:
                update_pairs = []

                placeholder = "%s"
                if isinstance(self.connection, sqlite3.Connection):
                    placeholder = "?"  # SQLite使用?占位符

                values = []
                primary_key_value = None

                for col in range(self.result_table.columnCount()):
                    item = self.result_table.item(row, col)
                    if item:
                        value = item.text()
                        values.append(value)
                    else:
                        values.append(None)

                    # 构建更新语句的列名=占位符
                    column_name = self.result_table.horizontalHeaderItem(col).text()
                    update_pairs.append(f"{column_name} = {placeholder}")

                    # 获取主键列的值
                    if column_name == primary_key_column:
                        primary_key_value = value

                # 构建更新语句
                update_query = f"UPDATE {table_name} SET " + ", ".join(update_pairs) + f" WHERE {primary_key_column} = {placeholder}"
                print(update_query)
                # 执行更新语句
                self.cursor.execute(update_query, values + [primary_key_value])

            self.connection.commit()
            self.statusBar().showMessage("Updated to database successfully")
        except (sqlite3.Error, pymysql.Error, psycopg2.Error) as e:
            QMessageBox.critical(self, "Error", str(e))
            self.statusBar().showMessage("Update to database failed")

    def get_primary_key_column(self, table_name):
        # 根据数据库类型查询表的主键字段名
        if self.db_type_input.currentText().lower() == "mysql":
            query = f"SHOW KEYS FROM {table_name} WHERE Key_name = 'PRIMARY'"
            self.cursor.execute(query)
            primary_key_info = self.cursor.fetchone()
            if primary_key_info:
                return primary_key_info[4]
        elif self.db_type_input.currentText().lower() == "sqlite":
            query = f"PRAGMA table_info({table_name})"
            self.cursor.execute(query)
            columns = self.cursor.fetchall()
            for column in columns:
                if column[5] == 1:  # 判断是否为主键
                    return column[1]
        elif self.db_type_input.currentText().lower() == "pgsql":
            query = f"SELECT column_name FROM information_schema.key_column_usage WHERE table_name = '{table_name}' AND constraint_name LIKE '%_pkey'"
            self.cursor.execute(query)
            primary_key_info = self.cursor.fetchone()
            if primary_key_info:
                return primary_key_info[0]
        return None



    def export_as_csv(self):
        file_dialog = QFileDialog()
        file_path, _ = file_dialog.getSaveFileName(self, "Export as CSV", "", "CSV Files (*.csv)")

        if file_path:
            try:
                with open(file_path, "w", newline="", encoding="utf-8-sig") as file:
                    writer = csv.writer(file)
                    header_data = [self.result_table.horizontalHeaderItem(col).text()
                                   for col in range(self.result_table.columnCount())]
                    writer.writerow(header_data)
                    selected_rows = set(index.row() for index in self.result_table.selectionModel().selectedRows())
                    for row in selected_rows:
                        row_data = [self.result_table.item(row, col).text().encode("utf-8", "ignore").decode("utf-8")
                                    if self.result_table.item(row, col) is not None 
                                    else None 
                                    for col in range(self.result_table.columnCount())]
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

    if len(sys.argv) > 1:
        db_file = sys.argv[1]
        sql_client = SQLClient()
        sql_client.db_name_input.setText(db_file)
    else:
        sql_client = SQLClient()

    sql_client.show()
    sys.exit(app.exec())
