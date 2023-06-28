import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QScrollArea, QPushButton, QHBoxLayout, QGroupBox, \
    QGridLayout, QCheckBox, QRadioButton, QLineEdit, QTextEdit, QComboBox, QSlider, QProgressBar, QSpinBox, QDial, \
    QDateTimeEdit, QCalendarWidget, QTabWidget, QToolBox, QLCDNumber, QFontComboBox, QInputDialog, QColorDialog, \
    QFileDialog, QSizePolicy

class WidgetGallery(QWidget):
    def __init__(self):
        super(WidgetGallery, self).__init__()
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Widget Gallery')
        self.layout = QVBoxLayout()
        self.scrollArea = QScrollArea()
        self.scrollArea.setWidgetResizable(True)
        self.scrollAreaWidgetContents = QWidget()
        self.gridLayout = QGridLayout(self.scrollAreaWidgetContents)

        # Add widgets to the gallery
        self.addWidget(QLabel('Label'))
        self.addWidget(QPushButton('Button'))
        self.addWidget(QCheckBox('Checkbox'))
        self.addWidget(QRadioButton('Radio button'))
        self.addWidget(QLineEdit('Line edit'))
        self.addWidget(QTextEdit('Text edit'))
        self.addComboBox()
        self.addSlider()
        self.addProgressBar()
        self.addSpinBox()
        self.addDial()
        self.addDateTimeEdit()
        self.addCalendarWidget()
        self.addTabWidget()
        self.addToolBox()
        self.addLCDNumber()
        self.addFontComboBox()
        self.addInputDialog()
        self.addColorDialog()
        self.addFileDialog()
        self.addSizePolicy()

        self.scrollArea.setWidget(self.scrollAreaWidgetContents)
        self.layout.addWidget(self.scrollArea)
        self.setLayout(self.layout)
        self.show()

    def addWidget(self, widget):
        row = self.gridLayout.rowCount()
        self.gridLayout.addWidget(widget, row, 0)

    def addComboBox(self):
        comboBox = QComboBox()
        comboBox.addItem('Option 1')
        comboBox.addItem('Option 2')
        comboBox.addItem('Option 3')
        self.addWidget(comboBox)

    def addSlider(self):
        slider = QSlider()
        slider.setOrientation(1)
        self.addWidget(slider)

    def addProgressBar(self):
        progressBar = QProgressBar()
        progressBar.setValue(50)
        self.addWidget(progressBar)

    def addSpinBox(self):
        spinBox = QSpinBox()
        self.addWidget(spinBox)

    def addDial(self):
        dial = QDial()
        self.addWidget(dial)

    def addDateTimeEdit(self):
        dateTimeEdit = QDateTimeEdit()
        self.addWidget(dateTimeEdit)

    def addCalendarWidget(self):
        calendarWidget = QCalendarWidget()
        self.addWidget(calendarWidget)

    def addTabWidget(self):
        tabWidget = QTabWidget()
        tab1 = QWidget()
        tab2 = QWidget()
        tabWidget.addTab(tab1, 'Tab 1')
        tabWidget.addTab(tab2, 'Tab 2')
        self.addWidget(tabWidget)

    def addToolBox(self):
        toolBox = QToolBox()
        page1 = QWidget()
        page2 = QWidget()
        toolBox.addItem(page1, 'Page 1')
        toolBox.addItem(page2, 'Page 2')
        self.addWidget(toolBox)

    def addLCDNumber(self):
        lcdNumber = QLCDNumber()
        lcdNumber.display(1234)
        self.addWidget(lcdNumber)

    def addFontComboBox(self):
        fontComboBox = QFontComboBox()
        self.addWidget(fontComboBox)

    def addInputDialog(self):
        button = QPushButton('Open Input Dialog')
        button.clicked.connect(self.showInputDialog)
        self.addWidget(button)

    def showInputDialog(self):
        text, ok = QInputDialog.getText(self, 'Input Dialog', 'Enter your name:')
        if ok:
            print('Entered name:', text)

    def addColorDialog(self):
        button = QPushButton('Open Color Dialog')
        button.clicked.connect(self.showColorDialog)
        self.addWidget(button)

    def showColorDialog(self):
        color = QColorDialog.getColor()
        if color.isValid():
            print('Selected color:', color.name())

    def addFileDialog(self):
        button = QPushButton('Open File Dialog')
        button.clicked.connect(self.showFileDialog)
        self.addWidget(button)

    def showFileDialog(self):
        fileDialog = QFileDialog()
        fileDialog.setFileMode(QFileDialog.AnyFile)
        if fileDialog.exec_():
            fileNames = fileDialog.selectedFiles()
            print('Selected file:', fileNames)

    def addSizePolicy(self):
        button = QPushButton('Button')
        button.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self.addWidget(button)


if __name__ == '__main__':
    app = QApplication(sys.argv)
    gallery = WidgetGallery()
    sys.exit(app.exec_())
