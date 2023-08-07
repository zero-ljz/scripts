#!/bin/bash

# sudo bash ./fast.sh

# 允许root用户登录
#sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "/etc/ssh/sshd_config"
# 允许使用密码登录
#sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "/etc/ssh/sshd_config"

#rm -rf /docker
#docker rm -f $(docker ps -a -q)

upgrade()
{
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Description: Upgrade this script, Perform this operation in the working directory"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
bash -c 'wget -O fast.sh http://us.iapp.run:777/proxy/https://raw.githubusercontent.com/zero-ljz/scripts/main/shell/fast.sh && bash fast.sh'
}

system_init(){
echo -e "\n\n\n------------------------------安装必备组件 && 系统配置------------------------------"
echo "是否继续？ (y)"
read -t 10 answer

if [ "$answer" = "y" ]; then

echo -e "\n\n\n 配置语言"
#dpkg-reconfigure locales
echo -e "\n\n\n 配置时区"
#dpkg-reconfigure tzdata

apt update

echo -e "\n\n\n 安装必备组件"
apt -y install sudo openssl aptitude zip unzip wget curl telnet sqlite3 python3 python3-pip python3-dev perl lua5.3

echo -e "\n\n\n 安装 Git"
apt -y install git
git config --global user.name "zero-ljz"
git config --global user.email "zero-ljz@qq.com"

echo -e "\n\n\n 设置ssh 120*720=86400 24小时不断开连接"
cp "/etc/ssh/sshd_config" "/etc/ssh/sshd_config-OLD-$(date +%y%m%d-%H%M%S)"
find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#TCPKeepAlive yes|TCPKeepAlive yes|g'
find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#ClientAliveInterval 0|ClientAliveInterval 120|g'
find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#ClientAliveCountMax 3|ClientAliveCountMax 720|g'
systemctl restart sshd

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
# 这个脚本在每个多用户运行级别结束时执行。
# 确保脚本在成功时返回"exit 0"，在错误时返回其他值。
#
# 要启用或禁用此脚本，只需更改执行权限位即可。
#
# 默认情况下，此脚本不执行任何操作。

EOF
systemctl enable rc-local
fi

if [ ! -f "/swapfile" ];then
echo -e "\n\n\n设置 Swap"
# 创建swap文件
fallocate -l 2G /swapfile
# 格式化为交换分区
mkswap /swapfile
# 将文件添加到系统的/etc/fstab文件中，以便在系统启动时自动挂载
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
# 启用交换文件
swapon /swapfile
fi

if [ -z "$(lsmod | grep bbr)" ]; then
echo -e "\n\n\n启用 Google BBR"
sh -c 'echo net.core.default_qdisc=fq >> /etc/sysctl.conf'
sh -c 'echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf'
echo -e "\n\n\n从配置文件加载内核参数（需要管理员）"
sysctl -p
fi


echo -e "\n\n\n配置防火墙"

# sudo apt-get update
# sudo apt-get install iptables-persistent

# # root用户端口 1:1023
# # 开放单个端口 -A INPUT -p tcp --dport 80 -j ACCEPT
# echo "-A INPUT -p tcp --match multiport --dports 1:65535 -j ACCEPT" >> /etc/iptables/rules.v4

# service netfilter-persistent save
# service netfilter-persistent reload
# #systemctl restart networking

apt -y install ufw

ufw allow ssh
ufw allow http
ufw allow https
ufw allow mysql
ufw allow 8000:8100/tcp
ufw allow 10000:20000/tcp
ufw allow 1024:65535/tcp

# ufw deny 9000


# ufw enable
# ufw reload


# 查看所有规则编号
# ufw status numbered
# ufw delete allow 端口号或者编号
# ufw disable
# ufw enable
# ufw reset

fi
}


