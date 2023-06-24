#!/bin/bash


echo -e "\n\n\n更新可用软件包列表"
apt update

echo -e "\n\n\n开启 rc.local"
if [ ! -e "/etc/rc.local" ];then
echo -e "\n\n\n配置 rc.local"
touch /etc/rc.local
chmod 755 /etc/rc.local

cat>/etc/rc.local<<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

EOF

systemctl enable rc-local
fi


echo -e "\n\n\n安装 Git"
apt -y install git
echo -e "\n\n\n配置 Git"
git config --global user.name "ljz"
git config --global user.email "2267719005@qq.com"


echo -e "\n\n\n安装 Micro 编辑器"
apt -y install micro


echo -e "\n\n\n安装 mc 文件管理器"
apt -y install mc


echo -e "\n\n\n安装 zsh"
apt -y install zsh
echo -e "\n\n\n下载并执行 Oh My Zsh 安装脚本"
wget http://47.87.214.106:666/?q=https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
chmod 755 install.sh
./install.sh --unattended


echo -e "\n\n\n下载 Frp 二进制包"
wget --no-check-certificate -O frp_0.44.0_linux_amd64.tar.gz http://47.87.214.106:666/?q=https://github.com/fatedier/frp/releases/download/v0.44.0/frp_0.44.0_linux_amd64.tar.gz
tar xzvf frp_0.44.0_linux_amd64.tar.gz -C /usr/local/bin/
mv /usr/local/bin/frp_0.44.0_linux_amd64 /usr/local/bin/frp

echo -e "\n\n\n将启动命令添加到 rc.local 实现开机自启"
sh -c 'echo "nohup /usr/local/bin/frp/frps -c /usr/local/bin/frp/frps.ini &" >> /etc/rc.local'
# 防火墙需要放行7000和用于映射的公共端口


echo -e "\n\n\n安装 Aria2"
apt -y install aria2
mkdir /etc/aria2/
touch /etc/aria2/aria2.session
wget -O /etc/aria2/aria2.conf http://47.87.214.106:666/?q=https://1fxdpq.dm.files.1drv.com/y4mIiwJL9lNeIdO8lXxaVlJ8CgaezUd3kIe7r8ZcAFytG78pUdSN0RprxwsYBW87AwMyXDAtEc3mLeTYBWHf_D4ngSWtjlCGvsoyA9YVs5Vs2X5taFFJmyl-5VgrMoj4EIKg0PsNXX-U6WC5INaaAK8fCrltwvj0lM0cRW0CuHSfxyAJZ0HaNph3kBqMCrtTwO5M_XR22RkpTRzolxlli3TxQ

echo -e "\n\n\n设置 Aria2c RPC Server 自启"
touch /etc/systemd/system/aria2c.service
chmod 755 /etc/systemd/system/aria2c.service

cat>/etc/systemd/system/aria2c.service<<EOF
[Unit]
Description = aria2c rpc server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = aria2c --conf-path=/etc/aria2/aria2.conf
WorkingDirectory=/etc/aria2/

[Install]
WantedBy = multi-user.target

EOF

systemctl enable aria2c
# 防火墙需要放行6800


echo -e "\n\n\n下载并执行V2ray安装脚本"
curl -L -s http://47.87.214.106:666/?q=https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash
echo -e "\n\n\n设置开机启动"
systemctl enable v2ray
echo -e "\n\n\n初始化配置文件"
rm /usr/local/etc/v2ray/config.json
cat>/usr/local/etc/v2ray/config.json<<EOF
{
  "inbounds": [
    {
      "port": 8080,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "cd051aef-2b9c-4c7b-95ef-a0ea888a9896",
            "level": 1,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "httpSettings": {
          "path": "/"
        }
      }
    }
    
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],

  "inboundDetour": [

  ],

  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}

EOF



echo -e "\n\n\n下载并执行V2ray路由规则安装脚本"
curl -L -s http://47.87.214.106:666/?q=https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh | bash



# echo -e "\n\n\n安装 Google BBR"
# wget -O - http://47.87.214.106:666/?q=https://github.com/teddysun/across/raw/master/bbr.sh | bash
echo -e "\n\n\nDebian 10/11 启用 Google BBR"
sh -c 'echo net.core.default_qdisc=fq >> /etc/sysctl.conf'
sh -c 'echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf'
echo -e "\n\n\n从配置文件加载内核参数（需要管理员）"
sysctl -p


echo -e "\n\n\n安装 Nginx"
apt -y install nginx


