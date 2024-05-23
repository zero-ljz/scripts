from fastapi import FastAPI, Request, Response
from fastapi.responses import PlainTextResponse

app = FastAPI()

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"])
async def echo(request: Request, path: str):
    request_line = f'{request.method} {request.url.path}{request.url.query and "?" + request.url.query} {request.scope["http_version"]}'
    headers = '\n'.join([f'{key}: {value}' for key, value in sorted(request.headers.items())])
    body = await request.body()
    
    response_content = f'{request_line}\n{headers}\n\n{body.decode("utf-8")}'
    
    return PlainTextResponse(response_content, headers={"Access-Control-Allow-Origin": "*"})

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)