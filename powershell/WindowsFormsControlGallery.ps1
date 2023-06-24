Add-Type -AssemblyName System.Windows.Forms

# 创建主窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = "Control Gallery"
$form.Size = New-Object System.Drawing.Size(800, 600)

# 创建控件列表框
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(200, 500)
$form.Controls.Add($listBox)

# 添加控件名称到列表框
$controls = @("Button", "TextBox", "Label", "ComboBox", "CheckBox", "RadioButton", "ListBox", "PictureBox", "ProgressBar", "DateTimePicker", "MenuStrip", "TreeView", "DataGridView", "TabControl", "TabControl2", "WebBrowser")
$listBox.Items.AddRange($controls)

# 创建控件展示区域
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Size = New-Object System.Drawing.Size(580, 500)
$controlPanel.Location = New-Object System.Drawing.Point(220, 10)
$form.Controls.Add($controlPanel)

# 处理列表框选项改变事件
$listBox.Add_SelectedIndexChanged({
    $controlPanel.Controls.Clear()
    $selectedControl = $listBox.SelectedItem

    switch ($selectedControl) {
        "Button" {
            $button = New-Object System.Windows.Forms.Button
            $button.Text = "Click Me"
            $button.Size = New-Object System.Drawing.Size(100, 30)
            $controlPanel.Controls.Add($button)
        }
        "TextBox" {
            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Size = New-Object System.Drawing.Size(100, 30)
            $controlPanel.Controls.Add($textBox)
        }
        "Label" {
            $label = New-Object System.Windows.Forms.Label
            $label.Text = "Hello, World!"
            $label.Size = New-Object System.Drawing.Size(100, 30)
            $controlPanel.Controls.Add($label)
        }
        "ComboBox" {
            $comboBox = New-Object System.Windows.Forms.ComboBox
            $comboBox.Size = New-Object System.Drawing.Size(100, 30)
            $comboBox.Items.AddRange(@("Option 1", "Option 2", "Option 3"))
            $controlPanel.Controls.Add($comboBox)
        }
        "CheckBox" {
            $checkBox = New-Object System.Windows.Forms.CheckBox
            $checkBox.Text = "Check Me"
            $checkBox.Size = New-Object System.Drawing.Size(100, 30)
            $controlPanel.Controls.Add($checkBox)
        }
        "RadioButton" {
            $radioButton = New-Object System.Windows.Forms.RadioButton
            $radioButton.Text = "Select Me"
            $radioButton.Size = New-Object System.Drawing.Size(100, 30)
            $controlPanel.Controls.Add($radioButton)
        }
        "ListBox" {
            $listBoxControl = New-Object System.Windows.Forms.ListBox
            $listBoxControl.Size = New-Object System.Drawing.Size(100, 100)
            $listBoxControl.Items.AddRange(@("Item 1", "Item 2", "Item 3"))
            $controlPanel.Controls.Add($listBoxControl)
        }
        "PictureBox" {
            $pictureBox = New-Object System.Windows.Forms.PictureBox
            $pictureBox.Size = New-Object System.Drawing.Size(100, 100)
            $pictureBox.Image = [System.Drawing.Image]::FromFile("path/to/image.jpg")
            $controlPanel.Controls.Add($pictureBox)
        }
        "ProgressBar" {
            $progressBar = New-Object System.Windows.Forms.ProgressBar
            $progressBar.Size = New-Object System.Drawing.Size(100, 30)
            $progressBar.Value = 50
            $controlPanel.Controls.Add($progressBar)
        }
        "DateTimePicker" {
            $dateTimePicker = New-Object System.Windows.Forms.DateTimePicker
            $dateTimePicker.Size = New-Object System.Drawing.Size(150, 30)
            $controlPanel.Controls.Add($dateTimePicker)
        }
        "MenuStrip" {
            $menuStrip = New-Object System.Windows.Forms.MenuStrip
            $menuItem = $menuStrip.Items.Add("File")
            $subMenuItem = $menuItem.DropDownItems.Add("Open")
            $subMenuItem.Add_Click({
                [System.Windows.Forms.MessageBox]::Show("Open clicked!")
            })
            $controlPanel.Controls.Add($menuStrip)
        }
        "TreeView" {
            $treeView = New-Object System.Windows.Forms.TreeView
            $treeNode1 = $treeView.Nodes.Add("Node 1")
            $treeNode1.Nodes.Add("Subnode 1")
            $treeNode2 = $treeView.Nodes.Add("Node 2")
            $treeNode2.Nodes.Add("Subnode 2")
            $controlPanel.Controls.Add($treeView)
        }
        "DataGridView" {
            $dataGridView = New-Object System.Windows.Forms.DataGridView
            $dataGridView.Size = New-Object System.Drawing.Size(300, 200)
            $dataGridView.Columns.Add("Column1", "Column 1")
            $dataGridView.Rows.Add("Value 1")
            $dataGridView.Rows.Add("Value 2")
            $controlPanel.Controls.Add($dataGridView)
        }
        "TabControl" {
            $tabControl = New-Object System.Windows.Forms.TabControl
            $tabPage1 = New-Object System.Windows.Forms.TabPage
            $tabPage1.Text = "Tab 1"
            $tabPage2 = New-Object System.Windows.Forms.TabPage
            $tabPage2.Text = "Tab 2"
            $tabControl.TabPages.Add($tabPage1)
            $tabControl.TabPages.Add($tabPage2)
            $controlPanel.Controls.Add($tabControl)
        }
        "TabControl2" {
            $tabControl = New-Object System.Windows.Forms.TabControl
            $tabPage1 = New-Object System.Windows.Forms.TabPage
            $tabPage1.Text = "Tab 1"
            $tabPage2 = New-Object System.Windows.Forms.TabPage
            $tabPage2.Text = "Tab 2"
            $tabControl.Controls.Add($tabPage1)
            $tabControl.Controls.Add($tabPage2)
            $controlPanel.Controls.Add($tabControl)
        }
        "WebBrowser" {
            $webBrowser = New-Object System.Windows.Forms.WebBrowser
            $webBrowser.Size = New-Object System.Drawing.Size(500, 400)
            $webBrowser.Navigate("https://www.google.com")
            $controlPanel.Controls.Add($webBrowser)
        }
    }
})

# 显示主窗口
$form.ShowDialog()
