const http = require('http');
const https = require('https');
const net = require('net');
const { URL } = require('url');

const PORT = 3000;
const PROXY_BASE = `http://localhost:${PORT}`;

// =====================================================================
// 辅助函数: 从 Referer 中推断目标 Base URL (用于处理浏览器中的相对路径请求)
// =====================================================================
function getTargetFromReferer(req) {
    const referer = req.headers['referer'];
    if (!referer) return null;

    try {
        const refererUrl = new URL(referer);
        // 只有当 Referer 也是来自本代理时才尝试解析
        if (refererUrl.origin === `http://localhost:${PORT}`) {
            // Referer 结构通常是: http://localhost:3000/https://target.com/path
            const path = refererUrl.pathname.slice(1); // 去掉开头的 /
            
            // 简单 heuristic: 如果路径部分看起来像个 URL
            if (path.startsWith('http')) {
                const targetUrlObj = new URL(path);
                return targetUrlObj.origin; 
            }
        }
    } catch (e) {
        return null;
    }
    return null;
}

// =====================================================================
// 主 HTTP 请求处理逻辑 (网关模式 / 普通代理模式)
// =====================================================================
const server = http.createServer((clientReq, clientRes) => {
    let targetUrlString = clientReq.url.slice(1); // 去掉开头的 '/'
    let targetUrl = null;

    // --- 1. 目标 URL 解析策略 ---
    
    // 策略 A: URL 显式包含目标 (例如 curl http://localhost:3000/http://...)
    if (targetUrlString.startsWith('http://') || targetUrlString.startsWith('https://')) {
        try {
            targetUrl = new URL(targetUrlString);
        } catch (e) {
            clientRes.writeHead(400);
            clientRes.end(`Invalid Target URL: ${e.message}`);
            return;
        }
    } 
    // 策略 B: 浏览器隐式资源请求 (例如 <img src="/logo.png">)
    else {
        // 尝试从 Referer 头部“救回”目标域名
        const inferredOrigin = getTargetFromReferer(clientReq);
        if (inferredOrigin) {
            try {
                // 将相对路径拼接到推断出的 Origin 上
                targetUrl = new URL(clientReq.url, inferredOrigin);
                console.log(`[Auto-Route] ${clientReq.url} -> ${targetUrl.href}`);
            } catch (e) {}
        }

        // 如果还是找不到目标，说明这不是一个代理请求，可能只是访问了根目录
        if (!targetUrl) {
            if (clientReq.url === '/' || clientReq.url === '/favicon.ico') {
                clientRes.writeHead(200, {'Content-Type': 'text/plain; charset=utf-8'});
                clientRes.end('Node.js Super Proxy is Running!\n\nUsage 1 (Browser/Curl): http://localhost:3000/https://www.google.com\nUsage 2 (Docker/Pip): export https_proxy=http://localhost:3000');
                return;
            }
            clientRes.writeHead(404);
            clientRes.end('Error: Cannot determine target URL. Please use full URL format.');
            return;
        }
    }

    console.log(`[Proxy HTTP] ${clientReq.method} ${targetUrl.href}`);

    // --- 2. 构建转发请求 ---

    const lib = targetUrl.protocol === 'https:' ? https : http;
    
    // 复制并清洗请求头
    const headers = { ...clientReq.headers };
    headers['host'] = targetUrl.host;
    
    // 伪造 Referer 以绕过防盗链 (将 localhost 替换为真实目标)
    if (headers['referer']) {
        try {
            const refObj = new URL(headers['referer']);
            if (refObj.origin === `http://localhost:${PORT}`) {
                headers['referer'] = targetUrl.origin; // 简单粗暴设为目标首页
            }
        } catch(e) {}
    }

    const options = {
        hostname: targetUrl.hostname,
        port: targetUrl.port || (targetUrl.protocol === 'https:' ? 443 : 80),
        path: targetUrl.pathname + targetUrl.search,
        method: clientReq.method,
        headers: headers,
        rejectUnauthorized: false // 忽略自签名证书错误
    };

    // --- 3. 发起请求并建立管道 ---

    const proxyReq = lib.request(options, (proxyRes) => {
        // --- 4. 响应头处理 (为了更好的浏览器兼容性) ---

        // 4.1 删除安全限制 (CSP, Frame-Options) 允许脚本执行
        delete proxyRes.headers['content-security-policy'];
        delete proxyRes.headers['content-security-policy-report-only'];
        delete proxyRes.headers['x-frame-options'];

        // 4.2 修正 Cookie (移除 Domain 和 Secure 限制)
        if (proxyRes.headers['set-cookie']) {
            proxyRes.headers['set-cookie'] = proxyRes.headers['set-cookie'].map(c => 
                c.replace(/Domain=[^;]+;/gi, '').replace(/Secure/gi, '').replace(/SameSite=[^;]+;/gi, '')
            );
        }

        // 4.3 拦截并重写重定向 (Location Header)
        // 只有当状态码是 3xx 且有 Location 时才处理
        if ([301, 302, 303, 307, 308].includes(proxyRes.statusCode) && proxyRes.headers.location) {
            try {
                const originalLoc = proxyRes.headers.location;
                // 解析绝对路径：如果 originalLoc 是相对的 (/login)，会基于 targetUrl 拼成绝对的
                const absoluteLoc = new URL(originalLoc, targetUrl.href).href;
                // 重写为指向代理的地址
                const newLoc = `${PROXY_BASE}/${absoluteLoc}`;
                
                console.log(`[Redirect] ${originalLoc} -> ${newLoc}`);
                proxyRes.headers.location = newLoc;
            } catch (e) {
                console.error('Redirect rewrite failed:', e);
            }
        }

        // 转发状态码和处理后的头
        clientRes.writeHead(proxyRes.statusCode, proxyRes.headers);
        
        // 核心：建立数据管道 (Streaming)
        // 数据直接透传，不经过 Node.js 内存缓冲，支持二进制
        proxyRes.pipe(clientRes);
    });

    // 错误处理
    proxyReq.on('error', (e) => {
        console.error(`[ProxyReq Error] ${e.message}`);
        if (!clientRes.headersSent) {
            clientRes.writeHead(502);
            clientRes.end(`Proxy Gateway Error: ${e.message}`);
        }
    });

    // 处理客户端上传的数据 (POST Body)
    clientReq.pipe(proxyReq);
});

