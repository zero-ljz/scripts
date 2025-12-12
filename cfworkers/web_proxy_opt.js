/**
 * Web Proxy Worker
 */

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);

        // 1. 首页直接返回 UI
        if (url.pathname === "/" || url.pathname === "") {
            return handleHome();
        }

        // 2. 解析目标 URL
        let targetUrlStr = request.url.substring(url.origin.length + 1);
        if (!targetUrlStr.match(/^https?:\/\//)) {
            targetUrlStr = "https://" + targetUrlStr;
        }

        try {
            const targetUrl = new URL(targetUrlStr);

            // 3. 构建代理请求头
            const requestHeaders = new Headers(request.headers);
            
            // 显式删除 'Accept-Encoding'。
            // 这告诉目标服务器不要发送 Gzip/Brotli 压缩数据，而是发送原始二进制。
            // 这样 Cloudflare 不需要消耗 CPU 去解压数据，直接像水管一样透传，速度最快。
            requestHeaders.delete("Accept-Encoding"); 
            
            requestHeaders.set("Host", targetUrl.host);
            requestHeaders.set("Referer", targetUrl.origin);
            requestHeaders.set("Origin", targetUrl.origin);
            
            const headersToDelete = ["cf-connecting-ip", "cf-ipcountry", "cf-ray", "cf-visitor", "x-forwarded-proto"];
            headersToDelete.forEach(h => requestHeaders.delete(h));

            // 4. 处理 OPTIONS 预检
            if (request.method === "OPTIONS") {
                return new Response(null, {
                    headers: {
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                        "Access-Control-Allow-Headers": request.headers.get("Access-Control-Request-Headers") || "*",
                        "Access-Control-Max-Age": "86400"
                    }
                });
            }

            // 5. 发起请求
            const proxyResponse = await fetch(targetUrl.toString(), {
                method: request.method,
                headers: requestHeaders,
                body: request.method === 'GET' || request.method === 'HEAD' ? null : request.body,
                redirect: "manual" 
            });

            // 6. 处理响应头
            const responseHeaders = new Headers(proxyResponse.headers);
            responseHeaders.set("Access-Control-Allow-Origin", "*");
            responseHeaders.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            
            // 删除不需要的安全策略头
            responseHeaders.delete("Content-Security-Policy"); 
            responseHeaders.delete("Content-Security-Policy-Report-Only");
            responseHeaders.delete("Clear-Site-Data");

            // --- 保留原始 Content-Length ---
            // 这有助于下载工具（如 IDM、浏览器下载器）显示进度条并进行分块下载
            if (proxyResponse.headers.has("Content-Length")) {
                responseHeaders.set("Content-Length", proxyResponse.headers.get("Content-Length"));
            }

            // 7. 处理重定向
            const location = responseHeaders.get("Location");
            if (location) {
                let newLocation = location;
                if (location.startsWith("http")) {
                    newLocation = url.origin + "/" + location;
                } else if (location.startsWith("/")) {
                    newLocation = url.origin + "/" + targetUrl.origin + location;
                } else {
                    newLocation = url.origin + "/" + new URL(location, targetUrl.href).href;
                }
                responseHeaders.set("Location", newLocation);
            }

            // 8. 返回响应
            // 使用 Identity TransformStream 确保数据保持原样流式传输
            return new Response(proxyResponse.body, {
                status: proxyResponse.status,
                statusText: proxyResponse.statusText,
                headers: responseHeaders
            });

        } catch (e) {
            return new Response(`Proxy Error: ${e.message}`, { status: 500 });
        }
    }
};

function handleHome() {
    const html = `
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Web Proxy Worker</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f0f2f5; }
            .container { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); width: 100%; max-width: 500px; }
            h2 { margin-top: 0; color: #333; text-align: center; }
            input[type="text"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
            button { width: 100%; padding: 10px; background-color: #0070f3; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
            button:hover { background-color: #005bb5; }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Web Proxy</h2>
            <form onsubmit="event.preventDefault(); const url = document.getElementById('url').value; if(url) window.location.href = '/' + url;">
                <input type="text" id="url" placeholder="输入网址 (例如: https://google.com)" required />
                <button type="submit">访问</button>
            </form>
        </div>
    </body>
    </html>
    `;
    return new Response(html, {
        headers: { "content-type": "text/html;charset=UTF-8" },
    });
}