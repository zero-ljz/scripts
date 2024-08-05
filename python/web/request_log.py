from bottle import Bottle, request, response
import datetime, time
import logging

app = Bottle()

# 配置日志记录器
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s', handlers=[logging.FileHandler('wait_log.txt'), logging.StreamHandler()])

@app.route('/<path:re:.*>', method=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
def wait(path):
    # 获取客户端 IP
    client_ip = request.remote_addr

    logging.info(f"Client {client_ip} started the request")
    
    # 检查客户端是否取消请求
    input_stream = request.environ.get('wsgi.input')
    if input_stream and input_stream.read(1) == b'':
        logging.info(f"Client {client_ip} canceled the request")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True, reloader=True)