install_utils(){

echo -e "\n\n\n------------------------------安装一些实用的命令行程序------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# 更多命令行工具 https://github.com/rothgar/awesome-tuis

apt -y install mc

# echo -e "\n\n\n 安装适用于 API 时代的现代、用户友好的命令行 HTTP 客户端"
# apt -y install httpie
# echo -e "\n\n\n 安装MySQL第三方命令行工具。"
# apt -y install mycli

# echo -e "\n\n\n 基于状态行（status line）的命令行提示符增强工具"
# apt -y install powerline
# echo -e "\n\n\n 安装一个更好的 cat 命令替代品，可以帮助你更好地查看文件的内容，支持语法高亮和分页显示。"
# apt -y install bat
# mkdir -p ~/.local/bin
# ln -s /usr/bin/batcat ~/.local/bin/bat

echo -e "\n\n\n 安装一个快速的命令行模糊搜索工具，可以帮助你更快地找到你需要的文件、目录、命令等等。"
apt -y install fzf

echo -e "\n\n\n 安装一个快速的命令行文本搜索工具，支持正则表达式和递归搜索目录"
apt -y install ripgrep


# echo -e "\n\n\n 安装用 Python 编写的终端文件管理器，可以方便地在终端中浏览和操作文件。"
# apt -y install ranger-fm
# echo -e "\n\n\n 安装一个基于文本搜索的快速查找工具，全称为"The Silver Searcher"。它是类似于grep的命令行工具，但比grep更快速、更强大。"
# apt -y install silversearcher-ag
echo -e "\n\n\n 安装一个简单易用的磁盘使用情况分析工具，可以直观地查看磁盘空间使用情况。"
apt -y install ncdu

# echo -e "\n\n\n 安装w3m浏览器。"
# apt -y install w3m
# echo -e "\n\n\n 安装类似于 top 命令，但是具有更强的交互性和可读性，它可以显示更多有关进程的信息。"
# apt -y install htop
echo -e "\n\n\n 安装命令行 JSON 处理器，可以帮助您以可读的方式解析和格式化 JSON 数据。"
apt -y install jq
# echo -e "\n\n\n 安装实时网络带宽监控器。"
# apt -y install bmon

echo -e "\n\n\n 安装网络扫描工具，用于检测主机和服务。其他替代品：masscan"
apt -y install nmap

echo -e "\n\n\n 安装可帮助您在终端中以树形结构显示目录结构。"
apt -y install tree


# echo -e "\n\n\n 安装 exa 替代ls，一个更好的 ls 命令替代品，可以帮助你更好地查看文件和目录的详细信息。"
# OSID=$(grep '^ID=' /etc/os-release | cut -d= -f2)
# if [ "$OSID" = "ubuntu" ]; then
# wget -O exa_0.9.0-4_amd64.deb -c http://old-releases.ubuntu.com/ubuntu/pool/universe/r/rust-exa/exa_0.9.0-4_amd64.deb
# apt-get -y install ./exa_0.9.0-4_amd64.deb
# else
# apt -y install exa
# fi

echo -e "\n\n\n 安装 Micro 编辑器"
apt -y install micro

# echo -e "\n\n\n 安装 nnn 文件管理器"
# apt -y install nnn

echo -e "\n\n\n 多功能的基准测试工具，可以测试CPU、内存、磁盘和数据库等各种系统性能。"
apt -y install sysbench
# cpu测试 sysbench cpu --threads=1 run
# 内存测试 sysbench memory --threads=1 run
# 文件io测试 sysbench fileio --threads=1 --file-total-size=1G --file-test-mode=rndrw prepare


echo -e "\n\n\n 安装fio磁盘性能测试工具"
apt -y install fio
# 运行随机读取测试
# fio --name=random-read --ioengine=libaio --direct=1 --rw=randread --bs=4k --size=1G --numjobs=1 --runtime=60s


# echo -e "\n\n\n 安装 fd 文件搜索工具，一个更好的 find 命令替代品，可以帮助你更快地查找文件，支持快速查找和过滤。"
# wget -O fd_8.4.0_amd64.deb https://github.com/sharkdp/fd/releases/download/v8.4.0/fd_8.4.0_amd64.deb
# dpkg -i  fd_8.4.0_amd64.deb

# 安装命令行提示工具
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc
source ~/.bashrc

echo -e "\n\n\n 安装 tldr 控制台命令的协作备忘单，用法tldr cp"
pip3 install tldr

echo -e "\n\n\n 安装 cht.sh 命令行查询"
apt -y install rlwrap
curl -s https://cht.sh/:cht.sh | tee /usr/local/bin/cht.sh && chmod +x /usr/local/bin/cht.sh

echo -e "\n\n\n 安装 thefuck 命令行自动纠正"
apt -y install python3-dev python3-pip python3-setuptools
pip3 install thefuck --user

echo -e "\n\n\n 安装 bpytop资源监视器"
pip3 install psutil
pip3 install bpytop

# echo -e "\n\n\n 安装跨平台系统监视工具，可以监视 CPU、内存、网络等方面的系统指标。"
pip install --user glances

# 安装GoTTY - 将您的终端共享为 Web 应用程序
wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
tar -xzf gotty_linux_amd64.tar.gz
mv gotty /usr/local/bin/
# 命令：gotty top




# 部署theia ide 
# https://theia--ide-org.translate.goog/docs/composing_applications?_x_tr_hist=true&_x_tr_sl=auto&_x_tr_tl=zh-CN&_x_tr_hl=zh-CN


# 文件发送工具：轻松安全地将内容从一台计算机发送到另一台计算机
curl https://getcroc.schollz.com | bash


fi
}




install_supervisor(){
echo -e "\n\n\n------------------------------安装 Supervisor 进程管理器------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
pip3 install supervisor
echo -e "\n\n\n 生成配置文件"
mkdir /etc/supervisor
echo_supervisord_conf > /etc/supervisor/supervisord.conf
echo -e "\n\n\n 编辑配置文件"
find '/etc/supervisor/supervisord.conf' | xargs perl -pi -e 's|;\[include\]|\[include\]|g'
find '/etc/supervisor/supervisord.conf' | xargs perl -pi -e 's|;files = relative/directory/\*\.ini|files = conf.d/*.ini|g'
echo -e "\n\n\n 创建子配置文件夹"
mkdir -p /etc/supervisor/conf.d

# echo -e "\n\n\n Supervisor 中增加子配置，用 python http server 共享share文件夹"
# mkdir /home/share
# touch /etc/supervisor/conf.d/python_http_server.ini
# cat>/etc/supervisor/conf.d/python_http_server.ini<<EOF
# [program:python]
# command=python3 -m http.server -d /home/share
# directory=/usr/local/bin/
# autorestart=true
# startsecs=3
# startretries=3
# stdout_logfile=/var/log/python.out.log
# stderr_logfile=/var/log/python.err.log
# stdout_logfile_maxbytes=2MB
# stderr_logfile_maxbytes=2MB
# user=root
# priority=999
# numprocs=1
# process_name=%(program_name)s_%(process_num)02d
# EOF

echo -e "\n\n\n 将 Supervisor 启动命令添加到 rc.local 中开机自动执行"
echo supervisord -c /etc/supervisor/supervisord.conf>>/etc/rc.local
supervisord -c /etc/supervisor/supervisord.conf
fi
}

create_service(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name command working_dir"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
app_name=$1
command=$2
working_dir=${3:-"/usr/local/bin/"}

touch /etc/systemd/system/${app_name}.service
chmod 755 /etc/systemd/system/${app_name}.service
cat>/etc/systemd/system/${app_name}.service<<EOF
[Unit]
Description = ${app_name}
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = $command
WorkingDirectory=$working_dir

[Install]
WantedBy = multi-user.target
EOF
}

create_supervisor(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name command working_dir"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
app_name=$1
command=$2
working_dir=${3:-"/usr/local/bin/"}

cat>/etc/supervisor/conf.d/${app_name}.ini<<EOF
[program:${app_name}]
directory=${working_dir}
command=${command}
;user=root
autostart=true
autorestart=true
;startsecs=10          ; 启动延迟时间
;priority=200          ; 启动优先级
stderr_logfile=/var/log/${app_name}.err
stdout_logfile=/var/log/${app_name}.log
;environment=CODENATION_ENV=prod,DEBUG=false,ENVIRONMENT=production
EOF

# 重新读取配置文件
supervisorctl reread
# 应用更改
supervisorctl update

# supervisorctl restart ${app_name}
# 重载配置和重启所有进程
# supervisorctl reload
# 重启匹配的命令行的进程
# pkill -f 'supervisord -c /etc/supervisor/supervisord.conf'
}

