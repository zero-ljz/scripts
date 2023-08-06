Add-Type -AssemblyName System.Windows.Forms

# 创建一个简单的 GUI 窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI 示例"
$form.Width = 300
$form.Height = 200

# 创建一个标签控件
$label = New-Object System.Windows.Forms.Label
$label.Text = "Hello, PowerShell GUI!"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 50)

# 创建一个按钮控件
$button = New-Object System.Windows.Forms.Button
$button.Text = "点击我"
$button.Location = New-Object System.Drawing.Point(100, 100)
$button.Add_Click({
    $label.Text = "按钮被点击了！"
})

# 将控件添加到窗口中
$form.Controls.Add($label)
$form.Controls.Add($button)

# 显示窗口
$form.ShowDialog()
