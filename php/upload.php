<?php
/***
 * 文件快速上传解压工具(单文件)
 * QQ：2267719005
 * 网站：3ghh.cn
 * 日期：2017.10.26
 * 版本：1.2
 * ©浩瀚星空
 ***/
header("Content-Type: text/html; charset=UTF-8");
ignore_user_abort(true);
error_reporting(0);

$uz = array(
    "tinyfilemanager.php|https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php"
,
    "adminer-4.8.0.php|https://github.com/vrana/adminer/releases/download/v4.8.0/adminer-4.8.0.php"
,
    "爱特文件管理器|https://aite.xyz/product/fileadmin.zip"
,
    "phpMyAdmin|https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.zip"
,
    "WordPress|https://cn.wordpress.org/latest-zh_CN.zip"
,
    "phpBB 3.3.2|https://tj.mycodes.net/202011/phpBB-chinese_simplified-3.3.2.zip"
,
    "Typecho 1.1|http://typecho.org/downloads/1.1-17.10.30-release.tar.gz"
,
    "树洞外链 2.4.6|https://codeload.github.com/HFO4/shudong-share/zip/master"
);

echo '
<!DOCTYPE html>
<html>
<head>
<title>文件快速上传解压工具</title>
<meta name="viewport" content="width=device-width; initial-scale=1.0; minimum-scale=1.0; maximum-scale=2.0; user-scalable=yes" >
<style type="text/css">
a {
	text-decoration: none;
	color: #0079ff;
	-webkit-tap-highlight-color: transparent;
}

body {
	margin: 0 auto;
}

#wrapper {
	width: 350px;
	border: 1px solid #337ab7;
	margin: 0 auto;
	border-top-left-radius: 3px;
	border-top-right-radius: 3px;
	background: #efeff5;
	text-align: center;
	color: green;
	box-sizing: border-box;
}

h3 {
	margin: 0;
	padding: 5px 0;
	display: block;
	color: #fff;
	background: #337ab7;
	text-align: center;
	width: 100%;
	margin-bottom: 10px;
}

h3 a {
	color: #fff;
}

h3 a:hover{
   color:#eee;
}

input,select {
	width: 100%;
	padding: 3px 0;
	margin: 0;
	margin-bottom: 2px;
	box-sizing: border-box;
	outline: none;
    -webkit-tap-highlight-color: transparent;
    transition: padding, margin 0.2s linear;
}

input[type=submit] {
	background: #3385ff;
	border: 1px solid #3385ff;
	border-radius: 2px;
	color: #fff;
	margin-top: 5px;
	cursor: pointer;
}

input[type=submit]:hover {
	background: #8abaf0;
	border: 1px solid #8abaf0;
}

.content{
padding: 5px 10px;
box-sizing: border-box;
}
</style>
</head>
<body>
';

function job_check($f, $l = '1')
{//类和函数检测
    if ($l == '0') {
        if (!class_exists($f)) {
            echo "{$f}";
            echo '<font color="red">类不支持，部分功能无法使用</font><br/>';
        }
    } else {
        if (!function_exists($f)) {
            echo "{$f}";
            echo '<font color="red">函数不支持，部分功能无法使用</font><br/>';
        }
    }

}

