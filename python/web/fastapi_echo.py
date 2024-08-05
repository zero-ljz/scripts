from fastapi import FastAPI, Request, Response
from fastapi.responses import PlainTextResponse

app = FastAPI()

async def get_request_content(request: Request):
    request_line = f'{request.method} {request.url.path}{request.url.query and "?" + request.url.query} {request.scope["http_version"]}'
    headers = '\n'.join([f'{key}: {value}' for key, value in sorted(request.headers.items())])
    body = await request.body()
    response_content = f'\n{request_line}\n{headers}\n\n{body.decode(encoding="utf-8", errors="ignore")}'
    return response_content

async def get_request_content_raw(request: Request):
    # 获取原始的 ASGI 作用域
    scope = request.scope

    # 构建请求行
    method = scope["method"]
    full_path = scope["raw_path"].decode('utf-8')
    query_string = scope["query_string"].decode('utf-8')
    http_version = scope["http_version"]

    request_line = f"{method} {full_path}"
    if query_string:
        request_line += f"?{query_string} {http_version}"
    else:
        request_line += f" {http_version}"

    # 构建请求头
    headers = '\n'.join([f'{key.decode("utf-8")}: {value.decode("utf-8")}' for key, value in sorted(scope["headers"])])

    # 获取请求体
    body = await request.body()

    # 构建响应体
    response_content = f'{request_line}\n{headers}\n\n{body.decode(encoding="utf-8", errors="ignore")}'
    return response_content

@app.middleware("http")
async def log_request(request: Request, call_next):
    response_content = await get_request_content(request)
    # 打印原始请求报文
    print('\n\n', response_content)
    # 继续处理请求
    response = await call_next(request)
    return response

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"])
async def echo(request: Request, path: str):
    response_content = await get_request_content(request)
    return PlainTextResponse(response_content, headers={"Access-Control-Allow-Origin": "*"})

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)