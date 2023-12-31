#!/bin/bash

# sudo bash ./init_ubuntu.sh


echo -e "\n\n\n 更新APT包索引"
apt update

base_url=

echo "是否需要代理url？ (y)"
read -t 10 answer
if [ "$answer" = "y" ]; then
base_url=http://47.87.214.106:666/php-proxy/index.php?q=
fi


echo -e "\n\n\n------------------------------------------------------------"






# 安装X Window系统
#apt install xorg
# 安装桌面环境
# apt install xfce4

# 安装vnc服务器
# apt install tigervnc-standalone-server tigervnc-common
# vncpasswd
# vncserver
















exit 0


























echo -e "\n\n\n------------------------------安装 Nginx------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# echo -e "\n\n\n 更新APT包索引"
# apt update
# echo -e "\n\n\n 安装必备组件"
# apt -y install curl gnupg2 ca-certificates lsb-release ubuntu-keyring
# echo -e "\n\n\n 导入官方nginx签名密钥，以便apt可以验证软件包真实性。 获取密钥："
# curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor  | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
# echo -e "\n\n\n 验证下载的文件是否包含正确的密钥："
# gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
# echo -e "\n\n\n 为稳定的nginx软件包设置apt存储库"
# echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
# # echo -e "\n\n\n 设置存储库固定以优先选择我们的包 分发提供的"
# # echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n"  | tee /etc/apt/preferences.d/99nginx

echo -e "\n\n\n 更新APT包索引"
apt update
echo -e "\n\n\n 安装 Nginx"
apt -y install nginx

#echo -e "\n\n\n 选择conf.d为子配置文件夹，将sites-enabled注释掉，这样conf.d中的配置才会生效"
#find '/etc/nginx/nginx.conf' | xargs perl -pi -e 's|include /etc/nginx/sites-enabled/\*;|#include /etc/nginx/sites-enabled/*;|g'

systemctl enable nginx
systemctl restart nginx
fi


echo -e "\n\n\n------------------------------安装 PHP------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
echo -e "\n\n\n安装 php7.4-fpm"
apt -y install php7.4-fpm
echo -e "\n\n\n 安装 wordpress 所需扩展"
apt -y install php-json php7.4-mysql php-curl php7.4-xml php7.4-common php-imagick php-mbstring openssl php-xml php-zip
systemctl enable php7.4-fpm
systemctl start php7.4-fpm

echo -e "\n\n\n 配置 Nginx"
rm /etc/nginx/sites-enabled/default
touch /etc/nginx/sites-enabled/default
cat>/etc/nginx/sites-enabled/default<<EOF
##
# 在大多数情况下，管理员会从站点中删除这个文件，并将它作为站点中可用的参考，在那里nginx打包团队将继续更新它。
#
# 该文件将自动加载其他应用程序(如Drupal或Wordpress)提供的配置文件。这些应用程序将在具有该包名称的路径下可用，例如/drupal8。
#
# 请参见/usr/share/doc/nginx-doc/examples/获取更详细的示例。
##

# Default server configuration
#
server {
  listen 80 default_server;
  # 监听ipv6
  listen [::]:80 default_server;

  root /var/www/html;

  # 如果使用PHP，则将index.php添加到列表中
  index index.php index.html index.htm index.nginx-debian.html;

  server_name _;

  #location / {
    # 首先尝试将请求作为文件，然后作为目录，然后退回到显示404。
  #  try_files $uri $uri/ =404;
  #}

  # 传递PHP脚本到FastCGI服务器
  #
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
  #
  # # With php-fpm (or other unix sockets):
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
  # # With php-cgi (or other tcp sockets):
  #  fastcgi_pass 127.0.0.1:9000;
  }

  # 如果Apache的根文件与nginx的根文件一致，则拒绝访问。htaccess文件
  #
  #location ~ /\.ht {
  # deny all;
  #}
}
EOF
touch /var/www/html/phpinfo.php
cat>/var/www/html/phpinfo.php<<EOF
<?php
echo phpinfo();
?>
EOF