install_docker(){
echo -e "\n\n\n------------------------------安装 Docker------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# curl -fsSL https://get.docker.com -o get-docker.sh
# sh get-docker.sh

echo -e "\n\n\n 读取发行版名称"
OSID=$(grep '^ID=' /etc/os-release | cut -d= -f2)
echo -e "\n\n\n 卸载旧版本"
apt-get remove docker docker-engine docker.io containerd runc
echo -e "\n\n\n 更新APT包索引"
apt-get update
echo -e "\n\n\n 安装包以允许apt通过HTTPS使用存储库"
apt-get -y install ca-certificates curl gnupg
echo -e "\n\n\n 添加 Docker 的官方 GPG 密钥"
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/${OSID}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo -e "\n\n\n 设置存储库"
echo  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OSID} "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo -e "\n\n\n 更新APT包索引"
apt-get update
echo -e "\n\n\n 安装 Docker Engine、containerd 和 Docker Compose"
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
}

install_python(){
echo -e "\n\n\n------------------------------安装 Python------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} version"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi

version=${1:-3.9.13}
short_version=${version%%.*}
apt -y install build-essential zlib1g zlib1g-dev libffi-dev
wget https://www.python.org/ftp/python/${version}/Python-${version}.tgz
tar xzvf Python-${version}.tgz
cd Python-${version}
./configure --prefix=/usr/local/bin/python
make && make install
ln -s  /usr/local/bin/python/bin/python${short_version} /usr/bin/python3
ln -s  /usr/local/bin/python/bin/pip3 /usr/bin/pip3
cd ..
fi

}



install_nodejs(){
echo -e "\n\n\n------------------------------安装 Nodejs------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
apt -y install npm
# 使用版本管理器安装nodejs https://learn.microsoft.com/zh-cn/windows/dev-environment/javascript/nodejs-on-wsl?source=recommendations
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# 运行以下操作可以不用重启终端就能使用nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts
# 全局安装yarn
npm install -g yarn
#npm config set registry https://registry.npm.taobao.org
fi
}

install_php(){
echo -e "\n\n\n------------------------------安装 PHP------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
apt -y install php php-fpm composer php-json php-mbstring php-mysql php-xml php-zip php-curl php-imagick php-gd php-pear php-redis php-sqlite3 php-mongodb php-bcmath php-soap php-intl php-igbinary php-xdebug
# 建议安装
apt -y install fossil mercurial subversion php-zip php-symfony-event-dispatcher php-symfony-lock php-pear
# systemctl enable php7.3-fpm
# systemctl start php7.3-fpm
fi
}

install_nginx(){
echo -e "\n\n\n------------------------------安装 Nginx------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
apt -y install nginx

systemctl enable nginx
systemctl start nginx
fi
}

install_mysql(){
echo -e "\n\n\n------------------------------安装 MySQL------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ "$answer" = "y" ]; then

# wget -O mysql-apt-config_0.8.24-1_all.deb https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
# dpkg -i mysql-apt-config_0.8.24-1_all.deb

# #安装MariaDB GPG密钥
# sudo apt-get install software-properties-common dirmngr
# sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
# # 添加MariaDB官方软件包源
# sudo add-apt-repository 'deb [arch=amd64] http://ftp.ubuntu-tw.org/mirror/mariadb/repo/10.3/debian buster main'

# echo -e "\n\n\n 安装 MySQL-Server"
# apt -y install MariaDB-client mariadb-server

# systemctl enable mariadb
# systemctl start mariadb

apt -y install lsb-release
wget -O mysql-apt-config_0.8.18-1_all.deb ${base_url}https://dev.mysql.com/get/mysql-apt-config_0.8.18-1_all.deb
dpkg -i mysql-apt-config_0.8.18-1_all.deb
systemctl enable mysql
systemctl start mysql

echo -e "\n\n\n 设置 MySQL 安全选项"
mysql_secure_installation

echo '
使用以下命令连接到MySQL服务器
mysql -h 127.0.0.1 -u root -p
'

echo '
使用以下命令修改root密码
UPDATE user SET PASSWORD=PASSWORD('root') where USER='root'; 
'

echo '
使用以下命令创建数据库和用户
CREATE DATABASE db1;
CREATE USER 'user1'@'%' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON db1.* TO 'user1'@'%';
FLUSH PRIVILEGES;
'

fi
}

install_redis(){
echo -e "\n\n\n------------------------------安装 Redis------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ "$answer" = "y" ]; then
echo -e "\n\n\n 安装 redis-server"
apt -y install redis-server

systemctl enable redis-server
systemctl restart redis-server

fi
}

install_aria2(){
echo -e "\n\n\n------------------------------安装 Aria2------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
apt -y install aria2
mkdir /etc/aria2/
touch /etc/aria2/aria2.session
wget -O /etc/aria2/aria2.conf https://1fxdpq.dm.files.1drv.com/y4mIiwJL9lNeIdO8lXxaVlJ8CgaezUd3kIe7r8ZcAFytG78pUdSN0RprxwsYBW87AwMyXDAtEc3mLeTYBWHf_D4ngSWtjlCGvsoyA9YVs5Vs2X5taFFJmyl-5VgrMoj4EIKg0PsNXX-U6WC5INaaAK8fCrltwvj0lM0cRW0CuHSfxyAJZ0HaNph3kBqMCrtTwO5M_XR22RkpTRzolxlli3TxQ

echo -e "\n\n\n 使用 systemd 守护 Aria2c RPC Server 进程"
create_service aria2c "aria2c --conf-path=/etc/aria2/aria2.conf" /etc/aria2/
systemctl enable aria2c
systemctl restart aria2c
# 防火墙需要放行6800
fi
}

install_filebrowser(){
echo -e "\n\n\n------------------------------安装 Web filebrowser------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash 
# filebrowser -r / -a 0.0.0.0 -p 8080
# 默认账户 admin / admin
fi
}

install_alist(){
echo -e "\n\n\n------------------------------安装 AList------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install /opt
systemctl restart alist
# 默认账号密码 admin/admin，端口5244
fi
}


