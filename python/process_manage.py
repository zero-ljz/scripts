import os
import platform
import subprocess
import sys

def find_process_by_command(command):
    if platform.system() == 'Windows':
        cmd = r'*' + command + '*'
        result = subprocess.run(['powershell', '-Command', "Get-WmiObject Win32_Process | Where-Object {$_.CommandLine -like '" + cmd + "'} | Select-Object -ExpandProperty ProcessId"], capture_output=True, text=True)
        if result.returncode == 0:
            # print(result.stdout)
            try:
                return int(result.stdout.strip())
            except ValueError:
                return None
    elif platform.system() == 'Linux':
        result = subprocess.run(['pgrep', '-f', command], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            pid_list = result.stdout.strip().split('\n')
            if pid_list:
                return int(pid_list[0])
    return None

def terminate_process_by_pid(pid):
    if platform.system() == 'Windows':
        command = f'taskkill /F /PID {pid}'
    elif platform.system() == 'Linux':
        command = f'kill -9 {pid}'
    try:
        output = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return output.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr.strip()}"

if __name__ == '__main__':
    # script_dir = os.path.dirname(os.path.realpath(__file__))
    # app_script = os.path.join(script_dir, 'app.py')
    # cmd = '"' + sys.executable + '" "' + app_script + '"'
    # print(cmd)

    # pid = find_process_by_command(cmd)
    # print(pid)

    # if pid:
    #     pass
    #     print(terminate_process_by_pid(pid))












    # pid = find_process_by_command(r'"C:\Users\LJZ\AppData\Local\Programs\Python\Python39\python.exe" "C:\Users\LJZ\repos\cron\app.py"')
    pid = find_process_by_command(r'"C:\Users\LJZ\AppData\Local\Programs\Python\Python39\python.exe" "api.py"')
    print(pid)