function zipExtract($src, $dest)
{//服务器内置的解压类
    $zip = new ZipArchive();
    if ($zip->open($src) === true) {
        $zip->extractTo($dest);
        $zip->close();
        return true;
    }
    return false;
}


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
        if ($newf) // 如果文件保存成功   
            while (!feof($file)) { // 判断附件写入是否完整   
                fwrite($newf, fread($file, 1024 * 8), 1024 * 8); // 没有写完就继续   
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

function mkdirs($path, $mode = "0755")
{
    if (!is_dir($path)) { // 判断目录是否存在   
        mkdirs(dirname($path), $mode); // 循环建立目录
        mkdir($path, $mode); // 建立目录   
    }
    return true;
}

echo '<div id="wrapper">';


if (file_exists('file_op_pass.php')) {
    include('file_op_pass.php');
    if ($_GET['pass'] != $pass) {
        echo '<form action="' . $_SERVER['PHP_SELF'] . '" method="get"><input type="text" name="pass" value="" ><input type="submit" class="enter" value="登录"></form>';
        exit;
    }
} else {
    //函数检测
    job_check("ignore_user_abort");
    job_check("curl_init");
    job_check("file_get_contents");
    job_check("ZipArchive", "0");
    job_check("copy");
    job_check("fopen");
    echo '<form action="' . $_SERVER['PHP_SELF'] . '" method="get"><input type="text" name="pass" value="" ><input type="submit" value="设置密码" class="enter"></form>';
    if (isset($_GET['pass'])) {
        $co = '<?php $pass="' . $_GET['pass'] . '"; ?>';
        if (file_put_contents('file_op_pass.php', $co)) {
            header("Location:{$_SERVER['PHP_SELF']}?pass={$_GET['pass']}");
        }
    }
    exit;
}

$lo = $_GET['pass'];

if (isset($_GET["ml"])) {
    header("Location:{$_GET['ml']}");
    exit;
}

if (isset($_GET["action"]) == 'cs') {
    unlink('file_op_pass.php');
    header('Location:' . $_SERVER['PHP_SELF'] . '');
    exit;
}


echo '<h3><a href="index.php">网站首页</a> <a href="' . $_SERVER['PHP_SELF'] . '?pass=' . $lo . '">程序首页</a> <a href="?pass=' . $lo . '&action=cs">重设密码</a></h3>';
echo '<div class="content"><form method="get" action=""><input type="hidden" name="pass" value="' . $lo . '"><input type="text" name="ml" value="fileadmin"/><input type="submit" value="快速访问" class="enter"/></form>';
echo '<hr/>当前路径<br/>';
echo '<div style="font-size:12px;">';
echo dirname(__FILE__);
echo '</div>';


echo '<hr/>本地文件上传<br/>';
if (!isset($_FILES['file']['name'])) {
    echo '
	<form enctype="multipart/form-data" action="" method="post">
<label for="file"></label>
<input type="file" name="file" /><br/>
<input type="text" name="lj" placeholder="保存路径以斜杠结束可为空"/><br/>
<input type="hidden" name="pass" value="' . $lo . '">
<input type="submit" name="submit" value="上传" class="enter" />
</form>
';
} else {
//文件存储路径
    $file_path = $_POST['lj'];
//664权限为文件属主和属组用户可读和写，其他用户只读。
    if (is_dir($file_path) != TRUE) mkdir($file_path, 0664);

    if (empty($_FILES) === false) {
//判断检查
        if ($_FILES["file"]["error"] > 0) {
            exit("文件上传发生错误：{$_FILES['file']['error']}");
        }
//将文件移动到存储目录下
        move_uploaded_file($_FILES["file"]["tmp_name"], "$file_path" . $_FILES["file"]["name"]);

        echo $_FILES["file"]["name"] . "<br/>上传成功！";
    } else {
        echo "无正确的文件上传";
    }
}


if (isset($_POST['extract'])) {

    echo '文件解压－解压结果<br/>';

    if (zipExtract($_POST['zip'], $_POST['root'])) {
        echo '解压成功';
    } else {
        echo '解压失败，尝试其他方法。。。';


        if (isset($_POST['extract'])) {

            if (!file_exists('pclzip.lib.php')) {
                echo "<br/>";
                $pclzip = "http://3ghh.cn/usr/uploads/2017/08/197032471.zip";
                if (!file_put_contents('pclzip.lib.php', file_get_contents($pclzip))) {
                    echo 'pclzip.lib.php下载失败<br/>';
                } else {
                    echo 'pclzip.lib.php下载成功<br/>';
                }
            }
            include 'pclzip.lib.php';
            $zip = $_POST['zip'];
            $archive = new PclZip($zip);
            if ($archive->extract(PCLZIP_OPT_PATH, $_POST['root']) == 0) {
                echo '解压失败，错误信息: <br/>' . $archive->errorInfo(true) . '';
            } else {
                echo '文件 ' . $zip . ' 解压成功!';
            }
            @unlink('pclzip.lib.php');
        }


    }

}

echo '<hr/>文件快速解压<br/>
<form action="" method="post"><select name="zip">
<option value="" selected>请选择ZIP文件</option>';
$fdir = opendir('./');
while ($file = readdir($fdir)) {
    if (!is_file($file))
        continue;
    if (preg_match('/\.zip$/mis', $file)) {
        echo '<option value="' . $file . '">' . $file . '</option>';
    }
}
echo '</select><br/><input type="hidden" name="pass" value="' . $lo . '">
<input type="text" name="root" value="./">
<br/><input type="submit" name="extract" value="解压" class="enter"/></form>
';


if (isset($_POST['upload']) and $_POST['yq'] == '1') {
    echo '文件上传－上传结果<br/>';
    if ($_POST['lj'] == '')
        $lj = './';
    else
        $lj = $_POST['lj'];
    if ($_POST['upname'] !== '') {
        if (file_put_contents($lj . $_POST['upname'], file_get_contents($_POST['upfile']))) {
            echo 'file_get_contents：文件 ' . $_POST['upname'] . '上传成功。';
        } else {
            echo 'file_get_contents：文件 ' . $_POST['upname'] . ' 上传失败。';
        }
    } else {
        $RemoteFilee = rawurldecode($_POST["upfile"]);
        if (file_put_contents($lj . basename($RemoteFilee), file_get_contents($_POST['upfile']))) {
            echo 'file_get_contents：文件 ' . basename($RemoteFilee) . ' 上传成功。';
        } else {
            echo 'file_get_contents：文件 ' . basename($RemoteFilee) . '上传失败。';
        }
    }
}


if (isset($_POST['upload']) and $_POST['yq'] == '2') {

    echo '文件上传－上传结果<br/>';

    if ($_POST['lj'] == '')
        $lj = './';
    else
        $lj = $_POST['lj'];

    if ($_POST['upname'] !== '') {
        if (copy($_POST['upfile'], $lj . $_POST['upname'])) {
            echo 'copy：文件 ' . $_POST['upname'] . '上传成功。';
        } else {
            echo 'copy：文件 ' . $_POST['upname'] . ' 上传失败。';
        }
    } else {
        $RemoteFilee = rawurldecode($_POST["upfile"]);
        if (copy($_POST['upfile'], $lj . basename($RemoteFilee))) {
            echo 'copy：文件 ' . basename($RemoteFilee) . ' 上传成功。';
        } else {
            echo 'copy：文件 ' . basename($RemoteFilee) . '上传失败。';
        }
    }
}


if (isset($_POST['upload']) and $_POST['yq'] == '3') {

    echo '文件上传－上传结果<br/>';

    if ($_POST['lj'] == '')
        $lj = './';
    else
        $lj = $_POST['lj'];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $_POST['upfile']);
    curl_setopt($ch, CURLOPT_TIMEOUT, 60);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
    $temp = curl_exec($ch);

    if ($_POST['upname'] !== '') {


        if (@file_put_contents($lj . $_POST['upname'], $temp) && !curl_error($ch)) {
            echo 'curl：文件 ' . $_POST['upname'] . '上传成功。';
        } else {
            echo 'curl：文件 ' . $_POST['upname'] . ' 上传失败。';
        }
    } else {
        $RemoteFilee = rawurldecode($_POST["upfile"]);
        if (@file_put_contents($lj . basename($RemoteFilee), $temp) && !curl_error($ch)) {
            echo 'curl：文件 ' . basename($RemoteFilee) . ' 上传成功。';
        } else {
            echo 'curl：文件 ' . basename($RemoteFilee) . '上传失败。';
        }
    }
    curl_close($ch);
}

