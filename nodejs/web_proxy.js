// 未完成

const http = require('http');
const url = require('url');
const axios = require('axios');

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const queryParams = new URLSearchParams(parsedUrl.query).toString();
  
  let newUrl = parsedUrl.pathname.slice(1);
  if (queryParams) {
    newUrl += '?' + queryParams;
  }

  if (newUrl) {
    try {
      // 发起代理请求使用 axios
      const axiosResponse = await axios({
        method: req.method,
        url: newUrl,
        headers: {
          ...req.headers,
          // 要删除的请求头字段
          Host: undefined,
          'Accept-Encoding': undefined,
        },
        maxRedirects: 0, // 不要自动重定向
      });

      // 处理代理地址返回的响应头
      const responseHeaders = {
        ...axiosResponse.headers,
        'Access-Control-Allow-Origin': '*', // 允许所有来源访问，可以根据需求进行修改
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      };

      if (axiosResponse.status >= 301 && axiosResponse.status <= 308) {
        // 遇到重定向时重定向到代理地址
        const redirectLocation = axiosResponse.headers.location;
        if (redirectLocation) {
          responseHeaders.Location = parsedUrl.protocol + '//' + parsedUrl.host + '/' + redirectLocation;
        }
      }

      if (axiosResponse.headers['content-length'] && parseInt(axiosResponse.headers['content-length']) > 1048576) {
        console.log('大于1MB');

        // 边收边传
        const { data } = axiosResponse;
        res.writeHead(axiosResponse.status, responseHeaders);
        res.write(data);
        res.end();
      } else {
        // 直接返回响应内容
        res.writeHead(axiosResponse.status, responseHeaders);
        res.end(axiosResponse.data);
      }
    } catch (error) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end(`Error occurred: ${error}`);
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
    `;

    res.writeHead(200, { 'Content-Type': 'text/html;charset=UTF-8' });
    res.end(html);
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