echo -e "\n\n\n 创建示例站点"
domain_name=example.ljz.one
site_root_dir=/var/www/${domain_name}
mkdir ${site_root_dir}
chmod -R 777 ${site_root_dir}
touch /etc/nginx/sites-available/${domain_name}
cat>/etc/nginx/sites-available/${domain_name}<<EOF
server {
  # 创建证书和通过域名访问需要监听80
  #listen 80;
  #listen [::]:80;
  listen 666;

  # listen 443 ssl;
  # #/var/ssl/example.ljz.one.chained.crt;
  # ssl_certificate ${DOMAIN_CHAINED_CRT};
  # # /var/ssl/example.ljz.one.key;
  # ssl_certificate_key ${DOMAIN_KEY};
  # ssl_session_timeout 5m;
  # ssl_protocols TLSv1.2 TLSv1.3; 
  # ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE; 
  # ssl_prefer_server_ciphers on;

  root ${site_root_dir};

  # 如果使用PHP，则将index.php添加到列表中
  index index.php index.html index.htm default.php index.nginx-debian.html;

  server_name ${domain_name};

  # 传递PHP脚本到FastCGI服务器
  #
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
  #
  # # With php-fpm (or other unix sockets):
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
  }

}

EOF
ln -s /etc/nginx/sites-available/${domain_name} /etc/nginx/sites-enabled/${domain_name}

touch ${site_root_dir}/default.php
cat>${site_root_dir}/default.php<<EOF
<?php
echo "网站创建成功";

?>
EOF




systemctl restart nginx



wget -O ${site_root_dir}/php-proxy.zip ${base_url}https://www.php-proxy.com/download/php-proxy.zip
unzip -d ${site_root_dir}/php-proxy/ ${site_root_dir}/php-proxy.zip
sed -i "s/config\['app_key'\] = ''/config['app_key'] = '1'/g" ${site_root_dir}/php-proxy/config.php
# 替换源码去除php-proxy的url参数加解密功能
# 进行普通字符串替换， -r 参数可以支持正则
sed -i 's/function url_encrypt($url, $key = false){/function url_encrypt($url, $key = false){return urlencode($url);/g' ${site_root_dir}/php-proxy/vendor/athlon1600/php-proxy/src/helpers.php
sed -i 's/function url_decrypt($url, $key = false){/function url_decrypt($url, $key = false){return urldecode($url);/g' ${site_root_dir}/php-proxy/vendor/athlon1600/php-proxy/src/helpers.php

wget -O ${site_root_dir}/miniProxy.php ${base_url}https://raw.githubusercontent.com/joshdick/miniProxy/master/miniProxy.php

wget -O ${site_root_dir}/adminer.php ${base_url}https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

wget -O ${site_root_dir}/tinyfilemanager.php ${base_url}https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
echo -e "\n\n\n 访问${domain_name}/tinyfilemanager.php 使用账户admin密码admin@123上传文件"

fi



echo -e "\n\n\n------------------------------安装 Cloudreve 网盘------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
wget -O cloudreve_3.7.1_linux_amd64.tar.gz ${base_url}https://github.com/cloudreve/Cloudreve/releases/download/3.7.1/cloudreve_3.7.1_linux_amd64.tar.gz
tar -xzf cloudreve_3.7.1_linux_amd64.tar.gz
mkdir /usr/local/cloudreve/
mv ./cloudreve /usr/local/cloudreve/cloudreve

echo -e "\n\n\n 使用 Nginx 反向代理 Cloudreve 端口到域名"
domain_name=cloud.ljz.one
touch /etc/nginx/conf.d/${domain_name}.conf
cat>/etc/nginx/conf.d/${domain_name}.conf<<EOF
server {
    server_name ${domain_name};
    listen 80;

    location / {
        proxy_pass_header Server;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:5212;
    }
}
EOF
systemctl daemon-reload
systemctl restart nginx

echo -e "\n\n\n 使用 Supervisor 守护 Cloudreve 进程"

touch /etc/supervisor/relative/directory/cloudreve.ini
cat>/etc/supervisor/relative/directory/cloudreve.ini<<EOF
[program:cloudreve]
directory=/usr/local/cloudreve/
command=/usr/local/cloudreve/cloudreve
autostart=true
autorestart=true
stderr_logfile=/var/log/cloudreve.err
stdout_logfile=/var/log/cloudreve.log
environment=CODENATION_ENV=prod
EOF

