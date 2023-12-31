from bottle import Bottle, request, response
app = Bottle()

@app.route('/<path:re:.*>', method=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'])
def echo(path):
    request_line = f'{request.method} {request.path}{(request.query_string or "") and "?" + request.query_string} {request.environ.get("SERVER_PROTOCOL")}'
    headers = '\n'.join([f'{key}: {value}' for key, value in sorted(request.headers.items())])
    body = request.body.read().decode("utf-8")

    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Content-Type'] = 'text/plain; charset=UTF-8'
    response.body = f'{request_line}\n{headers}\n\n{body}'

    print(response.body)
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True, reloader=True)