install_frp(){
echo -e "\n\n\n------------------------------安装 Frp------------------------------"
echo -e "\n\n\n下载 Frp 二进制包"
wget --no-check-certificate -O frp_0.48.0_linux_amd64.tar.gz http://us.iapp.run:777/proxy/https://github.com/fatedier/frp/releases/download/v0.48.0/frp_0.48.0_linux_amd64.tar.gz
tar xzvf frp_0.48.0_linux_amd64.tar.gz -C /usr/local/bin/
mv /usr/local/bin/frp_0.48.0_linux_amd64 /usr/local/bin/frp

# echo -e "\n\n\n 使用 systemd 守护 Frps 进程"
# create_service frps "/usr/local/bin/frp/frps -c /usr/local/bin/frp/frps.ini" /usr/local/bin/frp
# systemctl enable frps
# systemctl restart frps
}

start_frpc()
{
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} local_port:remote_port local_port:remote_port ..."
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
file=/usr/local/bin/frp/frpc.ini

# 重新生成配置文件
cat > $file << EOF
[common]
server_addr = 42.193.229.54
server_port = 7000

EOF

ip=$(curl -s ifconfig.me)

# 遍历命令行参数
index=1
while [[ $# -gt 0 ]]; do
    # 拆分参数为 local_port 和 remote_port
    #IFS=':' read -r local_port remote_port <<< "$1"
    # 替代上行命令以兼容sh
    local_port=$(echo "$1" | cut -d ':' -f 1)
    remote_port=$(echo "$1" | cut -d ':' -f 2)
    
    # 生成文本块
    text="[service-$ip-$index]
type = tcp
local_ip = 127.0.0.1
local_port = $local_port
remote_port = $remote_port

"
    
    # 追加文本块到文件
    echo "$text" >> $file
    
    # 增加索引
    index=$((index + 1))
    
    # 移动到下一个参数
    shift
done

# 启动客户端
/usr/local/bin/frp/frpc -c $file
}

start_frpc2()
{
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} local_port remote_port server_addr"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
local_port=$1
remote_port=$2
server_addr=${3:-42.193.229.54}
  #sed -i "s/server_addr = 127.0.0.1/server_addr = $server_addr/g" /usr/local/bin/frp/frpc.ini
  sed -i "s/\(server_addr = \)[0-9.]*/\1$server_addr/" /usr/local/bin/frp/frpc.ini
  sed -i "s/\(local_port = \)[0-9]*/\1$local_port/" /usr/local/bin/frp/frpc.ini
  sed -i "s/\(remote_port = \)[0-9]*/\1$remote_port/" /usr/local/bin/frp/frpc.ini

# 启动客户端
/usr/local/bin/frp/frpc -c /usr/local/bin/frp/frpc.ini
}


install_ssh(){ 
# alpine 安装ssh服务
apk add openssh-server 

sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
    echo "root:123123" | chpasswd

/usr/sbin/sshd

echo '请使用 ssh root@127.0.0.1 -p 22 连接'
}

systeminfo()
{
uname -a && lsb_release -a && cat /etc/os-release && hostnamectl && df -h && free -h && timedatectl && curl ipinfo.io
}



install_trojan(){
echo -e "\n\n\n------------------------------安装 Trojan------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

echo -e "\n\n\n 安装 expect 自动交互工具"
apt-get -y install tcl tk expect

IPWAN=$(curl ifconfig.io)
cat>openssl-req.exp<<EOF
#!/usr/bin/expect
spawn openssl req -x509 -newkey rsa:4096 -nodes -out certificate.crt -keyout private.key -days 365
expect "Country Name:"
send "cn\n"
expect "State or Province Name"
send "\n"
expect "Locality Name"
send "\n"
expect "Organization Name"
send "\n"
expect "Organizational Unit Name"
send "\n"
expect "Common Name"
send "${IPWAN}\r"
expect "Email Address"
send "zero-ljz@qq.com\n"
interact
EOF

expect ./openssl-req.exp
mv ./certificate.crt /home/certificate.crt
mv ./private.key /home/private.key

echo -e "\n\n\n 下载并执行 Trojan 快速开始脚本"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
echo -e "\n\n\n 替换配置文件中的证书路径"
find '/usr/local/etc/trojan/config.json' | xargs perl -pi -e 's|/path/to/|/home/|g'

systemctl enable trojan
systemctl restart trojan
fi
}

install_v2ray(){
echo -e "\n\n\n------------------------------安装 V2Ray------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# 安装可执行文件和 .dat 数据文件
curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash

# 只更新 .dat 数据文件
curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh | bash

echo -e "\n\n\n初始化配置文件"
rm /usr/local/etc/v2ray/config.json
cat>/usr/local/etc/v2ray/config.json<<EOF
{
  "inbounds": [
    {
      "port": 10801,
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

systemctl enable v2ray
systemctl restart v2ray
fi
}



install_v2ray2(){
curl -LkOJ http://us.iapp.run:777/proxy/https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip
unzip -d v2ray-linux-64 v2ray-linux-64.zip
# 复制主程序和辅助工具
cp v2ray-linux-64/v2ray v2ray-linux-64/v2ctl /usr/local/bin/ && chmod 777 /usr/local/bin/v2ray
# 复制ip数据文件和域名数据文件
mkdir -p /usr/local/share/v2ray && cp v2ray-linux-64/geoip.dat v2ray-linux-64/geosite.dat /usr/local/share/v2ray/
mkdir -p /usr/local/etc/v2ray && cp v2ray-linux-64/config.json /usr/local/etc/v2ray/
cp v2ray-linux-64/systemd/system/v2ray.service v2ray-linux-64/systemd/system/v2ray@.service /etc/systemd/system/

# 在v2rayN windows客户端右键节点导出为客户端配置config.json文件复制到/usr/local/etc/v2ray

# systemctl enable v2ray
# systemctl restart v2ray

# /usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json

#查看环境变量的值
#echo #ALL_PROXY

#一键设置系统代理，10809是Windows上v2rayN的监听端口
#export ALL_PROXY="http://127.0.0.1:10809"
#unset ALL_PROXY

#这个我也不清楚需不需要
#export http_proxy="http://127.0.0.1:10809"

# 参考链接
# https://www.junz.org/post/v2_in_linux/


rm /usr/local/etc/v2ray/config.json
cat>/usr/local/etc/v2ray/config.json<<EOF
{
  "log": {
    "access": "",
    "error": "",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    },
    {
      "tag": "http",
      "port": 10809,
      "listen": "127.0.0.1",
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "47.87.214.106",
            "port": 80,
            "users": [
              {
                "id": "cd051aef-2b9c-4c7b-95ef-a0ea888a9896",
                "alterId": 0,
                "email": "t@t.tt",
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/",
          "headers": {
            "Host": "qq.com"
          }
        }
      },
      "mux": {
        "enabled": false,
        "concurrency": -1
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "enabled": true
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "domain:example-example.com",
          "domain:example-example2.com"
        ],
        "enabled": true
      },
      {
        "type": "field",
        "outboundTag": "block",
        "domain": [
          "geosite:category-ads-all"
        ],
        "enabled": true
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ],
        "enabled": true
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private",
          "geoip:cn"
        ],
        "enabled": true
      },
      {
        "type": "field",
        "port": "0-65535",
        "outboundTag": "proxy",
        "enabled": true
      }
    ]
  }
}

