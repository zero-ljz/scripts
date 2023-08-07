<?php
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;

require __DIR__ . '/vendor/autoload.php';

$app = AppFactory::create();

$app->addErrorMiddleware(true, true, true);

$app->get('/', function (Request $request, Response $response) {
    $basePath = '/'; // 根目录路径
    $requestedPath = $request->getQueryParams()['path'] ?? ''; // 获取查询参数中的目录路径

    // 如果路径是 ".."，表示切换到上级目录
    if ($requestedPath === '..') {
        $requestedPath = dirname($requestedPath);
    }

    // 构建完整的目标路径
    $targetPath = realpath($basePath . '/' . $requestedPath);

    // 确保请求的路径在根目录下
    if (strpos($targetPath, $basePath) !== 0) {
        $response->getBody()->write('Invalid directory or path.');
        return $response;
    }

    // 扫描目标目录中的文件和子目录
    $items = scandir($targetPath);
    $items = array_diff($items, ['.', '..']); // 去除 "." 和 ".."

    // 构建目录列表的HTML
    $html = '<ul>';
    // 如果不是根目录，添加链接以返回上级目录
    if ($requestedPath !== '') {
        $parentPath = dirname($requestedPath);
        $html .= '<li><a href="/?path=' . urlencode($parentPath) . '">[上级目录]</a></li>';
    }
    foreach ($items as $item) {
        $itemPath = $requestedPath . '/' . $item;
        $fullItemPath = $basePath . '/' . $itemPath;
        if (is_dir($fullItemPath)) {
            $html .= '<li>[目录] <a href="/?path=' . urlencode($itemPath) . '">' . $item . '</a></li>';
        } else {
            $size = filesize($fullItemPath);
            $formattedSize = formatSizeUnits($size);
            $html .= '<li>[文件] ' . $item . ' (' . $formattedSize . ') <a href="/download?path=' . urlencode($itemPath) . '">下载</a></li>';
        }
    }
    $html .= '</ul>';

    // 在响应中显示目录列表
    $response->getBody()->write($html);

    return $response;
});

// 文件下载路由
$app->get('/download', function (Request $request, Response $response) {
    $basePath = '/'; // 根目录路径
    $filePath = $request->getQueryParams()['path'] ?? '';

    // 构建完整的文件路径
    $fullFilePath = $basePath . '/' . $filePath;

    // 确保请求的文件在根目录下，并且是一个文件
    if (strpos($fullFilePath, $basePath) !== 0 || !is_file($fullFilePath)) {
        $response->getBody()->write('Invalid file path.');
        return $response;
    }

    // 设置响应头以触发下载
    $response = $response->withHeader('Content-Type', 'application/octet-stream');
    $response = $response->withHeader('Content-Disposition', 'attachment; filename="' . basename($fullFilePath) . '"');
    $response->getBody()->write(file_get_contents($fullFilePath));

    return $response;
});

// 格式化文件大小单位函数
function formatSizeUnits($bytes) {
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $index = 0;
    while ($bytes >= 1024 && $index < count($units) - 1) {
        $bytes /= 1024;
        $index++;
    }
    return round($bytes, 2) . ' ' . $units[$index];
}

$app->run();
