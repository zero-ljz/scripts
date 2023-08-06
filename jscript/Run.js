/*
' https://docs.microsoft.com/en-us/windows/win32/shell/shell-shellexecute

' ShellExecute 参数 1 文件路径
' ShellExecute 参数 2 命令行参数
' ShellExecute 参数 3 工作目录，默认为当前脚本所在目录

' ShellExecute 参数4 
' edit 启动编辑器并打开文档进行编辑。
' find 从指定目录开始启动搜索。
' open 打开启动一个应用程序。如果此文件不是可执行文件，则启动其关联的应用程序。
' print 打印文档文件。
' properties 显示对象的属性。
' runas 以管理员身份启动应用程序。用户帐户控制(UAC)将提示用户同意运行升级的应用程序，或输入用于运行应用程序的管理员帐户的凭证。

' ShellExecute 参数 5
' 0 打开一个隐藏窗口的应用程序。
' 1 用一个普通窗口打开应用程序。如果窗口被最小化或最大化，系统会将其恢复到原来的大小和位置。
' 2 用最小化的窗口打开应用程序。
' 3 打开最大化窗口的应用程序。
' 4 打开应用程序，使其窗口保持最近的大小和位置。活动窗口保持活动状态。
' 5 打开应用程序，使其窗口保持当前大小和位置。
' 7 用最小化的窗口打开应用程序。活动窗口保持活动状态。
' 10 打开应用程序，使其窗口处于应用程序指定的默认状态。
*/

//var objShell = new ActiveXObject("Shell.Application");
//objShell.ShellExecute("cmd.exe", "/k ipconfig", "./", "open", 1);



var objShell = new ActiveXObject("WScript.Shell");
// 文件路径
var filePath = "cmd.exe /k ipconfig";
// 进程名称
var pname = "cmd.exe"; 
// 工作目录 ./ 或者 .\\ 表示当前目录
objShell.CurrentDirectory = "./"; 

if(FindProcess(pname))
{
objShell.Run("taskkill /IM " + pname + " /T /F", 0, true); // true为等待执行完并返回错误代码，0为没有错误
WSH.Echo("Task killed.");
}

objShell.Run(filePath, 1);
WSH.Echo(pname + " is Running...");


WSH.Quit();




function FindProcess(strProcess) { //查询指定进程
    var locator = new ActiveXObject("WbemScripting.SWbemLocator");
    var service = locator.ConnectServer("."); // 本机
    var properties = service.ExecQuery("SELECT * FROM Win32_Process");
    var eProc = new Enumerator(properties);

    var bRet = false;
    for (; !eProc.atEnd(); eProc.moveNext()) {
        var p = eProc.item().Name;
        if (p.toUpperCase() == strProcess.toUpperCase()) {
            bRet = true;
            break;
        }
    }
    return bRet;
}

















