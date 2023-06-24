import os

os.chdir(r'C:\Users\22677\OneDrive\程序\frp') # 双击执行不需要这行

print('Current working directory: ' + os.getcwd())

os.system(r'%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -NoExit ".\frpc.exe -c ./frpc_.ini"')