// =====================================================================
// HTTPS 隧道支持 (CONNECT 方法)
// 支持 Docker, Pip, Git 等通过 export https_proxy 使用
// =====================================================================
server.on('connect', (req, clientSocket, head) => {
    // req.url 格式通常是 "www.google.com:443"
    console.log(`[Tunnel] ${req.method} ${req.url}`);

    const { port, hostname } = new URL(`http://${req.url}`); // 加 http 只是为了解析方便

    const serverSocket = net.connect(port || 443, hostname, () => {
        // 1. 告诉客户端连接建立成功
        clientSocket.write('HTTP/1.1 200 Connection Established\r\n' +
                           'Proxy-Agent: Node-Super-Proxy\r\n' +
                           '\r\n');
        
        // 2. 建立双向原始 TCP 管道
        serverSocket.write(head);
        serverSocket.pipe(clientSocket);
        clientSocket.pipe(serverSocket);
    });

    serverSocket.on('error', (err) => {
        console.error(`[Tunnel Target Error] ${err.message}`);
        clientSocket.end();
    });

    clientSocket.on('error', (err) => {
        console.error(`[Tunnel Client Error] ${err.message}`);
        serverSocket.end();
    });
});

// =====================================================================
// 启动服务器
// =====================================================================
server.listen(PORT, () => {
    console.log(`\n>>> Node.js Super Proxy running at http://localhost:${PORT}`);
    console.log(`>>> Mode 1: URL Prefix (Browser/Curl) -> http://localhost:${PORT}/https://target.com`);
    console.log(`>>> Mode 2: Standard Proxy (Docker/Pip) -> export https_proxy=http://localhost:${PORT}\n`);
});