EOF





}


start_v2ray(){
    #systemctl restart v2ray
    nohup /usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json &

    # 不显示任何输出
    #nohup /usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json > /dev/null 2>&1 &

    # 为了使环境变量在脚本的父进程中生效，使用 . fast.sh start_v2ray
    export ALL_PROXY="http://127.0.0.1:10809"
}

stop_v2ray()
{
    #systemctl stop v2ray
    killall v2ray

    # 为了使环境变量在脚本的父进程中生效，使用 . fast.sh stop_v2ray
    unset ALL_PROXY
}


create_ssl(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi

domain_name=$1
site_root_dir=/var/www/html/${domain_name}

SSL_DIR=/var/ssl
if [ ! -d "$SSL_DIR" ]; then
    mkdir "$SSL_DIR"
fi

ACME_TINY="/tmp/acme_tiny.py"
ACCOUNT_KEY=$SSL_DIR/account.key
# 私钥
DOMAIN_KEY=$SSL_DIR/${domain_name}.key
# 公钥
DOMAIN_CRT="$SSL_DIR/${domain_name}.crt"
# 链接起来的公钥
DOMAIN_CHAINED_CRT="$SSL_DIR/${domain_name}.chained.crt"

DOMAIN_CSR=$SSL_DIR/${domain_name}.csr

# 文件不存在时创建 Let's Encrypt 帐户私钥
if [ ! -f "$ACCOUNT_KEY" ];then
    echo "Generate account key..."
    openssl genrsa 4096 > "$ACCOUNT_KEY"
fi

if [ ! -f "$DOMAIN_KEY" ];then
    echo "Generate domain key 私钥..."
    openssl genrsa 2048 > "$DOMAIN_KEY"
fi

echo "Generate CSR..."
openssl req -new -sha256 -key "$DOMAIN_KEY" -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=%s" "DNS:${domain_name},DNS:${domain_name}")) > "${DOMAIN_CSR}"


# crt文件存在时备份
if [ -f "$DOMAIN_CRT" ];then
    mv "$DOMAIN_CRT" "$DOMAIN_CRT-OLD-$(date +%y%m%d-%H%M%S)"
fi

DOMAIN_DIR="$site_root_dir/.well-known/acme-challenge/"
mkdir -p "$DOMAIN_DIR"

wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O $ACME_TINY -o /dev/null
python3 $ACME_TINY --account-key "$ACCOUNT_KEY" --csr "${DOMAIN_CSR}" --acme-dir "$DOMAIN_DIR" > "$DOMAIN_CRT"


if [ ! -f "lets-encrypt-x3-cross-signed.pem" ];then
    wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -o /dev/null
fi
# 合并为公钥文件
cat "$DOMAIN_CRT" lets-encrypt-x3-cross-signed.pem > "$DOMAIN_CHAINED_CRT"

}


create_proxy(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name local_port"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi

domain_name=$1
local_port=$2

cat>${domain_name}.conf<<EOF
# 反向代理配置

# 引入 upstream 配置
#include upstream.conf;

# 定义反向代理
server {
    listen 80;
    server_name ${domain_name};

    # 日志记录
    access_log /var/log/nginx/${domain_name}.access.log;
    error_log /var/log/nginx/${domain_name}.error.log;

    location / {
        # 设置代理缓存
        #proxy_cache my_cache;
        #proxy_cache_valid 200 10m;

        # 负载均衡算法
        #proxy_pass http://my_upstream;

        #add_header Content-Security-Policy upgrade-insecure-requests;
        proxy_pass_header Server;
        proxy_set_header Host \$host;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${local_port};
    }

    # SSL/TLS 配置
    # listen 443 ssl;
    # ssl_certificate /path/to/certificate.pem;
    # ssl_certificate_key /path/to/private_key.pem;

    # 安全配置
    # 设置请求头
    # proxy_set_header X-Real-IP $remote_addr;
    # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    # 设置请求大小限制
    # client_max_body_size 10m;

    # 设置连接超时
    # proxy_connect_timeout 5s;
    # proxy_read_timeout 10s;

    # 健康检查
    # check interval=30s rise=2 fall=3 timeout=5s;

    # 防止直接访问代理
    # deny all;
}

EOF

# docker exec -i nginx1 sh <<EOF
# cat > /etc/nginx/conf.d/blog.iapp.run.conf <<EOF2

# EOF2
# EOF


# docker cp ./${domain_name}.conf nginx1:/etc/nginx/conf.d/${domain_name}.conf
cp ./${domain_name}.conf /etc/nginx/conf.d/${domain_name}.conf
# docker restart nginx1
}

