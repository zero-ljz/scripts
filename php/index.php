<?php

function curl($url, $method = 'GET', $headers = [], $data = '') {
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

function index($request)
{
  if ($request["method"] == "POST") {
  } else {
    header("Content-Type: text/html; charset=UTF-8");

    // 获取所有定义的函数
    $allFunctions = get_defined_functions();

    // 获取自定义函数的名称
    $customFunctions = array_filter($allFunctions["user"], function (
      $functionName
    ) {
      $reflection = new ReflectionFunction($functionName);
      return $reflection->getFileName() === __FILE__;
    });

    $content = "<ul>";
    // 打印自定义函数的名称
    foreach ($customFunctions as $functionName) {
      $content .=
        '<li><a href="?' . $functionName . '">' . $functionName . "</a></li>";
    }
    $content .= "</ul>";

    return html("首页", $content);
  }
}

function get_info($request)
{
  header("Content-Type: text/plain; charset=UTF-8");
  return print_r($request);
}


function bing_wallpaper($request) {
    $response = curl("http://cn.bing.com/HPImageArchive.aspx?format=js&idx=5&n=1");

    $data = json_decode($response, true);

    // 壁纸文件地址
    $bgUri = $data['images'][0]['urlbase'] . "_1920x1080.jpg";
    $bgUrl = "http://cn.bing.com" . $bgUri;

    // 壁纸文件名
    preg_match("/\/th\?id=OHR\.(.*?\.jpg)/", $bgUrl, $arr);
    $bgName = $arr[1];

    // 壁纸说明文字
    $bgText = $data['images'][0]['copyright'];

  header("Content-Type: application/json; charset=UTF-8");
  return json_encode(['url' => $bgUrl, 'name' => $bgName, 'text' => $bgText]);

}

function proxy($request)
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

function test($request)
{
  if ($request["method"] == "POST") {
    return html(
      "测试结果",
      <<<EOD
{$_POST["name"]}
EOD
    );
  } else {
    header("Content-Type: text/html; charset=UTF-8");
    return html(
      "测试",
      <<<EOD
<form method="post">
    <input type="text" name="name" />
    <input type="submit" value="提交" />
</form>

EOD
    );
  }
}

$route = empty($_GET) || $_GET[array_keys($_GET)[0]] ? "index" : array_keys($_GET)[0];
echo call_user_func($route, [
  "method" => $_SERVER["REQUEST_METHOD"],
  "route" => $route,
  "query" => array_slice($_GET, 1)
]);

