import tkinter as tk
from tkinter import ttk

class WidgetGallery(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Widget Gallery")
        self.create_widgets()

    def create_widgets(self):
        # Label
        label = ttk.Label(self, text="This is a Label")
        label.pack(pady=10)

        # Button
        button = ttk.Button(self, text="Click Me")
        button.pack(pady=10)

        # Entry
        entry = ttk.Entry(self)
        entry.pack(pady=10)

        # Checkbutton
        checkbutton = ttk.Checkbutton(self, text="Check me")
        checkbutton.pack(pady=10)

        # Radiobutton
        radiobutton1 = ttk.Radiobutton(self, text="Option 1")
        radiobutton1.pack()
        radiobutton2 = ttk.Radiobutton(self, text="Option 2")
        radiobutton2.pack()

        # Combobox
        combobox = ttk.Combobox(self, values=["Option 1", "Option 2", "Option 3"])
        combobox.pack(pady=10)

        # Progressbar
        progressbar = ttk.Progressbar(self, length=200)
        progressbar.pack(pady=10)

        # Scale
        scale = ttk.Scale(self, from_=0, to=100, orient=tk.HORIZONTAL)
        scale.pack(pady=10)

        # Notebook
        notebook = ttk.Notebook(self)
        tab1 = ttk.Frame(notebook)
        tab2 = ttk.Frame(notebook)
        notebook.add(tab1, text="Tab 1")
        notebook.add(tab2, text="Tab 2")
        notebook.pack(pady=10)

        # Treeview
        treeview = ttk.Treeview(self)
        treeview.pack(pady=10)

        # Listbox
        listbox = tk.Listbox(self)
        listbox.pack(pady=10)

        # Menu
        menubar = tk.Menu(self)
        self.config(menu=menubar)
        file_menu = tk.Menu(menubar, tearoff=False)
        file_menu.add_command(label="New")
        file_menu.add_command(label="Open")
        file_menu.add_command(label="Save")
        menubar.add_cascade(label="File", menu=file_menu)

if __name__ == "__main__":
    gallery = WidgetGallery()
    gallery.mainloop()