create_vhost(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi

domain_name=$1
    
mkdir /var/www/html/${domain_name}
cat>${domain_name}.conf<<EOF
server {
    listen       80; # default_server;
    listen  [::]:80;
    #server_name  localhost;
    server_name  ${domain_name};

    #listen 443 ssl;
    #ssl_certificate /var/ssl/${domain_name}.chained.crt;
    #ssl_certificate_key /var/ssl/${domain_name}.key;

    # 静态资源路径，必须是在nginx容器内有效的路径
    root   /var/www/html/${domain_name};

    #access_log  /var/log/nginx/${domain_name}.access.log  main;

    location / {
        index index.php index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        # 本地安装的php-fpm默认是只能通过套接字通信
        #fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        # PHP脚本文件路径，document_root表示使用静态资源相同目录，目录路径必须是在php-fpm容器内有效的目录路径
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE "post_max_size=100M
                max_execution_time=3600
                upload_max_filesize=100M
                memory_limit=256M";
        include        fastcgi_params;
    }

    # 设置请求大小限制
    client_max_body_size 100m;

}
EOF
#docker cp ./${domain_name}.conf nginx1:/etc/nginx/conf.d/${domain_name}.conf
cp ${domain_name}.conf /etc/nginx/conf.d/${domain_name}.conf
#docker restart nginx1

echo "远程下载默认网站 源码文件"
echo '<?php echo phpinfo(); ?>' >> /var/www/html/${domain_name}/phpinfo.php
wget -O /var/www/html/${domain_name}/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
wget -O /var/www/html/${domain_name}/editor.php https://github.com/vrana/adminer/releases/download/v4.8.1/editor-4.8.1.php
wget -O /var/www/html/${domain_name}/tinyfilemanager.php https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
wget -O /var/www/html/${domain_name}/index.php https://raw.githubusercontent.com/lorenzos/Minixed/master/index.php
wget -O /var/www/html/${domain_name}/shell.php https://raw.githubusercontent.com/artyuum/simple-php-web-shell/master/index.php

# wget -O phpMyAdmin.zip https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
# unzip -d /var/www/html/${domain_name} phpMyAdmin.zip > /dev/null
# mv /var/www/html/${domain_name}/phpMyAdmin-5.2.1-all-languages /var/www/html/${domain_name}/phpMyAdmin
# mv /var/www/html/${domain_name}/phpMyAdmin/config.sample.inc.php /var/www/html/${domain_name}/phpMyAdmin/config.inc.php && chmod 755 /var/www/html/${domain_name}/phpMyAdmin/config.inc.php
# sed -i "s/localhost/mysql/g" /var/www/html/${domain_name}/phpMyAdmin/config.inc.php

#https://cn.wordpress.org/latest-zh_CN.zip
#https://github.com/typecho/typecho/releases/latest/download/typecho.zip


chown -R www-data:www-data /var/www/html/${domain_name}
chmod -R 777 /var/www/html/${domain_name}
}


create_database(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
domain_name=$1
MYSQL_ROOT_PASSWORD=$(cat MYSQL_ROOT_PASSWORD.txt)

# 将创建数据库的sql语句写入sql文件并通过-i参数和<输入重定向符号传递给容器内的命令执行
db_password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
db_user=${domain_name//./_}
cat>${domain_name}.sql<<EOF
CREATE DATABASE ${db_user}_db;
CREATE USER '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_user}_db.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
EOF

cmd=mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${domain_name}.sql
echo "请执行${cmd}创建数据库和用户 mysql://${db_user}:${db_password}@mysql:3306/${db_user}_db"
echo "在容器内创建需执行 docker exec -i mysql1 ${cmd}"

}


deploy_lnmpr(){
echo -e "\n\n\n------------------------------搭建LNMPR环境------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
echo "${MYSQL_ROOT_PASSWORD}" > MYSQL_ROOT_PASSWORD.txt

docker network create lnmp

echo "安装 Redis"
docker run -dp 6379:6379 --name redis1 --network lnmp --network-alias redis redis:alpine

echo "安装 MySQL"
# docker run -dp 3306:3306 --name mysql1 --network lnmp --network-alias mysql -v /docker/mysql:/var/lib/mysql \
# -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
# -e MYSQL_USER=user1 \
# -e MYSQL_PASSWORD=123 \
# -e MYSQL_DATABASE=db1 \
# mysql:5.7-debian

docker run -dp 3306:3306 --name mysql1 --network lnmp --network-alias mysql -v /docker/mysql:/var/lib/mysql \
--env MARIADB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
--env MARIADB_USER=user1 \
--env MARIADB_PASSWORD=123 \
--env MARIADB_DATABASE=db1 \
mariadb:10.3

echo "安装 Nginx"
docker run -d --name nginx1 --network host -v /var/www/html:/var/www/html -v /var/ssl:/var/ssl -v /etc/nginx/conf.d:/etc/nginx/conf.d nginx:alpine
echo "安装 PHP"
docker run -d -p 127.0.0.1:9000:9000 --name php1 --network lnmp -v /var/www/html:/var/www/html php:7.4-fpm-alpine

# 使用这个必须 -v /var/www:/var/www/html，否则nginx连不上php-fpm，日志报错[error] 20#20: *5 recv() failed (104: Connection reset by peer) while reading response header from upstream
#docker run -d -p 127.0.0.1:9000:9000 --name php1 --network lnmp -v /docker/php1:/usr/local/etc -v /var/www:/var/www/html webdevops/php:7.4-alpine

echo "安装 PHP扩展"
# https://github.com/docker-library/wordpress/blob/97f75b51f909fbd9894d128ea6893120cfd23979/latest/php8.0/fpm/Dockerfile#L10-L16
# https://make.wordpress.org/hosting/handbook/server-environment/

# https://github.com/docker-library/wordpress/blob/97f75b51f909fbd9894d128ea6893120cfd23979/latest/php7.4/fpm-alpine/Dockerfile
docker exec -t php1 apk update
docker exec -t php1 apk add --no-cache bash ghostscript imagemagick 
docker exec -t php1 apk add --no-cache --virtual .build-deps freetype-dev icu-dev imagemagick-dev libjpeg-turbo-dev libpng-dev libwebp-dev libzip-dev

# docker exec -t php1 apt-get update
# docker exec -t php1 apt-get install -y --no-install-recommends libfreetype6-dev libicu-dev libjpeg-dev libmagickwand-dev libpng-dev libwebp-dev libzip-dev

docker exec -t php1 docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# 用 docker-php-ext-install 安装扩展
docker exec -t php1 docker-php-ext-install -j "$(nproc)" bcmath exif gd intl mysqli zip

# 用 pecl 安装扩展
docker exec php1 apk add build-base autoconf
docker exec php1 pecl install imagick-3.6.0 redis
docker exec php1 docker-php-ext-enable imagick redis
docker exec -t php1 rm -r /tmp/pear




#docker exec -t php1 apt-get install -y libbz2-dev sqlite3 libsqlite3-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libonig-dev libreadline-dev libtidy-dev libxslt-dev libzip-dev
# docker-php-ext-install 全部可安装扩展
#docker exec -t php1 docker-php-ext-install bcmath bz2 calendar ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp hash iconv imap intl json ldap mbstring mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection session shmop simplexml snmp soap sockets sodium spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlrpc xmlwriter xsl zend_test zip

docker restart php1

fi
}

deploy_tinyfilemanager(){
docker run -d -v /:/var/www/html/data -p 8020:80 --restart=always --name tinyfilemanager1 tinyfilemanager/tinyfilemanager:master
docker exec -i tinyfilemanager1 wget -O /docker/${app_name}/adminer.php http://us.iapp.run:777/proxy/https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
domain_name=${1:-file.iapp.run}
create_proxy ${domain_name} 8020
}

deploy_wordpress_fpm(){
echo -e "\n\n\n------------------------------部署 Wordpress FPM 和 Nginx 配合------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

domain_name=${1:-blog.iapp.run}
create_database ${domain_name}

docker run -dp 127.0.0.1:9001:9000 --name wordpress1 --network lnmp -v /var/www/html/${domain_name}:/var/www/html \
-e WORDPRESS_DB_HOST=mysql \
-e WORDPRESS_DB_USER=${db_user} \
-e WORDPRESS_DB_PASSWORD=${db_password} \
-e WORDPRESS_DB_NAME=${db_user}_db \
wordpress:php8.2-fpm-alpine

cat>${domain_name}.conf<<EOF
server {
    listen       80;
    listen  [::]:80;
    server_name  ${domain_name};  
    # 在nginx容器里的静态资源根目录
    root   /var/www/html/${domain_name};

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        index index.php index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9001;
        fastcgi_index  index.php;
        # 在fastcgi process manager 容器里的脚本文件 根目录
        fastcgi_param  SCRIPT_FILENAME  /var/www/html\$fastcgi_script_name;
        include        fastcgi_params;
    }

}
EOF
docker cp ./${domain_name}.conf nginx1:/etc/nginx/conf.d/${domain_name}.conf
docker restart nginx1


fi
}

