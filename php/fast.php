<?php

$packages = [
    'https://cn.wordpress.org/latest-zh_CN.zip',
    'https://builds.matomo.org/matomo-latest.zip',
    'https://downloads.joomla.org/cms/joomla3/3-10-6/Joomla_3-10.6-Stable-Full_Package.zip',
    'https://www.drupal.org/download-latest/zip',
    'https://github.com/typecho/typecho/releases/latest/download/typecho.zip',
    'https://gitee.com/Discuz/DiscuzX/attach_files/1477547/download',
    'https://tj.mycodes.net/202011/phpBB-chinese_simplified-3.3.2.zip',
    'https://static.kodcloud.com/update/download/kodbox.1.43.zip',
    'https://download.nextcloud.com/server/releases/latest.zip',
    'https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.zip',
    'https://github.com/netcccyun/pan/archive/refs/tags/5.5.zip'
];

// 获取当前目录路径
$dir = __DIR__;
$targetDir = isset($_POST['target_dir']) ? $_POST['target_dir'] : $dir;
$path = isset($_GET['path']) ? $_GET['path'] : '';

if (!empty($path) && is_dir($path)) {
    $dir = $path;
}

// 处理文件上传
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $uploadFile = $targetDir . '/' . basename($_FILES['file']['name']);
    if (move_uploaded_file($_FILES['file']['tmp_name'], $uploadFile)) {
        echo "文件上传成功！";
    } else {
        echo "文件上传失败！";
    }
}

// 处理远程文件下载
if (isset($_GET['download_url'])) {
    $downloadUrl = $_GET['download_url'];
    $targetFile = $targetDir . '/' . basename($downloadUrl);
    if (copy($downloadUrl, $targetFile)) {
        echo "文件下载成功！";
    } else {
        echo "文件下载失败！";
    }
}

// 处理压缩包解压
if (isset($_GET['extract'])) {
    $archiveFile = $_GET['extract'];
    $extractDir = isset($_POST['extract_dir']) ? $_POST['extract_dir'] : $dir;

    // 检查文件扩展名以确定解压方式
    $extension = pathinfo($archiveFile, PATHINFO_EXTENSION);

    if ($extension === 'zip') {
        // 使用zip扩展解压.zip文件
        $zip = new ZipArchive;
        if ($zip->open($archiveFile) === TRUE) {
            $zip->extractTo($extractDir);
            $zip->close();
            echo "压缩包解压成功！";
        } else {
            echo "压缩包解压失败！";
        }
    } elseif ($extension === 'tar' || $extension === 'gz') {
        // 使用PHP的phar扩展解压.tar和.tar.gz文件
        try {
            $phar = new PharData('phar://' . $archiveFile);
            $phar->extractTo($extractDir, null, true);
            echo "压缩包解压成功！";
        } catch (Exception $e) {
            echo "压缩包解压失败：" . $e->getMessage();
        }
    } else {
        echo "不支持的压缩包格式！";
    }
}

// 执行命令
if (isset($_POST['command'])){
    $command = $_POST['command'];
    $lastLine = exec($command, $output, $exitCode);
    if ($exitCode === 0) {
        $commandResult = implode("\n", $output);
        echo "<pre>" . htmlspecialchars($commandResult, ENT_QUOTES, 'UTF-8') . "</pre>"; // 使用<pre>标签显示文本，保留换行和空格
    } else {
        echo "命令执行失败！";
        echo "退出状态码：$exitCode";
    }
}



// 显示文件和目录列表
$files = scandir($dir);
echo "<h2>文件和目录列表</h2>";
echo "<p>当前目录：$dir</p>";
echo "<ul>";
if ($dir !== __DIR__) {
    $parentDir = dirname($dir);
    echo "<li><a href=\"?path=$parentDir\">上级目录</a></li>";
}
foreach ($files as $file) {
    $filePath = $dir . '/' . $file;
    if ($file !== "." && $file !== "..") {
        if (is_dir($filePath)) {
            echo "<li><a href=\"?path=$filePath\">$file/</a></li>";
        } else {
            echo "<li>$file</li>";
        }
    }
}
echo "</ul>";
?>

<!DOCTYPE html>
<html>
<head>
    <title>网站空间快速助手</title>
</head>
<body>
    <h2>上传文件</h2>
    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="text" name="target_dir" placeholder="目标路径" value="<?php echo $targetDir; ?>">
        <input type="submit" value="上传">
    </form>

    <h2>远程下载文件</h2>
    <form method="GET" action="">
        <input list="popular_urls" name="download_url" placeholder="选择或输入远程文件URL">
        <datalist id="popular_urls">
            <?php
            foreach ($packages as $url) {
                echo "<option value=\"$url\">";
            }
            ?>
        </datalist>
        <input type="text" name="target_dir" placeholder="目标路径" value="<?php echo $targetDir; ?>">
        <input type="submit" value="下载">
    </form>

    <h2>解压压缩包</h2>
    <form method="GET" action="">
       <input list="archive_files" name="extract" placeholder="选择或输入压缩包文件名">
        <datalist id="archive_files">
            <?php
            foreach ($files as $file) {
                $filePath = $dir . '/' . $file;
                $extension = pathinfo($file, PATHINFO_EXTENSION);
                if ($extension === 'zip' || $extension === 'tar' || $extension === 'gz') {
                    echo "<option value=\"$file\">";
                }
            }
            ?>
        </datalist>
        <input type="text" name="extract_dir" placeholder="解压目录" value="<?php echo $dir; ?>">
        <input type="submit" value="解压">
    </form>

    <h2>执行命令</h2>
    <form method="POST" action="">
        <input type="text" name="command" placeholder="命令">
        <input type="submit" value="执行">
    </form>

    <h2>跳转目录</h2>
    <form method="GET" action="">
        <input type="text" name="path" placeholder="目录路径">
        <input type="submit" value="显示目录内容">
    </form>
</body>
</html>