echo -e "\n\n\n安装 php7.4-fpm"
apt -y install php7.4-fpm
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
mkdir /var/www/$domain_name
chmod 777 /var/www/$domain_name
touch /etc/nginx/sites-available/${domain_name}
cat>/etc/nginx/sites-available/${domain_name}<<EOF
server {
  listen 80;
  listen [::]:80;

  root /var/www/${domain_name};

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

touch /var/www/${domain_name}/default.php
cat>/var/www/${domain_name}/default.php<<EOF
<?php
echo "网站创建成功";

?>
EOF

systemctl restart nginx


wget -O /var/www/${domain_name}/tinyfilemanager.php http://47.87.214.106:666/?q=https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
echo -e "\n\n\n 访问${domain_name}/tinyfilemanager.php 使用账户admin密码admin@123上传文件"

# https://mariadb.com/kb/en/getting-installing-and-upgrading-mariadb/
# echo -e "\n\n\n安装 mariadb-server"
# apt -y install MariaDB-client MariaDB-server
# systemctl start mariadb
# systemctl enable mariadb
# 启动安装向导命令 mysql_secure_installation
# 进入shell sudo mysql -u root mysql
# 修改root密码 UPDATE user SET PASSWORD=PASSWORD('新密码') where USER='root'; 


#echo -e "\n\n\n安装 Docker CE"
#apt install apt-transport-https ca-certificates  curl  gnupg2 software-properties-common
#curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | sudo apt-key add -
#add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable"
#apt update
#apt install docker-ce docker-ce-cli containerd.io



















# echo -e "\n\n\n 安装 php7.4-fpm"
# apt -y install php7.4-fpm
# echo -e "\n\n\n 安装 wordpress 所需扩展"
# apt -y install php-json php7.4-mysql php-curl php7.4-xml php7.4-common php-imagick php-mbstring openssl php-xml php-zip
# systemctl enable php7.4-fpm
# systemctl restart php7.4-fpm

# echo -e "\n\n\n 创建示例站点"
# domain_name=example.ljz.one
# mkdir /var/www/$domain_name
# touch /etc/nginx/conf.d/${domain_name}
# cat>/etc/nginx/conf.d/${domain_name}<<EOF
# server {
#   listen 80;
#   listen [::]:80;

#   root /var/www/${domain_name};

#   # 如果使用PHP，则将index.php添加到列表中
#   index index.php index.html index.htm default.php index.nginx-debian.html;

#   server_name ${domain_name};

#   # 传递PHP脚本到FastCGI服务器
#   #
#   location ~ \.php$ {
#     include snippets/fastcgi-php.conf;
#   #
#   # # With php-fpm (or other unix sockets):
#     fastcgi_pass unix:/run/php/php7.4-fpm.sock;
#   }

# }
# EOF

# mkdir -p /var/www/${domain_name}
# echo "<?php phpinfo(); ?>" >> /var/www/${domain_name}/index.php

# systemctl restart nginx

# # docker pull 2233466866/lnmp:mini
# # docker run -dit -p 81:80 -p 82-90:82-90 -v /docker/www:/www --privileged=true --name=lnmp 2233466866/lnmp:mini
# # docker exec lnmp
# # wget https://github.com/prasathmani/tinyfilemanager/raw/master/tinyfilemanager.php
# # wget https://wordpress.org/latest.zip










# echo -e "\n\n\n------------------------------安装 CPUlimit------------------------------"
# apt -y install cpulimit
# # yum install epel-release cpulimit

# echo -e "\n\n\n 创建脚本对所有进程（包括新建进程）进行监控并限制（3秒检测一次，CPU限制为49％"

# touch /root/cpulimit.sh
# chmod 755 /root/cpulimit.sh
# cat>/root/cpulimit.sh<<EOF
# #!/bin/bash 

# while true ; do

#   id=`ps -ef | grep cpulimit | grep -v "grep" | awk '{print $10}' | tail -1`

#   nid=`ps aux | awk '{ if ( $3 > 49 ) print $2 }' | head -1`

#   if [ "${nid}" != "" ] && [ "${nid}" != "${id}" ] ; then

#     cpulimit -p ${nid} -l 49 &

#     echo "[`date`] CpuLimiter run for ${nid} `ps -ef | grep ${nid} | awk '{print $8}' | head -1`" >> /root/cpulimit-log.log

#   fi

#   sleep 3

# done
# EOF

#echo -e "\n\n\n 将 脚本 启动命令添加到 rc.local 中开机自动执行"
#echo /root/cpulimit.sh>>/etc/rc.local

# cpugroup的方法限制cpu
# systemctl set-property user.slice CPUQuota=49%
# systemctl set-property system.slice CPUQuota=49%

