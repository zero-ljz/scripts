<?php
/**
 * 文件快速上传解压工具(单文件)
 * QQ：2267719005
 * 网站：3ghh.cn
 * 日期：2017.10.26
 * 版本：1.2
 * ©浩瀚星空
 */

header("Content-Type: text/html; charset=UTF-8");

// 定义常量
define('BASE_URL', 'http://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
define('ZIP_FILES', [
    "tinyfilemanager.php" => "https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php",
    "adminer-4.8.0.php" => "https://github.com/vrana/adminer/releases/download/v4.8.0/adminer-4.8.0.php",
    "爱特文件管理器" => "https://aite.xyz/product/fileadmin.zip",
    "phpMyAdmin" => "https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.zip",
    "WordPress" => "https://cn.wordpress.org/latest-zh_CN.zip",
    "phpBB 3.3.2" => "https://tj.mycodes.net/202011/phpBB-chinese_simplified-3.3.2.zip",
    "Typecho 1.1" => "http://typecho.org/downloads/1.1-17.10.30-release.tar.gz",
    "树洞外链 2.4.6" => "https://codeload.github.com/HFO4/shudong-share/zip/master"
]);

// 设置错误报告级别
error_reporting(E_ALL);

// 处理密码设置和重设
if (isset($_GET['pass'])) {
    $password = $_GET['pass'];
    $passwordFile = 'file_op_pass.php';

    if ($_GET['action'] === 'cs') {
        if (file_exists($passwordFile)) {
            unlink($passwordFile);
        }
        header('Location: ' . BASE_URL);
        exit;
    }

    if (!file_exists($passwordFile) && $password !== '') {
        $passwordContent = "<?php \$pass = '{$password}'; ?>";
        if (file_put_contents($passwordFile, $passwordContent)) {
            header('Location: ' . BASE_URL . '?pass=' . $password);
            exit;
        }
    } elseif (file_exists($passwordFile)) {
        include($passwordFile);
        if ($_GET['pass'] !== $pass) {
            echo '<form action="' . $_SERVER['PHP_SELF'] . '" method="get"><input type="text" name="pass" value="" ><input type="submit" class="enter" value="登录"></form>';
            exit;
        }
    }
} else {
    echo '<form action="' . $_SERVER['PHP_SELF'] . '" method="get"><input type="text" name="pass" value="" ><input type="submit" value="设置密码" class="enter"></form>';
    exit;
}

// 输出页面头部
echo '
<!DOCTYPE html>
<html>
<head>
<title>文件快速上传解压工具</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
<div id="wrapper">
<h3><a href="index.php">网站首页</a> <a href="' . BASE_URL . '?pass=' . $pass . '">程序首页</a> <a href="?pass=' . $pass . '&action=cs">重设密码</a></h3>
<div class="content">
';

// 处理文件上传和解压
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['file'])) {
        handleLocalFileUpload();
    } elseif (isset($_POST['extract'])) {
        handleZipExtraction();
    } elseif (isset($_POST['upload'])) {
        handleRemoteFileUpload();
    }
}

// 输出当前路径
echo '<hr/>当前路径<br/><div style="font-size:12px;">' . dirname(__FILE__) . '</div>';

// 处理本地文件上传
echo '<hr/>本地文件上传<br/>';
echo '
<form enctype="multipart/form-data" action="" method="post">
    <label for="file"></label>
    <input type="file" name="file" /><br/>
    <input type="text" name="lj" placeholder="保存路径以斜杠结束可为空"/><br/>
    <input type="hidden" name="pass" value="' .$pass . '">
    <input type="submit" name="submit" value="上传" class="enter" />
</form>
';

// 处理文件解压
echo '<hr/>文件快速解压<br/>';
echo '
<form action="" method="post">
    <select name="zip">
        <option value="" selected>请选择ZIP文件</option>';

foreach (ZIP_FILES as $filename => $url) {
    echo '<option value="' . $url . '">' . $filename . '</option>';
}

echo '
    </select><br/>
    <input type="hidden" name="pass" value="' . $pass . '">
    <input type="text" name="root" value="./"><br/>
    <input type="submit" name="extract" value="解压" class="enter"/>
</form>
';

// 处理远程文件上传
echo '<hr/>远程文件上传<br/>';
echo '
<form action="" method="post">
    <input type="text" name="upfile" value="http://"/><br/>
    <input type="text" name="upname" placeholder="留空则用原文件名"/><br/>
    <input type="text" name="lj" placeholder="保存路径以斜杠结束可为空"/><br/>
    <select name="yq">
        <option value ="1">file_get_contents</option>
        <option value ="2">copy</option>
        <option value ="3">curl_init</option>
        <option value ="4">fopen</option>
    </select>
    <input type="submit" name="upload" value="上传" class="enter"/>
