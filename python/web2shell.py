#!/usr/bin/env python3

# python3 -m pip install bottle waitress
# export AUTH_PASSWORD="123qwe123@"
# python3 web2shell.py

import subprocess
import re, os, base64
from bottle import Bottle, request, template, response, static_file, abort, HTTPResponse

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
    query = dict(request.query.decode('utf-8'))
    if command := query.get('c'):
        print(command)
        output = subprocess.check_output(command, shell=True).decode("utf-8", errors="ignore")
    elif path is not None:
        params = split_with_quotes(path)
        print(params)
        command = " ".join(f'"{value}"' for value in params)
        output = subprocess.run(params, capture_output=True, text=True, encoding='utf-8', errors='ignore').stdout
    else:
        # return template('web2shell.html')
        return static_file('web2shell.html', root='.', mimetype='text/html')

    # response.headers['Content-Type'] = 'text/plain; charset=UTF-8'
    response.content_type = 'text/plain; charset=UTF-8'
    response.body = output
    return response

def split_with_quotes(string):
    parts = re.findall(r'(?:".*?"|[^/"]+)', string)
    return [part.strip('"') for part in parts]


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Run the server.')
    parser.add_argument('--host', '-H', default='0.0.0.0', help='Host to listen on (default: 0.0.0.0)')
    parser.add_argument('--port', '-p', type=int, default=8000, help='Port to listen on (default: 8000)')
    args = parser.parse_args()

    app.run(host=args.host, port=args.port, debug=True, reloader=True, server='waitress')