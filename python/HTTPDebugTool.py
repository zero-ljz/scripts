import sys
import asyncio
import json
import aiohttp
from PySide6.QtCore import Qt, Slot
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QTextEdit, \
    QPushButton, QComboBox, QMessageBox


class HTTPDebugTool(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("HTTP Debug Tool")
        self.setGeometry(100, 100, 800, 600)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QVBoxLayout(central_widget)

        request_widget = QWidget()
        request_layout = QVBoxLayout(request_widget)

        url_layout = QHBoxLayout()
        url_label = QLabel("URL:")
        self.url_text = QTextEdit()
        self.url_text.setFixedHeight(30)
        url_layout.addWidget(url_label)
        url_layout.addWidget(self.url_text)

        method_layout = QHBoxLayout()
        method_label = QLabel("Method:")
        self.method_combo = QComboBox()
        self.method_combo.addItems(["GET", "POST", "PUT", "DELETE"])
        method_layout.addWidget(method_label)
        method_layout.addWidget(self.method_combo)

        request_headers_label = QLabel("Request Headers:")
        self.request_headers_text = QTextEdit()

        request_body_label = QLabel("Request Body:")
        self.request_body_text = QTextEdit()

        send_button = QPushButton("Send")
        send_button.clicked.connect(self.send_request)

        request_layout.addLayout(url_layout)
        request_layout.addLayout(method_layout)
        request_layout.addWidget(request_headers_label)
        request_layout.addWidget(self.request_headers_text)
        request_layout.addWidget(request_body_label)
        request_layout.addWidget(self.request_body_text)
        request_layout.addWidget(send_button)

        response_widget = QWidget()
        response_layout = QVBoxLayout(response_widget)

        response_headers_label = QLabel("Response Headers:")
        self.response_headers_text = QTextEdit()
        self.response_headers_text.setReadOnly(True)
        response_layout.addWidget(response_headers_label)
        response_layout.addWidget(self.response_headers_text)

        response_body_label = QLabel("Response Body:")
        self.response_body_text = QTextEdit()
        self.response_body_text.setReadOnly(True)
        response_layout.addWidget(response_body_label)
        response_layout.addWidget(self.response_body_text)

        main_layout.addWidget(request_widget)
        main_layout.addWidget(response_widget)

    @Slot()
    def send_request(self):
        url = self.url_text.toPlainText()
        method = self.method_combo.currentText()
        headers = self.parse_request_headers()
        body = self.request_body_text.toPlainText()

        asyncio.run(self.make_request(url, method, headers, body))

    def parse_request_headers(self):
        headers_text = self.request_headers_text.toPlainText().strip()
        headers = {}
        if headers_text:
            lines = headers_text.splitlines()
            for line in lines:
                key, value = line.split(':', 1)
                headers[key.strip()] = value.strip()
        return headers

    async def make_request(self, url, method, headers, body):
        try:
            async with aiohttp.ClientSession() as session:
                async with session.request(method, url, headers=headers, data=body) as response:
                    response_text = await response.text()
                    self.response_body_text.setPlainText(response_text)

                    response_headers = response.headers
                    headers_text = ""
                    for header, value in response_headers.items():
                        headers_text += f"{header}: {value}\n"
                    self.response_headers_text.setPlainText(headers_text)

                    content_type = response.headers.get('Content-Type', '')
                    if 'application/json' in content_type:
                        try:
                            json_data = json.loads(response_text)
                            formatted_json = json.dumps(json_data, indent=4)
                            self.response_body_text.setPlainText(formatted_json)
                        except ValueError:
                            pass

        except aiohttp.ClientError as e:
            QMessageBox.warning(self, "Error", str(e))


if __name__ == '__main__':
    app = QApplication(sys.argv)
    http_debug_tool = HTTPDebugTool()
    http_debug_tool.show()
    sys.exit(app.exec())
