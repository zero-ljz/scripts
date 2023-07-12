import sys
import asyncio
import json
import aiohttp
from PySide6.QtCore import Qt, Slot
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QTextEdit, \
    QPushButton, QComboBox, QMessageBox, QTabWidget, QFileDialog, QSplitter, QStatusBar, QCheckBox
from PySide6.QtGui import QAction


class HTTPClient(QMainWindow):
    def __init__(self):
        super().__init__()
        self.tab_widget = QTabWidget()
        self.tab_count = 0
        self.tab_widget.setTabsClosable(True)
        self.tab_widget.tabCloseRequested.connect(self.close_tab)
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("HTTP Client")
        self.setGeometry(100, 100, 800, 600)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QVBoxLayout(central_widget)

        button_layout = QHBoxLayout()
        new_tab_button = QPushButton("New Tab")
        new_tab_button.clicked.connect(self.create_new_tab)
        button_layout.addWidget(new_tab_button)
        main_layout.addLayout(button_layout)
        main_layout.addWidget(self.tab_widget)

        self.create_new_tab()

        self.create_menu_bar()

        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)

    def create_menu_bar(self):
        menu_bar = self.menuBar()
        file_menu = menu_bar.addMenu("File")

        new_tab_action = QAction("New Tab", self)
        new_tab_action.triggered.connect(self.create_new_tab)
        file_menu.addAction(new_tab_action)

        close_tab_action = QAction("Close Tab", self)
        close_tab_action.triggered.connect(self.close_current_tab)
        file_menu.addAction(close_tab_action)

        save_data_action = QAction("Save Data", self, triggered=self.save_data)
        file_menu.addAction(save_data_action)

        load_data_action = QAction("Load Data", self, triggered=self.load_data)
        file_menu.addAction(load_data_action)

    def save_data(self):
        file_dialog = QFileDialog()
        file_path, _ = file_dialog.getSaveFileName(self, "Save Data", "", "JSON Files (*.json)")

        if file_path:
            data = []
            for i in range(self.tab_widget.count()):
                tab = self.tab_widget.widget(i)
                request_widget = tab.findChild(QWidget, "request_widget")
                response_widget = tab.findChild(QWidget, "response_widget")

                url = tab.findChild(QWidget, "url_text").toPlainText()
                method = tab.findChild(QWidget, "method_combo").currentText()
                headers = tab.findChild(QWidget, "request_headers_text").toPlainText()
                
                body = tab.findChild(QWidget, "request_body_text").toPlainText()

                response_headers = tab.findChild(QWidget, "response_headers_text").toPlainText()
                response_body = tab.findChild(QWidget, "response_body_text").toPlainText()

                data.append({
                    "url": url,
                    "method": method,
                    "headers": headers,
                    "body": body,
                    "response_headers": response_headers,
                    "response_body": response_body
                })

            with open(file_path, "w") as file:
                json.dump(data, file, indent=4)

    def load_data(self):
        file_dialog = QFileDialog()
        file_path, _ = file_dialog.getOpenFileName(self, "Load Data", "", "JSON Files (*.json)")

        if file_path:
            with open(file_path, "r") as file:
                data = json.load(file)

            for item in data:
                self.create_new_tab()
                tab = self.tab_widget.widget(self.tab_widget.count() - 1)
                request_widget = tab.findChild(QWidget, "request_widget")
                response_widget = tab.findChild(QWidget, "response_widget")

                tab.findChild(QWidget, "url_text").setPlainText(item["url"])
                tab.findChild(QWidget, "method_combo").setCurrentText(item["method"])
                tab.findChild(QWidget, "request_headers_text").setPlainText(item["headers"])
                tab.findChild(QWidget, "request_body_text").setPlainText(item["body"])

                tab.findChild(QWidget, "response_headers_text").setPlainText(item["response_headers"])
                tab.findChild(QWidget, "response_body_text").setPlainText(item["response_body"])

    def create_new_tab(self):
        self.tab_count += 1
        tab_widget = QWidget()
        tab_layout = QVBoxLayout(tab_widget)
    
        splitter = QSplitter(Qt.Horizontal)
        tab_layout.addWidget(splitter)
    
        request_widget = QWidget()
        request_widget.setObjectName("request_widget")  # 添加对象名称
        request_layout = QVBoxLayout(request_widget)
    
        url_layout = QHBoxLayout()
        url_label = QLabel("URL:")
        url_text = QTextEdit("https://httpbin.org/get")
        url_text.setObjectName("url_text")  # 添加对象名称
        url_text.setFixedHeight(30)
        url_layout.addWidget(url_label)
        url_layout.addWidget(url_text)
    
        method_layout = QHBoxLayout()
        method_label = QLabel("Method:")
        method_combo = QComboBox()
        method_combo.addItems(["GET", "POST", "PUT", "DELETE"])
        method_combo.setObjectName("method_combo")  # 添加对象名称
        method_layout.addWidget(method_label)
        method_layout.addWidget(method_combo)
    
        request_headers_label = QLabel("Request Headers:")
        request_headers_text = QTextEdit("User-Agent: curl/7.85.0<br/>Content-Type: application/json")
        request_headers_text.setObjectName("request_headers_text")  # 添加对象名称
    
        request_body_label = QLabel("Request Body:")
        request_body_text = QTextEdit()
        request_body_text.setObjectName("request_body_text")  # 添加对象名称
    
        send_button = QPushButton("Send")
        send_button.clicked.connect(self.send_request)

        follow_redirect_checkbox = QCheckBox("Follow Redirects")
        follow_redirect_checkbox.setObjectName("follow_redirect_checkbox")  # 添加对象名称
        follow_redirect_checkbox.setChecked(True)  # 默认勾选
    
        request_layout.addLayout(url_layout)
        request_layout.addLayout(method_layout)
        request_layout.addWidget(request_headers_label)
        request_layout.addWidget(request_headers_text)
        request_layout.addWidget(request_body_label)
        request_layout.addWidget(request_body_text)
        request_layout.addWidget(send_button)
        request_layout.addWidget(follow_redirect_checkbox)
    
        response_widget = QWidget()
        response_widget.setObjectName("response_widget")  # 添加对象名称
        response_layout = QVBoxLayout(response_widget)
    
        response_headers_label = QLabel("Response Headers:")
        response_headers_text = QTextEdit()
        response_headers_text.setObjectName("response_headers_text")  # 添加对象名称
        response_headers_text.setReadOnly(True)
        response_layout.addWidget(response_headers_label)
        response_layout.addWidget(response_headers_text)
    
        response_body_label = QLabel("Response Body:")
        response_body_text = QTextEdit()
        response_body_text.setObjectName("response_body_text")  # 添加对象名称
        response_body_text.setReadOnly(True)
        response_layout.addWidget(response_body_label)
        response_layout.addWidget(response_body_text)
    
        splitter.addWidget(request_widget)
        splitter.addWidget(response_widget)
    
        self.tab_widget.addTab(tab_widget, f"Tab {self.tab_count}")
        self.tab_widget.setCurrentIndex(self.tab_widget.count() - 1)

    @Slot()
    def send_request(self):
        current_tab_index = self.tab_widget.currentIndex()
        current_tab = self.tab_widget.widget(current_tab_index)
        request_widget = current_tab.findChild(QWidget, "request_widget")

        url_text = request_widget.findChild(QTextEdit, "url_text")
        request_headers_text = request_widget.findChild(QTextEdit, "request_headers_text")
        request_body_text = request_widget.findChild(QTextEdit, "request_body_text")

        url = url_text.toPlainText()
        method_combo = self.findChild(QComboBox, "method_combo")
        method = method_combo.currentText()
        headers = self.parse_headers(request_headers_text)
        body = request_body_text.toPlainText()

        asyncio.run(self.make_request(url, method, headers, body))


    def parse_headers(self, headers_text):
        headers_text = headers_text.toPlainText().strip()
        headers = {}
        if headers_text:
            lines = headers_text.splitlines()
            for line in lines:
                key, value = line.split(':', 1)
                headers[key.strip()] = value.strip()
        return headers

    async def make_request(self, url, method, headers, body):
        current_tab_index = self.tab_widget.currentIndex()
        current_tab = self.tab_widget.widget(current_tab_index)
        allow_redirects = current_tab.findChild(QWidget, "follow_redirect_checkbox").isChecked()

        try:
            async with aiohttp.ClientSession() as session:
                async with session.request(method, url, headers=headers, data=body, allow_redirects=allow_redirects) as response:
                    response_text = await response.text()

                    response_widget = current_tab.findChild(QWidget, "response_widget")

                    response_headers_text = current_tab.findChild(QWidget, "response_headers_text")
                    response_body_text = current_tab.findChild(QWidget, "response_body_text")

                    response_body_text.setPlainText(response_text)

                    response_headers = response.headers
                    headers_text = ""
                    for header, value in response_headers.items():
                        headers_text += f"{header}: {value}\n"
                    response_headers_text.setPlainText(headers_text)

                    content_type = response.headers.get('Content-Type', '')
                    if 'application/json' in content_type:
                        try:
                            json_data = json.loads(response_text)
                            formatted_json = json.dumps(json_data, indent=4)
                            response_body_text.setPlainText(formatted_json)
                        except ValueError:
                            pass
                    # Update status bar message
                    status_message = f"{response.status} {response.reason}"
                    self.statusBar().showMessage(status_message)

        except aiohttp.ClientError as e:
            QMessageBox.warning(self, "Error", str(e))

    def close_tab(self, index):
        if self.tab_widget.count() > 1:
            self.tab_widget.removeTab(index)

    def close_current_tab(self):
        current_tab_index = self.tab_widget.currentIndex()
        self.close_tab(current_tab_index)

    def closeEvent(self, event):
        reply = QMessageBox.question(self, "Confirm Exit",
                                     "Are you sure you want to exit the application?",
                                     QMessageBox.Yes | QMessageBox.No)
        if reply == QMessageBox.Yes:
            event.accept()
        else:
            event.ignore()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    http_client = HTTPClient()
    http_client.show()
    sys.exit(app.exec())