</form>
';

// 输出页面底部
echo '</div></div></body></html>';

/**
 * 处理本地文件上传
 */
function handleLocalFileUpload()
{
    $file = $_FILES['file'];
    $filePath = $_POST['lj'] ?? './';

    if (is_dir($filePath) !== true) {
        mkdir($filePath, 0664, true);
    }

    if ($file['error'] === 0) {
        $destination = $filePath . $file['name'];
        if (move_uploaded_file($file['tmp_name'], $destination)) {
            echo $file['name'] . '<br/>上传成功！';
        } else {
            echo $file['name'] . '上传失败！';
        }
    } else {
        echo '文件上传发生错误：' . $file['error'];
    }
}

/**
 * 处理文件解压
 */
function handleZipExtraction()
{
    $zipFile = $_POST['zip'];
    $extractPath = $_POST['root'];
    $result = zipExtract($zipFile, $extractPath);

    echo '文件解压－解压结果<br/>';
    if ($result) {
        echo '解压成功';
    } else {
        echo '解压失败，尝试其他方法...';
        // 在此可以尝试其他的解压方法
    }
}

/**
 * 处理远程文件上传
 */
function handleRemoteFileUpload()
{
    $upfile = $_POST['upfile'];
    $upname = $_POST['upname'] !== '' ? $_POST['upname'] : basename(rawurldecode($upfile));
    $lj = $_POST['lj'] !== '' ? $_POST['lj'] : './';
    $yq = $_POST['yq'];

    echo '文件上传－上传结果<br/>';
    switch ($yq) {
        case '1':
            if (file_put_contents($lj . $upname, file_get_contents($upfile))) {
                echo 'file_get_contents：文件 ' . $upname . '上传成功。';
            } else {
                echo 'file_get_contents：文件 ' . $upname . '上传失败。';
            }
            break;
        case '2':
            if (copy($upfile, $lj . $upname)) {
                echo 'copy：文件 ' . $upname . '上传成功。';
            } else {
                echo 'copy：文件 ' . $upname . '上传失败。';
            }
            break;
        case '3':
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $upfile);
            curl_setopt($ch, CURLOPT_TIMEOUT, 60);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            $temp = curl_exec($ch);
            if (file_put_contents($lj . $upname, $temp) && !curl_error($ch)) {
                echo 'curl：文件 ' . $upname . '上传成功。';
            } else {
                echo 'curl：文件 ' . $upname . '上传失败。';
            }
            curl_close($ch);
            break;
        case '4':
            if (get_file($upfile, $lj, $upname)) {
                echo 'fopen：文件 ' . $upname . '上传成功。';
            } else {
                echo 'fopen：文件 ' . $upname . '上传失败。';
            }
            break;
        default:
            echo '无效的上传方法';
    }
}

/**
 * 服务器内置的解压方法
 */
function zipExtract($src, $dest)
{
    $zip = new ZipArchive();
    if ($zip->open($src) === true) {
        $zip->extractTo($dest);
        $zip->close();
        return true;
    }
    return false;
}

/**
 * 文件下载函数
 */
function get_file($url, $folder = "./", $newfname)
{
    set_time_limit(24 * 60 * 60); // 设置超时时间
    $destination_folder = $folder . ''; // 文件下载保存目录，默认为当前文件目录
    if (!is_dir($destination_folder)) { // 判断目录是否存在   
        mkdirs($destination_folder); // 如果没有就建立目录
    }
    $newfnamea = $destination_folder . $newfname; // 取得文件的名称   
    $file = fopen($url, "rb"); // 远程下载文件，二进制模式
    if ($file) { // 如果下载成功   
        $newf = fopen($newfnamea, "wb"); // 远在文件文件
        if ($newf) { // 如果文件保存成功   
            while (!feof($file)) { // 判断附件写入是否完整   
                fwrite($newf, fread($file, 1024 * 8), 1024 * 8); // 没有写完就继续   
            }
        }
    }
    if ($file) {
        fclose($file); // 关闭远程文件   
    }
    if ($newf) {
        fclose($newf); // 关闭本地文件   
    }
    return true;
}

/**
 * 递归创建目录
 */
function mkdirs($path, $mode = 0755)
{
    if (!is_dir($path)) {
        mkdirs(dirname($path), $mode);
        mkdir($path, $mode);
    }
    return true;
}
