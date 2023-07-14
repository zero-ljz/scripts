<?php

function curl($url, $method = "GET", $headers = [], $data = "")
{
  $ch = curl_init($url);

  // 设置cURL选项
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
  curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);

  // 执行请求并获取响应
  $response = curl_exec($ch);

  // 检查是否有错误发生
  if (curl_errno($ch)) {
    $error_msg = curl_error($ch);
    // 处理错误
  }

  // 关闭cURL资源
  curl_close($ch);

  return $response;
}

function bing_wallpaper($itx = 1)
{
  $response = curl(
    "http://cn.bing.com/HPImageArchive.aspx?format=js&idx={$itx}&n=1"
  );

  $data = json_decode($response, true);

  // 壁纸文件地址
  $bgUri = $data["images"][0]["urlbase"] . "_1920x1080.jpg";
  $bgUrl = "http://cn.bing.com" . $bgUri;

  // 壁纸文件名
  preg_match("/\/th\?id=OHR\.(.*?\.jpg)/", $bgUrl, $arr);
  $bgName = $arr[1];

  // 壁纸说明文字
  $bgText = $data["images"][0]["copyright"];

  return ["url" => $bgUrl, "name" => $bgName, "text" => $bgText];
}

function html($title, $main)
{
  return <<<EOD
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
     <title>{$title}</title>
  </head>
  <body><main>{$main}</main></body>
</html>
EOD;
}

class Router
{
  private $request;

  public function __construct($request)
  {
    $this->request = $request;
  }

  public function handleRequest()
  {
    $methodName = $this->request["route"];

    if (method_exists($this, $methodName)) {
      return $this->$methodName();
    } else {
      http_response_code(404);
      echo "Not Found";
      exit();
    }
  }

  function index()
  {
    $content = "<ul>";
    $content .= '<li><a href="?echo">echo</a></li>';
    $content .= '<li><a href="?bing_wallpaper_info">bing_wallpaper_info</a></li>';
    $content .= '<li><a href="?bing_wallpaper_image">bing_wallpaper_image</a></li>';
    $content .= '<li><a href="?test">test</a></li>';
    $content .= "</ul>";

    header("Content-Type: text/html; charset=UTF-8");
    return html("Index", $content);
  }

  function echo()
  {
    header("Content-Type: text/plain; charset=UTF-8");
    return print_r($this->request, true);
  }

  function test()
  {
    if ($this->request["method"] === "POST") {
      $name = $_POST["name"] ?? "";
      return html("测试结果", $name);
    } else {
      header("Content-Type: text/html; charset=UTF-8");
      $form = <<<EOD
<form method="post">
    <input type="text" name="name" />
    <input type="submit" value="提交" />
</form>
EOD;
      return html("测试", $form);
    }
  }

  function bing_wallpaper_info()
  {
    $itx = $_GET["itx"] ?? 1;
    header("Content-Type: application/json; charset=UTF-8");
    return json_encode(bing_wallpaper($itx));
  }

  function bing_wallpaper_image()
  {
    $itx = $_GET["itx"] ?? 1;
    Header("Location: " . bing_wallpaper($itx)["url"]);
  }


function proxy()
{
  // 从传入请求中获取目标URL
  $url = $_GET["url"];

  // 创建cURL句柄
  $ch = curl_init();

  // 设置代理请求的URL
  curl_setopt($ch, CURLOPT_URL, $url);

  // 将客户端请求的所有标头发送到目标服务器
  $headers = [];
  foreach (getallheaders() as $key => $value) {
    // 排除不需要转发的标头，可根据需要自行修改
    if (
      $key !== "Host" &&
      $key !== "Content-Length" &&
      $key !== "Content-Type"
    ) {
      $headers[] = "$key: $value";
    }
  }
  curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

  // 不接收目标服务器响应的标头
  curl_setopt($ch, CURLOPT_HEADER, false);

  // 转发请求方法
  curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $_SERVER["REQUEST_METHOD"]);

  // 转发请求主体数据
  $body = file_get_contents("php://input");
  curl_setopt($ch, CURLOPT_POSTFIELDS, $body);

  // 转发请求主体数据边传边接收
  curl_setopt($ch, CURLOPT_READFUNCTION, function ($ch, $fd, $length) use (
    $body
  ) {
    return substr($body, 0, $length);
  });

  // 接收目标服务器响应的主体数据边传边输出
  curl_setopt($ch, CURLOPT_WRITEFUNCTION, function ($ch, $data) {
    // 获取代理URL响应的内容类型
    $contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    // 发送内容类型给客户端
    header("Content-Type: $contentType");

    // 获取目标服务器响应的文件名
    $filename = "";
    $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $header = substr($response, 0, $headerSize);
    preg_match('/filename="([^"]+)"/', $header, $matches);
    if (isset($matches[1])) {
      $filename = $matches[1];
    }

    // 发送文件名给客户端
    header("Content-Disposition: attachment; filename=\"$filename\"");

    echo $data;
    return strlen($data);
  });

  // 执行cURL请求
  curl_exec($ch);

  // 关闭cURL句柄
  curl_close($ch);
}

  function proxy2()
  {
    $url = $this->request["query"]["url"];
    $uri = "";
    $cs = unpack("C*", $url);
    for ($i = 1; $i <= count($cs); $i++) {
      $uri .= $cs[$i] > 127 ? "%" . strtoupper(dechex($cs[$i])) : $url[$i - 1];
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $uri);
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true, //不直接打印结果
      CURLINFO_HEADER_OUT => true, //info中包含请求头
      CURLOPT_FOLLOWLOCATION => true, //跟随重定向
    ]);
    $response = curl_exec($ch);
    $info = curl_getinfo($ch);
    curl_close($ch);

    $contentType = $info["content_type"];
    //$contentDisposition = $info["Content-Disposition"];

    header("Content-Type: " . $contentType);
    //header("Content-Disposition: " . $contentDisposition);

    return $response;
  }
}

$request = [
  "method" => $_SERVER["REQUEST_METHOD"],
  "route" =>
    empty($_GET) || $_GET[array_keys($_GET)[0]]
      ? "index"
      : array_keys($_GET)[0],
  "query" => array_slice($_GET, 1),
];

$router = new Router($request);
echo $router->handleRequest();
