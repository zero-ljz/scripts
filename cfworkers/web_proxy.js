/**
 * Web Proxy Worker
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  // url.searchParams.get('url')
  const queryParams = url.searchParams.toString();

  let newUrl = url.pathname.slice(1);
  if (queryParams) {
      newUrl += "?" + queryParams;
  }

  if (newUrl) {
      if (!newUrl.startsWith("http://") && !newUrl.startsWith("https://")) {
          newUrl = "http://" + newUrl;
      }

      try {
          // 处理浏览器发来的请求头
          const headers = new Headers(request.headers);
          // 要删除的请求头字段列表
          const headersToRemove = [
              "Host",
              "Accept-Encoding", // 不把浏览器支持的编码方式发送给代理网址
          ];
          // 使用 delete 方法删除指定的请求头字段
          for (const header of headersToRemove) {
              headers.delete(header);
          }
          // 添加缓存控制字段
          headers.set("Cache-Control", "no-cache");

          // 发起代理请求
          const proxyResponse = await fetch(newUrl, {
              method: request.method,
              headers: headers,
              body: request.body,
              redirect: "manual", // 不要自动重定向
          });

          // 处理代理地址返回的响应头
          const responseHeaders = new Headers(proxyResponse.headers);
          // 设置允许的请求来源
          responseHeaders.set("Access-Control-Allow-Origin", "*"); // 允许所有来源访问，可以根据需求进行修改
          // 设置允许的请求方法
          responseHeaders.set(
              "Access-Control-Allow-Methods",
              "GET, POST, PUT, DELETE, OPTIONS"
          );

          // 将代理响应的头部字段复制到响应对象
          for (const [key, value] of proxyResponse.headers.entries()) {
              if (
                  ![
                      "Content-Length",
                      "Content-Encoding",
                      "Transfer-Encoding",
                      "Cache-Control",
                  ].includes(key)
              ) {
                  responseHeaders.set(key, value);
              }
          }

          if (proxyResponse.status >= 301 && proxyResponse.status <= 308) {
              // 遇到重定向时重定向到代理地址
              const redirectLocation = proxyResponse.headers.get("Location");
              if (redirectLocation) {
                  responseHeaders.set("Location", url.origin + "/" + redirectLocation);
              }
          }

          if (
              proxyResponse.headers.get("Content-Length") &&
              parseInt(proxyResponse.headers.get("Content-Length")) > 1048576
          ) {
              console.log("<1MB");
              const readable = proxyResponse.body;
              if (!readable) {
                  return new Response("No readable body", { status: 500 });
              }

              const { readable: transformed, writable } = new TransformStream();
              const writer = writable.getWriter();
              const reader = readable.getReader();

              pump(reader, writer).catch((err) => {
                  console.error("Stream error:", err);
                  writer.close();
              });

              return new Response(transformed, {
                  status: proxyResponse.status,
                  headers: responseHeaders,
              });
          } else {

              // 直接返回响应内容
              let responseBody = await proxyResponse.arrayBuffer();
              return new Response(responseBody, {
                  status: proxyResponse.status,
                  headers: responseHeaders,
              });
          }
      } catch (error) {
          return new Response(`Error occurred: ${error}`, { status: 500 });
      }
  } else {
      const html = `
<!DOCTYPE html>
<html>

<head>
    <title>Web Proxy</title>
</head>

<body>
    <h2>Web Proxy</h2>
    <form onsubmit="event.preventDefault(); window.location.href = '/' + new FormData(this).get('url');">
        <label style="display: block; margin: 1rem 0" for="url">URL:</label>
        <input type="text" id="url" name="url" placeholder="Resource url for proxy access" value="http://" required />
        <input type="submit" value="GO" />
    </form>
</body>

</html>
      `;

      return new Response(html, {
          headers: {
              "content-type": "text/html;charset=UTF-8",
          },
      });
  }
}

async function pump(reader, writer) {
  try {
      while (true) {
          const { value, done } = await reader.read();
          if (done) {
              writer.close();
              break;
          }
          await writer.write(value);
      }
  } catch (err) {
      console.error("Error in pump:", err);
      writer.close();
  }
}