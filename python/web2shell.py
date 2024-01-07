#!/usr/bin/env python3

# python3 -m pip install bottle
# export AUTH_PASSWORD="123qwe123@"
# python3 web2shell.py

# 被执行的python脚本最好设置
# export PYTHONIOENCODING=utf-8
# sys.stdout.reconfigure(encoding='utf-8')

import subprocess
import re, sys, os, base64, datetime, time
from bottle import Bottle, request, template, response, static_file, abort, HTTPResponse
import urllib.parse
import logging

app_name = os.path.splitext(os.path.basename(sys.argv[0]))[0]
logging.basicConfig(filename=app_name + '.log', level=logging.INFO)

root_directory = os.path.abspath(os.sep)
user_home_directory = os.path.expanduser("~")

app = Bottle()
auth_username = os.environ.get('AUTH_USERNAME', '')
auth_password = os.environ.get('AUTH_PASSWORD', '123qwe123@') # Authorization: Basic OjEyM3F3ZTEyM0A=

# 假设这是保存在服务器端的用户名和密码信息
users = {
    auth_username: auth_password,
}

def check_auth(username, password):
    """检查用户名和密码是否有效"""
    return username in users and users[username] == password

def requires_auth(f):
    """装饰器函数，用于进行基本认证"""
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if auth_header:
            auth_type, credentials = auth_header.split(' ')
            if auth_type.lower() == 'basic':
                decoded_credentials = base64.b64decode(credentials).decode('utf-8')
                username, password = decoded_credentials.split(':', 1)
                if check_auth(username, password):
                    # 用户名和密码有效，继续执行被装饰的视图函数
                    return f(*args, **kwargs)
        # 认证失败，返回401 Unauthorized状态码，并添加WWW-Authenticate头
        response = HTTPResponse(status=401)
        response.headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        return response
    return wrapper


@app.route('/', method='GET')
# @app.route('/<path:re:.*>')
@app.route('/<path:path>')
@requires_auth
def handle_request(path=None):
    if path == 'favicon.ico':
        abort(404, 'Not Found')
    cwd = request.query.cwd or request.forms.cwd or user_home_directory
    shell = (request.query.shell or request.forms.shell) in ["1", "true", "on"]
    capture_output = (request.query.capture_output or request.forms.capture_output) in ["1", "true", "on"]
    
    if command := request.query.cmd or request.forms.cmd: # 参数中包含了空格时要用双引号"将参数包括起来
        params = split_with_quotes(command, sep=' ')
    elif path is not None: # 参数中包含了斜杠/时要用双引号"将参数包括起来
        params = split_with_quotes(path)
        command = " ".join(f'"{value}"' for value in params)
    else:
        return static_file('web2shell.html', root='.', mimetype='text/html')
    print()
    
    print(datetime.datetime.now(), 'Starting', '\n', 'cmd:', params, '\n', 'cwd:', cwd)
    # run方法这里的shell=True 代表使用系统的shell环境执行命令而非当前脚本所处的shell环境
    # 请求取消或命令执行超时后子进程不会中止，只是脚本不再阻塞等待结果，shell=False时超时才有效果
    try:
        completed_process = subprocess.run(params, cwd=cwd, shell=shell, capture_output=capture_output, timeout=1800)
    except Exception as e:
        print('Exception:', e)
        return 'Exception: ' + str(e)

    if capture_output:
        output = try_decode(completed_process.stdout)
        if completed_process.returncode != 0:
            response.status = 500
            output = f"Error: {completed_process.returncode}\n\n{try_decode(completed_process.stderr)}\n\n{output}"
    print(datetime.datetime.now(), 'finished', '\n', 'cmd:', params, '\n', 'cwd:', cwd)

    if capture_output:
        response.headers['Content-Type'] = 'text/plain; charset=UTF-8'
        response.content_type = 'text/plain; charset=UTF-8'
        response.body = output

        logging.info('\n' + response.body)

    try: # 终止子进程
        completed_process.check_returncode()
    except subprocess.CalledProcessError as e:
        pass
    return response

def split_with_quotes(string, sep='/'):
    parts = re.findall(r'(?:".*?"|[^' + sep + r'"]+)', string)
    return [part.strip('"') for part in parts]

def try_decode(byte_data, encodings=['utf-8', 'utf-8-sig', 'gbk', 'latin-1']):
    for encoding in encodings:
        try:
            decoded_string = byte_data.decode(encoding)
            return decoded_string
        except UnicodeDecodeError:
            continue
    return None

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Run the server.')
    parser.add_argument('--host', '-H', default='0.0.0.0', help='Host to listen on (default: 0.0.0.0)')
    parser.add_argument('--port', '-p', type=int, default=8000, help='Port to listen on (default: 8000)')
    args = parser.parse_args()

    app.run(host=args.host, port=args.port, debug=True, reloader=True)