if (isset($_POST['upload']) and $_POST['yq'] == '4') {

    echo '文件上传－上传结果<br/>';

    if ($_POST['lj'] == '') {
        $lj = './';
    } else {
        $lj = "./{$_POST['lj']}";
    }

    if ($_POST['upname'] !== '') {

        if (get_file($_POST['upfile'], $lj, $_POST['upname'])) {
            echo 'fopen：文件 ' . $_POST['upname'] . '上传成功。';
        } else {
            echo 'fopen：文件 ' . $_POST['upname'] . ' 上传失败。';
        }
    } else {
        $RemoteFilee = rawurldecode($_POST["upfile"]);
        if (get_file($_POST['upfile'], $lj, basename($RemoteFilee))) {
            echo 'fopen：文件 ' . basename($RemoteFilee) . ' 上传成功。';
        } else {
            echo 'fopen：文件 ' . basename($RemoteFilee) . '上传失败。';
        }
    }
}


echo '<hr/>远程文件上传<br/>
<form action="" method="post">
<input type="text" name="upfile" value="http://"/><br/>
<input type="text" name="upname" placeholder="留空则用原文件名"/><br/>
<input type="text" name="lj" placeholder="保存路径以斜杠结束可为空"/><br/>
<select name="yq">
  <option value ="1">file_get_contents</option>
  <option value ="2">copy</option>
     <option value ="3">curl_init</option>
   <option value ="4">fopen</option>
</select> <input type="submit" name="upload" value="上传" class="enter"/>
</form>';


if (!isset($_GET['zip'])) {

    $ymdz = "http://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
    echo '<hr/><b>自动上传解压</b><br/>';
    echo '<form method="get" action="".$ymdz.""><select name="zip">';
    foreach ($uz as $va) {
        $z = explode('|', $va);
        echo "<option value='{$z[1]}'>{$z[0]}</option>";
    }
    echo '</select> <br/><input type="submit" value="一键远程上传并解压" class="enter"/><input type="hidden" name="pass" value="' . $lo . '"><input type="submit" name="down" value="下载ZIP包" class="enter"/></form>';
    echo '<hr/>Powered By <a href="http://3ghh.cn">Xink</a> 1.2！';
    exit;
}
if ($_GET["down"]) {
    echo "文件地址:";
    $zipp = $_GET["zip"];
    echo '<br/><a href="' . $zipp . '">' . $zipp . '</a>';
    exit;
}
$RemoteFile = rawurldecode($_GET["zip"]);
$ZipFile = "Archive.zip";
$Dir = "./";


if (get_file($_GET["zip"], $Dir, $ZipFile)) {
//if (copy($RemoteFile, $ZipFile)) {
    echo "已下载文件 <br/><b>" . $RemoteFile . "";

    if (zipExtract($ZipFile, $Dir)) {
        echo "<br/><b>" . basename($RemoteFile) . "";
        echo "已解压成功<br/>已删除程序安装包 <a href='index.php'>进入首页</a>！</b>";
        if (file_exists($ZipFile)) {
            unlink($ZipFile);
        }
    } else {
        echo "无法解压该文件 <br/><b>" . $ZipFile . ".</b>";
    }
} else {
    echo "无法复制文件 <br/><b>" . $RemoteFile . "";
}

echo '</div></div></body></html>';