deploy_wordpress(){
echo -e "\n\n\n------------------------------部署 Wordpress------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

docker run -dp 127.0.0.1:8010:80 --name wordpress1 --network lnmp -v /docker/wordpress1:/var/www/html wordpress
domain_name=${1:-blog.iapp.run}
create_proxy ${domain_name} 8010
create_database ${domain_name}

fi
}

deploy_portainer(){
echo -e "\n\n\n------------------------------部署 Portainer------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# https://docs.portainer.io/start/install/server/docker/linux
docker volume create portainer_data
#docker run -d -p 127.0.0.1:9002:9000 --name portainer1 -v /var/run/docker.sock:/var/run/docker.sock -v /docker/portainer_data:/data portainer/portainer
# 汉化版
docker run -d -p 9002:9000 --name portainer1 -v /var/run/docker.sock:/var/run/docker.sock -v /docker/portainer_data:/data 6053537/portainer

domain_name=${1:-docker.iapp.run}
create_proxy ${domain_name} 9002

fi
}




deploy_nextcloud(){
echo -e "\n\n\n------------------------------部署 NextCloud------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

docker run -dp 127.0.0.1:8011:80 --name nextcloud1 --network lnmp  -v /docker/nextcloud:/var/www/html nextcloud
domain_name=${1:-cloud.iapp.run}
create_proxy ${domain_name} 8011
#create_database ${domain_name}
# 用mysql性能不好
fi
}

deploy_searxng(){
echo -e "\n\n\n------------------------------部署 SearXNG------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
domain_name=${1:-s.iapp.run}
# https://docs.searxng.org/admin/installation-docker.html#searxng-searxng
docker run --rm \
-d -p 127.0.0.1:8012:8080 \
--name searxng1 \
-v "/docker/searxng:/etc/searxng" \
-e "BASE_URL=http://${domain_name}/" \
-e "INSTANCE_NAME=元搜索" \
searxng/searxng

# 在settings.yml文件中设置默认启用的搜索引擎
create_proxy ${domain_name} 8012


fi
}


deploy_gitea(){
echo -e "\n\n\n------------------------------部署 Gitea------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then
adduser \
   --system \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --group \
   --disabled-password \
   --home /home/git \
   git
docker run -d \
--name gitea1 \
-p 127.0.0.1:3000:3000 -p 222:22 \
-e USER_UID=$(id -u git) \
-e USER_GID=$(id -g git) \
-v /docker/gitea:/data  \
-v /etc/timezone:/etc/timezone:ro \
-v /etc/localtime:/etc/localtime:ro  \
gitea/gitea:1.19

domain_name=${1:-git.iapp.run}
create_proxy ${domain_name} 3000

# 记得配置SSH_PORT=222，SSH_LISTEN_PORT=22

# ssh://git@git.iapp.run:222/zero-ljz/repo.git
fi
}

deploy_cloudreve(){
echo -e "\n\n\n------------------------------部署 CloudReve------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

mkdir -vp /docker/cloudreve/{uploads,avatar} && touch /docker/cloudreve/conf.ini && touch /docker/cloudreve/cloudreve.db

docker run -d \
-p 5212:5212 \
--name cloudreve1 \
--mount type=bind,source=/docker/cloudreve/conf.ini,target=/cloudreve/conf.ini \
--mount type=bind,source=/docker/cloudreve/cloudreve.db,target=/cloudreve/cloudreve.db \
-v /docker/cloudreve/uploads:/cloudreve/uploads \
-v /docker/cloudreve/avatar:/cloudreve/avatar \
cloudreve/cloudreve:latest

domain_name=${1:-c.iapp.run}
create_proxy ${domain_name} 5212

fi
}

