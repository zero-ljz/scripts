import sys
import asyncio

from aiohttp import web

# uvloop 目前不支持windows
if sys.platform != 'win32':
    try:
        import uvloop
        asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
    except ImportError:
        pass  # 如果无法导入 uvloop，则继续使用默认的 asyncio 事件循环策略
else:
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

async def echo(request):
    request_line = f'{request.method} {request.path_qs} HTTP/{request.version[0]}.{request.version[1]}'
    headers = '\n'.join([f'{key}: {value}' for key, value in sorted(request.headers.items())])

    # 异步读取请求体
    body = await request.text()

    response = web.Response(
        text=f'{request_line}\n{headers}\n\n{body}',
        content_type='text/plain',
    )

    response.headers['Access-Control-Allow-Origin'] = '*'

    print(response.text)
    return response

app = web.Application()
app.router.add_route('*', '/{path:.*}', echo)

if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=80)
