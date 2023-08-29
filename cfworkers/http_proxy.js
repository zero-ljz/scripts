/**
 * HTTP Proxy Worker
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
  })
  
  async function handleRequest(request) {
    const url = new URL(request.url)
    // url.searchParams.get('url')
    const queryParams = url.searchParams.toString()
    
    let newUrl = url.pathname.slice(1)
    if (queryParams) {
      newUrl += '?' + queryParams
    }
  
    if (newUrl) {
      try {
        // 处理浏览器发来的请求头
        const headers = new Headers(request.headers)
        // 要删除的请求头字段列表
        const headersToRemove = [
          'Host',
          'Accept-Encoding', // 不把浏览器支持的编码方式发送给代理网址
        ]
        // 使用 delete 方法删除指定的请求头字段
        for (const header of headersToRemove) {
          headers.delete(header)
        }
        // 添加缓存控制字段
        headers.set('Cache-Control', 'no-cache')
  
        // 发起代理请求
        const proxyResponse = await fetch(newUrl, {
          method: request.method,
          headers: headers,
          body: request.body,
          redirect: 'manual', // 不要自动重定向
        })
  
        // 处理代理地址返回的响应头
        const responseHeaders = new Headers(proxyResponse.headers)
        // 设置允许的请求来源
        responseHeaders.set('Access-Control-Allow-Origin', '*') // 允许所有来源访问，可以根据需求进行修改
        // 设置允许的请求方法
        responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
  
        // 将代理响应的头部字段复制到响应对象
        for (const [key, value] of proxyResponse.headers.entries()) {
          if (!['Content-Length', 'Content-Encoding', 'Transfer-Encoding', 'Cache-Control'].includes(key)) {
            responseHeaders.set(key, value)
          }
        }
    
        if (proxyResponse.status >= 301 && proxyResponse.status <= 308) {
          // 遇到重定向时重定向到代理地址
          const redirectLocation = proxyResponse.headers.get('Location')
          if (redirectLocation) {
            responseHeaders.set('Location', url.origin + '/' + redirectLocation)
          }
        }
  
        if (proxyResponse.headers.get('Content-Length') && parseInt(proxyResponse.headers.get('Content-Length')) > 1048576) {
          console.log('大于1MB')
          // 边收边传，通过生成器逐步返回响应内容
          // const responseBody = proxyResponse.body
          // return new Response(responseBody, {
          //   status: proxyResponse.status,
          //   headers: responseHeaders,
          // })

           // 边收边传
  const { readable, writable } = new TransformStream();

  // 开始传输数据
  const writer = writable.getWriter();
  const reader = proxyResponse.body.getReader();

  // 使用 transform 方法将数据从 reader 转移到 writer
  await pump(reader, writer);

  // 返回经过转换的响应
  return new Response(readable, {
    status: proxyResponse.status,
    headers: responseHeaders,
  });

        } else {


        //     let newUrlObj = new URL(newUrl);
        //     // const OLD_URL = newUrlObj.host;
        //     // const NEW_URL = url.origin + '/' + newUrlObj.host;
        //     const OLD_URL = newUrlObj.origin;
        //     const NEW_URL = url.origin + '/' + newUrlObj.origin;
            
        
        //     class AttributeRewriter {
        //       constructor(attributeName) {
        //         this.attributeName = attributeName;
        //       }
        //       element(element) {
        //         const attribute = element.getAttribute(this.attributeName);
        //         if (attribute) {
        //           element.setAttribute(
        //             this.attributeName,
        //             attribute.replace(OLD_URL, NEW_URL)
        //           );
        //         }
        //       }
        //     }

        //     const rewriter = new HTMLRewriter()
        //     .on("a", new AttributeRewriter("href"))
        //     .on("img", new AttributeRewriter("src"))
        //     .on("script", new AttributeRewriter("src"))
        //     .on("link", new AttributeRewriter("href"));
           
            

        //   if(proxyResponse.headers.get('Content-Type').startsWith("text/html"))
        //   {
        //     let proxyResponse2 = await rewriter.transform(proxyResponse);
        //     const transformedContent = await proxyResponse2.arrayBuffer();
        //     return new Response(transformedContent, {
        //         status: proxyResponse.status,
        //         headers: responseHeaders,
        //       })
        //   }

          // 直接返回响应内容
          let responseBody = await proxyResponse.arrayBuffer()
          return new Response(responseBody, {
            status: proxyResponse.status,
            headers: responseHeaders,
          })
        }
  
  
      } catch (error) {
        return new Response(`Error occurred: ${error}`, { status: 500 })
      }
    } else {
      const html = `
      <h2>
  HTTP Proxy
  </h2>
  
  <form id="form1">
      <label style="display: block; margin: 1rem 0;" for="text">输入要代理的页面或文件URL</label>
      <textarea style="display: block; margin: 1rem 0;" id="url" placeholder="url" required>http://</textarea>
      <input type="submit" value="Send Request">
  </form>
  
  <script>
      document.getElementById("form1").addEventListener("submit", function(event) {
        event.preventDefault(); // 阻止表单默认提交行为
        var url = document.getElementById("url").value;
  
        // 使用 URL 进行页面跳转
        window.location.href = "/" + url;
      });
    </script>
      
      `
  
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8",
        },
      });
      
    }
  }
  

  // 辅助函数：异步地将从一个 reader 读取的数据写入一个 writer
async function pump(reader, writer) {
  const { value, done } = await reader.read();
  if (done) {
    writer.close();
    return;
  }
  await writer.write(value);
  return pump(reader, writer);
}