# supervisorctl restart cloudreve

echo -e "\n\n\n 请执行 cd /usr/local/cloudreve & ./cloudreve 来初始化Cloudreve以获得默认账户和密码"
fi

echo -e "\n\n\n------------------------------安装 Gitea------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
wget -O gitea ${base_url}https://dl.gitea.com/gitea/1.19.0/gitea-1.19.0-linux-amd64
chmod +x gitea
gpg --keyserver keys.openpgp.org --recv 7C9E68152594688862D62AF62D9AE806EC1592E2
gpg --verify gitea-1.19.0-linux-amd64.asc gitea-1.19.0-linux-amd64
echo -e "\n\n\n创建用户"
adduser \
   --system \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --group \
   --disabled-password \
   --home /home/git \
   git
echo -e "\n\n\n创建工作路径"
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea
echo -e "\n\n\n复制二进制文件到全局位置"
cp gitea /usr/local/bin/gitea

mkdir /usr/local/bin/data
chmod 777 /usr/local/bin/data
mkdir /usr/local/bin/data/home
chmod 777 /usr/local/bin/data/home
mkdir /usr/local/bin/log
chmod 777 /usr/local/bin/log

echo -e "\n\n\n 使用 systemd 守护 Gitea 进程"
app_name=gitea
touch /etc/systemd/system/${app_name}.service
chmod 755 /etc/systemd/system/${app_name}.service
cat>/etc/systemd/system/${app_name}.service<<EOF
[Unit]
Description = ${app_name}
After = network.target syslog.target
Wants = network.target

[Service]
User=git
Type = simple
ExecStart = /usr/local/bin/gitea web -c /etc/gitea/app.ini
WorkingDirectory=/var/lib/gitea/

[Install]
WantedBy = multi-user.target
EOF
systemctl enable gitea
systemctl restart gitea

echo -e "\n\n\n 使用 Nginx 反向代理 Gitea 端口到域名"
domain_name=gitea.ljz.one
touch /etc/nginx/conf.d/${domain_name}.conf
cat>/etc/nginx/conf.d/${domain_name}.conf<<EOF
server {
    server_name ${domain_name};
    listen 80;

    location / {
        proxy_pass_header Server;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:3000;
    }
}
EOF
systemctl daemon-reload
systemctl restart nginx
fi

echo -e "\n\n\n------------------------------安装 gocron------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
wget -O gocron.tar.gz ${base_url}https://github.com/ouqiang/gocron/releases/download/v1.5.3/gocron-v1.5.3-linux-amd64.tar.gz
tar -xzf gocron.tar.gz
mkdir /usr/local/gocron/
mv gocron-linux-amd64/gocron /usr/local/gocron/gocron

echo -e "\n\n\n 使用 systemd 守护 gocron 进程"
app_name=gocron
touch /etc/systemd/system/${app_name}.service
chmod 755 /etc/systemd/system/${app_name}.service
cat>/etc/systemd/system/${app_name}.service<<EOF
[Unit]
Description = ${app_name}
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/gocron/gocron web
WorkingDirectory=/usr/local/gocron/

[Install]
WantedBy = multi-user.target
EOF
systemctl enable gocron
systemctl restart gocron


echo -e "\n\n\n 使用 Nginx 反向代理 gocron 端口到域名"
domain_name=gocron.ljz.one
touch /etc/nginx/conf.d/${domain_name}.conf
cat>/etc/nginx/conf.d/${domain_name}.conf<<EOF
server {
    server_name ${domain_name};
    listen 80;

    location / {
        proxy_pass_header Server;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:5920;
    }
}
EOF
systemctl daemon-reload
systemctl restart nginx
fi







echo -e "\n\n\n------------------------------安装 Zsh & Oh My Zsh------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ "$answer" = "y" ]; then
apt -y install zsh
echo -e "\n\n\n下载并执行 Oh My Zsh 安装脚本"
#wget -O - ${base_url}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
# bash <(wget -O - ${base_url}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended
# bash -c "$(curl -fsSL ${base_url}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
bash -c "$(wget -O - ${base_url}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi