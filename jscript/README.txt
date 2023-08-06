Windows Script Host (WSH) 是 Windows 操作系统提供的一种脚本宿主环境，它允许您在 Windows 平台上运行和执行各种脚本语言，如 VBScript 和 JScript。

WSH 提供了一种简单且灵活的方式来自动化和管理 Windows 系统的各种任务和操作。下面是一些 WSH 的常见用途：

系统管理和自动化：使用 WSH 脚本可以自动执行各种系统管理任务，如创建、修改和删除文件、文件夹和注册表项，管理网络连接，执行系统备份等。

软件部署和配置：通过 WSH，您可以编写脚本来自动化软件部署和配置过程。您可以使用脚本安装软件、配置应用程序设置、创建快捷方式等。

网络管理和监控：WSH 脚本可以帮助您监控和管理网络环境，包括检查网络连接、配置网络设备、获取网络信息、发送网络请求等。

系统日志和事件处理：使用 WSH，您可以编写脚本来监视系统日志和事件，并根据特定条件触发操作，如发送电子邮件通知、生成报告等。

用户界面和交互：WSH 提供了一些对象和方法，使您能够与用户进行交互，如弹出消息框、显示输入对话框、创建自定义界面等。

请注意，WSH 支持多种脚本语言，但它的主要用途是在 Windows 环境下执行 VBScript 和 JScript 脚本。因此，您可以使用这些脚本语言编写和执行各种任务和操作。



Windows Script Host（WSH）中使用的JScript是基于ECMAScript标准的第3版（ECMAScript 3）版本。


JScript和JavaScript在语法和核心功能上非常相似，它们都是基于ECMAScript标准的脚本语言，并具有类似的语法结构和特性。

JScript最初是由微软开发的一种脚本语言，用于在Windows环境下进行脚本编程。它在语法和行为上与JavaScript非常接近，因此可以说JScript是微软对JavaScript的实现。

JavaScript是一种跨平台的脚本语言，最初由Netscape公司开发，后来成为ECMAScript标准的实现之一。它在Web开发中得到广泛应用，可以在不同的浏览器和操作系统上运行。

尽管JScript和JavaScript有一些细微的差异和特定的实现细节，但从大部分功能和语法角度来看，它们可以被认为是相同的语言。在实际开发中，JScript和JavaScript通常可以互换使用，特别是在Windows环境下进行脚本编程。


以管理员身份运行hta脚本
Start-Process -FilePath "C:\windows\system32\mshta.exe" "C:\Users\ljz\Desktop\app.hta" -Verb RunAs

hta应用程序说明
https://learn.microsoft.com/en-us/previous-versions/ms536496%28v%3dvs.85%29