deploy_gocron(){
echo -e "\n\n\n------------------------------部署 GoCron------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

docker run --name gocron1 --network lnmp -p 127.0.0.1:5920:5920 -d ouqg/gocron

domain_name=${1:-cron.iapp.run}
create_proxy ${domain_name} 5920
create_database ${domain_name}
fi
}



deploy_hackmd(){
echo -e "\n\n\n------------------------------部署 HackMD------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# https://hackmd.io/c/codimd-documentation/%2Fs%2Fcodimd-docker-deployment
docker run -d \
-p 3001:3000 \
--name hackmd1 \
--network lnmp \
-e CMD_DB_URL=mysql://user1:123@mysql:3306/db1 \
-e CMD_USECDN=false \
-v /docker/hackmd/upload-data:/home/hackmd/app/public/uploads \
hackmdio/hackmd:2.4.2

domain_name=${1:-md.iapp.run}
create_proxy ${domain_name} 3001
create_database ${domain_name}

fi
}



deploy_lychee()
{
echo -e "\n\n\n------------------------------部署 Lychee------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

# https://github.com/LycheeOrg/Lychee-Docker/blob/master/default.conf
# https://lycheeorg.github.io/docs/docker.html
docker run -d \
-p 127.0.0.1:8013:80 \
--name=lychee1 \
-v /docker/lychee/conf:/conf \
-v /docker/lychee/uploads:/uploads \
-v /docker/lychee/sym:/sym \
-e PUID=1000 \
-e PGID=1000 \
-e PHP_TZ=Asia/ShangHai \
-e DB_CONNECTION=mysql \
-e DB_HOST=mysql \
-e DB_PORT=3306 \
-e DB_DATABASE=db1 \
-e DB_USERNAME=user1 \
-e DB_PASSWORD=123 \
--network lnmp \
lycheeorg/lychee

domain_name=${1:-photo.iapp.run}
create_proxy ${domain_name} 8013
create_database ${domain_name}

fi
}


deploy_ghost()
{
echo -e "\n\n\n------------------------------部署 Ghost------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ $? -eq 142 ] || [ "$answer" = "y" ]; then

domain_name=${1:-ghost.iapp.run}
create_proxy ${domain_name} 8014
create_database ${domain_name}

docker volume create --name ghost_data
docker run -d --name ghost1 \
  -p 8014:8080 -p 8443:8443 \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env GHOST_DATABASE_USER=${db_user} \
  --env GHOST_DATABASE_PASSWORD=${db_password} \
  --env GHOST_DATABASE_NAME=${db_user}_db \
  --env GHOST_DATABASE_HOST=mysql \
  --network lnmp \
  --volume ghost_data:/bitnami/ghost \
  bitnami/ghost:5.50.4
# 垃圾镜像，run后显示Inspecting operating system然后卡死就没了下文
fi
}

#docker run --name py1 -v $PWD:/usr/src/myapp  -w /usr/src/myapp python:3.9.13-alpine python app.py

# vnc连接 密码123456 安装vscode后用code --user-data-dir ./ --no-sandbox 启动
# docker run --name ud1 -d -p 22:22 -p 5900:5900 gotoeasy/ubuntu-desktop

# 先安装Kasm Workspaces
#https://www.kasmweb.com/docs/latest/install/single_server_install.html

# cd /tmp
# curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.13.0.002947.tar.gz
# tar -xf kasm_release_1.13.0.002947.tar.gz
# sudo bash kasm_release/install.sh -L 8443 --admin-password admin --user-password 123123


# # 用户名 kasm_user ，用https协议访问6901端口
# docker run -d --name kasm1 -it --shm-size=512m --name k1 -e KASM_PORT=4443 -p 4443:4443 -p 6901:6901 -e VNC_PW=123123 kasmweb/desktop:1.13.0



# 创建空的 Debian 容器并保持运行
# docker run -d -p  --name debian1 --network host debian:bullseye-slim tail -f /dev/null
# commands=$(cat <<EOF

# apt update


# EOF
# )
# docker exec debian1 bash -c "$commands"

create_php_app()
{
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name http_port"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi

app_name=$1
http_port=$2
docker run -d -p "${http_port}":80 --name ${app_name} -v "/docker/${app_name}":/var/www/html php:7.4-apache
wget -O /docker/${app_name}/adminer.php http://us.iapp.run:777/proxy/https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
wget -P /docker/${app_name} http://us.iapp.run:777/proxy/https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
}

# docker restart nginx1




function run_from_git(){
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} repo_url port_port"
    exit 0
elif [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then
    declare -f ${FUNCNAME}
    exit 0
fi
  url=$1
  p=$2

  # bash /root/fast.sh run_from_git https://github.com/zero-ljz/iapp.git 777:8000
  # 请在repos目录使用此函数
  repo=$(echo "$url" | sed 's|.*/\([^/]*\)\.git|\1|')
  docker rm -f ${repo}1
  docker image rm ${repo}
  rm -rf ${repo}

  git clone ${url}
  docker build -t ${repo} ${repo}
  docker run -p ${p} --name ${repo}1 ${repo}
  docker exec -it ${repo}1 sh

}


function reinstall_debian(){
    read -p "请输入新的root密码：" password
    curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && chmod a+rx debi.sh && ./debi.sh --cdn --network-console --ethx --bbr --timezone Asia/Shanghai --user root --password ${password}
}


function auto_mode(){
    system_init
    install_docker
    install_nodejs
    install_php
    install_nginx

    install_aria2
    install_frp
    install_v2ray

    # deploy_portainer
    # deploy_lnmpr
    # deploy_cloudreve
    # deploy_searxng
    
    
    
}

# 获取函数名
function_name=${1:-default}
shift  # 移除第一个参数，剩下的参数会被传递给函数

# 获取可用函数列表
function_list=$(compgen -A function)

# 定义在不传入参数时默认执行的函数
function default()
{
    echo "Usage: ${FUNCNAME} [function_name] [-h] [arguments]"
    echo -e "\nAvailable functions:"
    for func in $function_list; do
        echo "  $func"
    done
    echo
}

# 调用指定的函数，并传递参数
"$function_name" "$@"
