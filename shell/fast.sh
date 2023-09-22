#!/bin/bash

# sudo bash ./fast.sh

# 允许root用户登录
#sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "/etc/ssh/sshd_config"
# 允许使用密码登录
#sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "/etc/ssh/sshd_config"

#rm -rf /docker
#docker rm -f $(docker ps -a -q)

OSID=$(grep '^ID=' /etc/os-release | cut -d= -f2)

system_init(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装必备组件 && 系统配置------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

# echo -e "\n\n\n 配置语言"
# dpkg-reconfigure locales
# echo -e "\n\n\n 配置时区"
# dpkg-reconfigure tzdata

apt update

echo -e "\n\n\n 安装必备组件"
apt -y install sudo openssl aptitude unzip wget curl telnet perl
apt -y install sqlite3 lua5.3 zip
apt -y install python3 python3-pip python3-venv python3-dev python3-setuptools

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

total_memory_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 1024)}')
swapfile_length=$(($total_memory_mb * 2))
# 创建swap文件
fallocate -l ${swapfile_length}M /swapfile
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

}


install_utils(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装一些实用的命令行程序------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

# 更多命令行工具 https://github.com/rothgar/awesome-tuis

apt -y install mc

# echo -e "\n\n\n 安装适用于 API 时代的现代、用户友好的命令行 HTTP 客户端"
pip3 install httpie
# echo -e "\n\n\n 安装数据库第三方命令行工具。"
pip3 install mycli litecli iredis

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

apt -y install apache2-utils
# Apache Benchmarking Tool，t最大持续时间 n总请求数 c并发连接数 v信息详细程度
#ab -t 30 -n 5000 -c 100 -v 1 http://example.com/

apt -y install wrk
# WRK，t线程数 c并发连接数 d最大持续时间
# wrk -t12 -c600 -d60s http://example.com

# echo -e "\n\n\n 安装 fd 文件搜索工具，一个更好的 find 命令替代品，可以帮助你更快地查找文件，支持快速查找和过滤。"
# wget -O fd_8.4.0_amd64.deb https://p.ljz.one/https://github.com/sharkdp/fd/releases/download/v8.4.0/fd_8.4.0_amd64.deb
# dpkg -i  fd_8.4.0_amd64.deb

# 安装命令行提示工具
# curl -sS https://starship.rs/install.sh | sh
# echo 'eval "$(starship init bash)"' >> ~/.bashrc
# source ~/.bashrc
# 由于会需要输入y确认，所以先注释掉

echo -e "\n\n\n 安装 tldr 控制台命令的协作备忘单，用法tldr cp"
pip3 install tldr

echo -e "\n\n\n 安装 cht.sh 命令行查询"
apt -y install rlwrap
curl -s https://cht.sh/:cht.sh | tee /usr/local/bin/cht.sh && chmod +x /usr/local/bin/cht.sh

echo -e "\n\n\n 安装 thefuck 命令行自动纠正"
pip3 install thefuck --user

echo -e "\n\n\n 安装 bpytop资源监视器"
pip3 install psutil
pip3 install bpytop

echo -e "\n\n\n 安装 httpx，Python的下一代HTTP客户端"
pip3 install httpx
pip3 install 'httpx[cli]'

# echo -e "\n\n\n 安装跨平台系统监视工具，可以监视 CPU、内存、网络等方面的系统指标。"
pip3 install --user glances

# 安装GoTTY - 将您的终端共享为 Web 应用程序
wget https://p.ljz.one/https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
tar -xzf gotty_linux_amd64.tar.gz
mv gotty /usr/local/bin/
# 命令：gotty top


# 部署theia ide 
# https://theia--ide-org.translate.goog/docs/composing_applications?_x_tr_hist=true&_x_tr_sl=auto&_x_tr_tl=zh-CN&_x_tr_hl=zh-CN


# 文件发送工具：轻松安全地将内容从一台计算机发送到另一台计算机
curl https://getcroc.schollz.com | bash

}




install_supervisor(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Supervisor 进程管理器------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
pip3 install supervisor
echo -e "\n\n\n 生成配置文件"
mkdir /etc/supervisor
echo_supervisord_conf > /etc/supervisor/supervisord.conf
echo -e "\n\n\n 编辑配置文件"
find '/etc/supervisor/supervisord.conf' | xargs perl -pi -e 's|;\[include\]|\[include\]|g'
find '/etc/supervisor/supervisord.conf' | xargs perl -pi -e 's|;files = relative/directory/\*\.ini|files = conf.d/*.ini|g'
echo -e "\n\n\n 创建子配置文件夹"
mkdir -p /etc/supervisor/conf.d

# python3 -m http.server -d /home/share

echo -e "\n\n\n 将 Supervisor 启动命令添加到 rc.local 中开机自动执行"
echo supervisord -c /etc/supervisor/supervisord.conf>>/etc/rc.local
supervisord -c /etc/supervisor/supervisord.conf

}

create_service(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name command working_dir"
return; fi
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name "command" working_dir"
return; fi
app_name=$1
command=$2
working_dir=${3:-"/usr/local/bin/"}

cat>/etc/supervisor/conf.d/${app_name}.ini<<EOF
[program:${app_name}]
directory=${working_dir}
command=${command}
;user=root
autostart=true
autorestart=true       ; 如果进程终止,自动重启
;startsecs=10          ; 进程启动后等待n秒钟如果没有退出则视为启动成功
;priority=999          ; 启动优先级
stderr_logfile=/var/log/${app_name}.err
stdout_logfile=/var/log/${app_name}.log
;stdout_logfile_maxbytes=2MB
;stderr_logfile_maxbytes=2MB
;environment=CODENATION_ENV=prod,DEBUG=false,ENVIRONMENT=production
;numprocs=1            ; 启动进程数
;startretries=3        ; 启动重试次数
;process_name=%(program_name)s_%(process_num)02d
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Docker------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

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
echo  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://p.ljz.one/https://download.docker.com/linux/${OSID} "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo -e "\n\n\n 更新APT包索引"
apt-get update
echo -e "\n\n\n 安装 Docker Engine、containerd 和 Docker Compose"
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

}

install_python(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} version"
return; fi
echo -e "\n\n\n------------------------------安装 Python------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
version=${1:-3.9.13}
short_version=${version%%.*}
apt -y install build-essential zlib1g zlib1g-dev libffi-dev
wget https://www.python.org/ftp/python/${version}/Python-${version}.tgz
tar xzvf Python-${version}.tgz
cd Python-${version}
./configure --prefix=/usr/local/bin --with-ssl
make && make install
ln -s  /usr/local/bin/python${short_version} /usr/bin/python3
ln -s  /usr/local/bin/pip3 /usr/bin/pip3
cd ..

pip install --upgrade certifi
pip install pyopenssl

}

install_nodejs(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Nodejs------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
apt -y install npm
# 使用版本管理器安装nodejs https://learn.microsoft.com/zh-cn/windows/dev-environment/javascript/nodejs-on-wsl?source=recommendations
curl -o- https://p.ljz.one/https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | sed -E 's#(https?://)#https://p.ljz.one/\1#g' /etc/apt/sources.list | bash

# 运行以下操作可以不用重启终端就能使用nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts
# 全局安装yarn
npm install -g yarn

# 查看全局包，并且只显示顶级包，而不会列出其依赖项
#npm list -g --depth 0

# npm config set registry https://registry.npmjs.org/
# npm config set registry https://registry.npm.taobao.org

}


install_mysql(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 MySQL------------------------------"
echo "是否继续？ (y)"
read -t 10 answer
if [ "$answer" = "y" ]; then

# #https://mariadb.com/kb/en/getting-installing-and-upgrading-mariadb/
# #安装MariaDB GPG密钥
# sudo apt-get install software-properties-common dirmngr
# sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
# # 添加MariaDB官方软件包源
# sudo add-apt-repository 'deb [arch=amd64] http://ftp.ubuntu-tw.org/mirror/mariadb/repo/10.3/debian buster main'
# echo -e "\n\n\n 安装 MariaDB"
# apt -y install MariaDB-client mariadb-server
# systemctl enable mariadb
# systemctl start mariadb

apt -y install lsb-release
# wget -O mysql-apt-config_0.8.24-1_all.deb https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
# dpkg -i mysql-apt-config_0.8.24-1_all.deb
wget -O mysql-apt-config_0.8.18-1_all.deb https://dev.mysql.com/get/mysql-apt-config_0.8.18-1_all.deb
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Redis------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
echo -e "\n\n\n 安装 redis-server"
apt -y install redis-server
sudo sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server

}

install_aria2(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Aria2------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
apt -y install aria2
mkdir /etc/aria2/
touch /etc/aria2/aria2.session
wget -O /etc/aria2/aria2.conf https://1fxdpq.dm.files.1drv.com/y4mIiwJL9lNeIdO8lXxaVlJ8CgaezUd3kIe7r8ZcAFytG78pUdSN0RprxwsYBW87AwMyXDAtEc3mLeTYBWHf_D4ngSWtjlCGvsoyA9YVs5Vs2X5taFFJmyl-5VgrMoj4EIKg0PsNXX-U6WC5INaaAK8fCrltwvj0lM0cRW0CuHSfxyAJZ0HaNph3kBqMCrtTwO5M_XR22RkpTRzolxlli3TxQ

echo -e "\n\n\n 使用 systemd 守护 Aria2c RPC Server 进程"
create_service aria2c "aria2c --conf-path=/etc/aria2/aria2.conf" /etc/aria2/
systemctl enable aria2c
systemctl restart aria2c
# 防火墙需要放行6800

}

install_filebrowser(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Web filebrowser------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
curl -fsSL https://p.ljz.one/https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash 
# filebrowser -r / -a 0.0.0.0 -p 8080
# 默认账户 admin / admin

}

deploy_tinyfilemanager(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
docker run -d -v /:/var/www/html/data -p 8020:80 --restart=always --name tinyfilemanager1 tinyfilemanager/tinyfilemanager:master
}

deploy_adminer(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
docker run -d --link mysql1:db --network network1 -p 8021:8080 --restart=always --name adminer1 adminer
}

install_alist(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 AList------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install /opt
systemctl restart alist
# 默认账号密码 admin/admin，端口5244

}

install_frp(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 Frp------------------------------"
echo -e "\n\n\n下载 Frp 二进制包"
wget --no-check-certificate -O frp_0.48.0_linux_amd64.tar.gz https://p.ljz.one/https://github.com/fatedier/frp/releases/download/v0.48.0/frp_0.48.0_linux_amd64.tar.gz
tar xzvf frp_0.48.0_linux_amd64.tar.gz -C /usr/local/bin/
mv /usr/local/bin/frp_0.48.0_linux_amd64 /usr/local/bin/frp

cat <<EOF > /usr/local/bin/frp/frps.ini
[common]
bind_addr = 0.0.0.0
bind_port = 7000

vhost_http_port = 8080

dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = admin

EOF

}

install_frps()
{
install_frp

echo -e "\n\n\n 使用 systemd 守护 Frps 进程"
create_service frps "/usr/local/bin/frp/frps -c /usr/local/bin/frp/frps.ini" /usr/local/bin/frp
systemctl enable frps
systemctl restart frps
}

start_frpc()
{
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} local_port:remote_port local_port:remote_port ..."
return; fi
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} local_port remote_port server_addr"
return; fi
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

if [ "$OSID" = "debian" ] || [ "$OSID" = "ubuntu" ]; then
    apt -y install openssh-server
elif [ "$OSID" = "alpine" ]; then
    apk add openssh-server
elif [ "$OSID" = "arch" ]; then
    pacman -S openssh-server
fi

sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
    echo "root:123qwe123@" | chpasswd

/usr/sbin/sshd

echo '请使用 ssh root@127.0.0.1 -p 22 连接'
}

systeminfo()
{
apt -y install lsb-release curl
uname -a && lsb_release -a && lscpu && cat /etc/os-release && hostnamectl && df -h && free -h && timedatectl && curl ipinfo.io
}



create_ssl(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name [acme_dir]"
return; fi

domain_name=$1

# acme_dir=${2:-/var/www/${domain_name}/.well-known/acme-challenge/} 
acme_dir=/var/www/challenges/${domain_name}/

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

mkdir -p "$acme_dir"

wget https://p.ljz.one/https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O $ACME_TINY -o /dev/null
python3 $ACME_TINY --account-key "$ACCOUNT_KEY" --csr "${DOMAIN_CSR}" --acme-dir "$acme_dir" > "$DOMAIN_CRT"


if [ ! -f "lets-encrypt-x3-cross-signed.pem" ];then
    wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -o /dev/null
fi
# 合并为公钥文件
cat "$DOMAIN_CRT" lets-encrypt-x3-cross-signed.pem > "$DOMAIN_CHAINED_CRT"

cat << EOF
在nginx网站配置的server块中添加以下内容:

    listen 443 ssl;
    ssl_certificate /var/ssl/${domain_name}.chained.crt;
    ssl_certificate_key /var/ssl/${domain_name}.key;
EOF
echo "Please restart nginx"
}


create_proxy(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then 
echo "Usage: ${FUNCNAME} domain_name local_port"; 
return; fi

domain_name=$1
local_port=$2

cat>${domain_name}.conf<<EOF
# 反向代理配置

# 引入 upstream 配置
#include upstream.conf;

# 定义反向代理
server {
    listen 80;
    listen  [::]:80;
    server_name ${domain_name};

    # 日志记录
    access_log /var/log/nginx/${domain_name}.access.log;
    error_log /var/log/nginx/${domain_name}.error.log;

    # 申请证书需要用到的配置
    location /.well-known/acme-challenge/ {
        alias /var/www/challenges/${domain_name}/;
        try_files \$uri =404;
    }

    location / {
        # 设置代理缓存
        #proxy_cache my_cache;
        #proxy_cache_valid 200 10m;

        # 负载均衡算法
        #proxy_pass http://my_upstream;

        #add_header Content-Security-Policy upgrade-insecure-requests;
        proxy_http_version 1.1;
        proxy_pass_header Server;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${local_port};

        # 安全配置
        # 设置请求头
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # if (\$scheme = http ) {
    #     return 301 https://\$host\$request_uri;
    # }

    # SSL/TLS 配置
    # listen 443 ssl;
    # ssl_certificate /var/ssl/${domain_name}.chained.crt;
    # ssl_certificate_key /var/ssl/${domain_name}.key;

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
echo "Please restart nginx"
}

create_vhost(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name"
return; fi

domain_name=$1
    
mkdir /var/www/${domain_name}
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
    root   /var/www/${domain_name};

    #access_log  /var/log/nginx/${domain_name}.access.log  main;

    # 申请证书需要用到的配置
    location /.well-known/acme-challenge/ {
        alias /var/www/challenges/${domain_name}/;
        try_files \$uri =404;
    }

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
echo '<?php echo phpinfo(); ?>' >> /var/www/${domain_name}/phpinfo.php
wget -O /var/www/${domain_name}/adminer.php https://p.ljz.one/https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
wget -O /var/www/${domain_name}/editor.php https://p.ljz.one/https://github.com/vrana/adminer/releases/download/v4.8.1/editor-4.8.1.php
wget -O /var/www/${domain_name}/tinyfilemanager.php https://p.ljz.one/https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
wget -O /var/www/${domain_name}/index.php https://p.ljz.one/https://raw.githubusercontent.com/lorenzos/Minixed/master/index.php
wget -O /var/www/${domain_name}/shell.php https://p.ljz.one/https://raw.githubusercontent.com/artyuum/simple-php-web-shell/master/index.php

# wget -O phpMyAdmin.zip https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
# unzip -d /var/www/${domain_name} phpMyAdmin.zip > /dev/null
# mv /var/www/${domain_name}/phpMyAdmin-5.2.1-all-languages /var/www/${domain_name}/phpMyAdmin
# mv /var/www/${domain_name}/phpMyAdmin/config.sample.inc.php /var/www/${domain_name}/phpMyAdmin/config.inc.php && chmod 755 /var/www/${domain_name}/phpMyAdmin/config.inc.php
# sed -i "s/localhost/mysql/g" /var/www/${domain_name}/phpMyAdmin/config.inc.php

#https://cn.wordpress.org/latest-zh_CN.zip
#https://p.ljz.one/https://github.com/typecho/typecho/releases/latest/download/typecho.zip


chown -R www-data:www-data /var/www/${domain_name}
chmod -R 777 /var/www/${domain_name}
}

create_database(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} domain_name"
return; fi
domain_name=$1
MYSQL_ROOT_PASSWORD=$(cat MYSQL_ROOT_PASSWORD.txt)

# 将创建数据库的sql语句写入sql文件并通过-i参数和<输入重定向符号传递给容器内的命令执行
db_password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
db_user=${domain_name//./_}
cat>${domain_name}.sql<<EOF
CREATE DATABASE ${db_user}_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
CREATE USER '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_user}_db.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
EOF

cmd="mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${domain_name}.sql"
echo "请执行${cmd}创建数据库和用户 mysql://${db_user}:${db_password}@mysql:3306/${db_user}_db"
echo "在容器内创建需执行 docker exec -i mysql1 ${cmd}"

}


deploy_mysql(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [port]"
return; fi
port=${1:-3306}
docker network create network1

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
echo "${MYSQL_ROOT_PASSWORD}" > MYSQL_ROOT_PASSWORD.txt

echo "安装 MySQL"
# docker run -dp ${port}:3306 --name mysql1 --restart=always --network network1 --network-alias mysql -v /docker/mysql:/var/lib/mysql \
# -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
# -e TZ=Asia/Shanghai \
# -e MYSQL_USER=user1 \
# -e MYSQL_PASSWORD=123 \
# -e MYSQL_DATABASE=db1 \
# -e MYSQL_CHARSET=utf8mb4 \
# -e MYSQL_COLLATION=utf8mb4_unicode_ci \
# mysql:5.7-debian \
# --character-set-server=utf8mb4 \
# --collation-server=utf8mb4_unicode_ci

docker run -dp ${port}:3306 --name mysql1 --restart=always --network network1 --network-alias mysql -v /docker/mysql:/var/lib/mysql \
--env MARIADB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
--env TZ=Asia/Shanghai \
--env MARIADB_USER=user1 \
--env MARIADB_PASSWORD=123 \
--env MARIADB_DATABASE=db1 \
--env MARIADB_CHARSET=utf8mb4 \
--env MARIADB_COLLATION=utf8mb4_unicode_ci \
mariadb:10.3-focal \
--character-set-server=utf8mb4 \
--collation-server=utf8mb4_unicode_ci

}

deploy_redis(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [port]"
return; fi
port=${1:-6379}
docker network create network1

echo "安装 Redis" 
docker run -dp ${port}:6379 --name redis1 --restart=always --network network1 --network-alias redis -v /docker/redis1:/data \
redis:6-bullseye \
redis-server --save 60 1 --loglevel warning --requirepass "123qwe123@"
# 传给redis服务器的启动参数：若每60秒至少有一个键被修改了1次，就将数据持久化到磁盘，只记录警告及更高级别的日志
# 连接字符串
# redis://default:123qwe123@@localhost:6379/0
# 连接方式：redis-cli
# docker run -it --network redis --rm redis redis-cli -h redis1
}

deploy_nginx(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo "安装 Nginx"
docker run -d --name nginx1 --restart=always --network host -v /var/www:/var/www -v /var/ssl:/var/ssl -v /etc/nginx/conf.d:/etc/nginx/conf.d nginx:stable-bullseye
}

deploy_php_fpm(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [local_port]"
return; fi
local_port=${1:-9000}
echo -e "\n\n\n------------------------------部署PHP和扩展------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

docker network create network1

echo "安装 PHP"
docker run -d -p 127.0.0.1:${local_port}:9000 --name php-fpm1 --restart=always --network network1 -v /var/www:/var/www php:7.4-fpm-bullseye

docker exec -t php-fpm1 sh -c "sed -i -E 's#(https?://)#https://p.ljz.one/\1#g' /etc/apt/sources.list"


# 使用这个必须 -v /var/www:/var/www/html，否则nginx连不上php-fpm，日志报错[error] 20#20: *5 recv() failed (104: Connection reset by peer) while reading response header from upstream
#docker run -d -p 127.0.0.1:9000:9000 --name php1 --network network1 -v /docker/php1:/usr/local/etc -v /var/www:/var/www/html webdevops/php:7.4-alpine

echo "安装 PHP扩展"
# https://github.com/docker-library/wordpress/blob/97f75b51f909fbd9894d128ea6893120cfd23979/latest/php8.0/fpm/Dockerfile#L10-L16
# https://make.wordpress.org/hosting/handbook/server-environment/

# https://github.com/docker-library/wordpress/blob/97f75b51f909fbd9894d128ea6893120cfd23979/latest/php7.4/fpm-alpine/Dockerfile
# docker exec -t php-fpm1 apk update
# docker exec -t php-fpm1 apk add --no-cache bash ghostscript imagemagick 
# docker exec -t php-fpm1 apk add --no-cache --virtual .build-deps freetype-dev icu-dev imagemagick-dev libjpeg-turbo-dev libpng-dev libwebp-dev libzip-dev
# docker exec php-fpm1 apk add build-base autoconf

docker exec -t php-fpm1 apt-get update
docker exec -t php-fpm1 apt-get install -y --no-install-recommends libfreetype6-dev libicu-dev libjpeg-dev libmagickwand-dev libpng-dev libwebp-dev libzip-dev

docker exec -t php-fpm1 docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# 用 docker-php-ext-install 安装扩展
docker exec -t php-fpm1 docker-php-ext-install -j "$(nproc)" bcmath exif gd intl mysqli zip pdo_mysql soap bz2 gettext sockets ldap

# 用 pecl 安装扩展
docker exec php-fpm1 pecl install imagick-3.6.0 redis
docker exec php-fpm1 docker-php-ext-enable imagick redis
docker exec -t php-fpm1 rm -r /tmp/pear

#docker exec -t php-fpm1 apt-get install -y libbz2-dev sqlite3 libsqlite3-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libonig-dev libreadline-dev libtidy-dev libxslt-dev libzip-dev
# docker-php-ext-install 全部可安装扩展
#docker exec -t php-fpm1 docker-php-ext-install bcmath bz2 calendar ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp hash iconv imap intl json ldap mbstring mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection session shmop simplexml snmp soap sockets sodium spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlrpc xmlwriter xsl zend_test zip

docker restart php-fpm1

}


install_phpfpm(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------安装 PHP FPM------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
apt -y install php-fpm composer 
# 安装php扩展
apt -y install php-json php-mbstring php-mysql php-xml php-zip php-curl php-imagick php-gd file php-pear php-redis php-sqlite3 php-mongodb php-bcmath php-soap php-intl php-igbinary php-xdebug
# systemctl enable php8.2-fpm
# systemctl start php8.2-fpm

#curl -sS https://getcomposer.org/installer | php

}


deploy_wordpress_fpm(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 Wordpress FPM 和 Nginx 配合------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

domain_name=${1:-blog.iapp.run}
local_port=${2:-9001}
create_database ${domain_name}

docker run -dp 127.0.0.1:${local_port}:9000 --name wordpress1 --restart=always --network network1 -v /var/www/${domain_name}:/var/www/html \
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
    root   /var/www/${domain_name};

    #access_log  /var/log/nginx/host.access.log  main;

    # 申请证书需要用到的配置
    location /.well-known/acme-challenge/ {
        alias /var/www/challenges/${domain_name}/;
        try_files \$uri =404;
    }

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
        fastcgi_pass   127.0.0.1:${local_port};
        fastcgi_index  index.php;
        # 在fastcgi process manager 容器里的脚本文件 根目录
        fastcgi_param  SCRIPT_FILENAME  /var/www\$fastcgi_script_name;
        include        fastcgi_params;
    }

}
EOF
docker cp ./${domain_name}.conf nginx1:/etc/nginx/conf.d/${domain_name}.conf
docker restart nginx1

}

deploy_wordpress(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 Wordpress------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

domain_name=${1:-blog.iapp.run}
local_port=${2:-8010}
docker run -dp 127.0.0.1:${local_port}:80 --name wordpress1 --restart=always --network network1 -v /docker/wordpress1:/var/www/html wordpress
create_proxy ${domain_name} ${local_port}
create_database ${domain_name}

}

deploy_portainer(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
echo -e "\n\n\n------------------------------部署 Portainer------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

# https://docs.portainer.io/start/install/server/docker/linux
docker volume create portainer_data
#docker run -d -p 127.0.0.1:9002:9000 --name portainer1 -v /var/run/docker.sock:/var/run/docker.sock -v /docker/portainer_data:/data portainer/portainer
# 汉化版
docker run -d -p 9002:9000 --name portainer1 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /docker/portainer_data:/data 6053537/portainer

domain_name=${1:-docker.iapp.run}
create_proxy ${domain_name} 9002

}

deploy_nextcloud(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 NextCloud------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

domain_name=${1:-cloud.iapp.run}
local_port=${2:-8011}
docker run -dp 127.0.0.1:${local_port}:80 --name nextcloud1 --restart=always --network network1  -v /docker/nextcloud:/var/www/html nextcloud
create_proxy ${domain_name} ${local_port}
#create_database ${domain_name}
# 用mysql性能不好

}

deploy_searxng(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 SearXNG------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
domain_name=${1:-s.iapp.run}
local_port=${2:-8012}
# https://docs.searxng.org/admin/installation-docker.html#searxng-searxng
docker run --rm \
-d -p 127.0.0.1:${local_port}:8080 \
--name searxng1 \
-v "/docker/searxng:/etc/searxng" \
-e "BASE_URL=http://${domain_name}/" \
-e "INSTANCE_NAME=元搜索" \
searxng/searxng

# 在settings.yml文件中设置默认启用的搜索引擎
create_proxy ${domain_name} ${local_port}

}

deploy_gitea(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port] [ssh_port]"
return; fi
echo -e "\n\n\n------------------------------部署 Gitea------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
domain_name=${1:-git.iapp.run}
local_port=${2:-3000}
ssh_port=${3:-222}
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
--restart=always \
-p 127.0.0.1:${local_port}:3000 -p ${ssh_port}:22 \
-e USER_UID=$(id -u git) \
-e USER_GID=$(id -g git) \
-v /docker/gitea:/data  \
-v /etc/timezone:/etc/timezone:ro \
-v /etc/localtime:/etc/localtime:ro  \
gitea/gitea:1.19

create_proxy ${domain_name} ${local_port}

# 记得配置SSH_PORT=222，SSH_LISTEN_PORT=22

# ssh://git@git.iapp.run:222/zero-ljz/repo.git

}

deploy_cloudreve(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [port]"
return; fi
echo -e "\n\n\n------------------------------部署 CloudReve------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
domain_name=${1:-c.iapp.run}
port=${2:-5212}
mkdir -vp /docker/cloudreve/{uploads,avatar} && touch /docker/cloudreve/conf.ini && touch /docker/cloudreve/cloudreve.db

docker run -d \
-p ${port}:5212 \
--name cloudreve1 \
--restart=always \
--mount type=bind,source=/docker/cloudreve/conf.ini,target=/cloudreve/conf.ini \
--mount type=bind,source=/docker/cloudreve/cloudreve.db,target=/cloudreve/cloudreve.db \
-v /docker/cloudreve/uploads:/cloudreve/uploads \
-v /docker/cloudreve/avatar:/cloudreve/avatar \
cloudreve/cloudreve:latest

create_proxy ${domain_name} ${port}

}

deploy_gocron(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 GoCron------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

domain_name=${1:-cron.iapp.run}
local_port=${2:-5920}
docker run --name gocron1 --restart=always --network network1 -p 127.0.0.1:${local_port}:5920 -d ouqg/gocron

create_proxy ${domain_name} ${local_port}
create_database ${domain_name}

}


deploy_hackmd(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} [domain_name] [local_port]"
return; fi
echo -e "\n\n\n------------------------------部署 HackMD------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
domain_name=${1:-md.iapp.run}
local_port=${2:-3001}
# https://hackmd.io/c/codimd-documentation/%2Fs%2Fcodimd-docker-deployment
docker run -d \
-p 127.0.0.1:${local_port}:3000 \
--name hackmd1 \
--network network1 \
-e CMD_DB_URL=mysql://user1:123@mysql:3306/db1 \
-e CMD_USECDN=false \
-v /docker/hackmd/upload-data:/home/hackmd/app/public/uploads \
hackmdio/hackmd:2.4.2

create_proxy ${domain_name} ${local_port}
create_database ${domain_name}


}


deploy_php_app() {
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name http_port"
return; fi

app_name=$1
http_port=$2
docker run -d -p "${http_port}":80 --name ${app_name} -v "/docker/${app_name}":/var/www/html php:7.4-apache
wget -O /docker/${app_name}/adminer.php https://p.ljz.one/https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
wget -P /docker/${app_name} https://p.ljz.one/https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
}

# docker restart nginx1

deploy_debian() {
# 创建空的 Debian 容器并保持运行
docker run -d --name debian1 --network host debian:bullseye-slim tail -f /dev/null

commands=$(cat <<EOF

apt update
apt -y install wget curl nano micro

EOF
)
docker exec debian1 bash -c "$commands"

docker exec -it debian1 bash
}

deploy_python_app() {
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} app_name http_port repo_url command"
return; fi
# docker rm -f iapp2
# bash fast.sh deploy_python_app iapp2 8000 https://p.ljz.one/https://github.com/zero-ljz/iapp.git
app_name=$1
http_port=${2:-8000}
repo_url=${3}
command=${4:-"python /app/app.py"}
docker run -d -p "${http_port}":8000 --name ${app_name} python:3.9.13-bullseye tail -f /dev/null

commands=$(cat <<EOF

apt update
apt -y install git wget
mkdir -p /app
git clone ${repo_url} /app
python -m pip install -r /app/requirements.txt
${command}

EOF
)
docker exec ${app_name} bash -c "$commands"

docker exec -it ${app_name} bash
}
# 3.11-alpine3.17
#docker run -it --rm --name py1 -v $PWD:/usr/src/myapp -w /usr/src/myapp python:3.9.13-slim-bullseye python app.py
#docker run -it --rm --name php1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp php:7.4-cli php app.php
#docker run -it --rm --name node1 -v "$PWD":/usr/src/app -w /usr/src/app node:18-bullseye-slim node app.js



function run_from_git(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: ${FUNCNAME} repo_url port_port"
return; fi
  url=$1
  p=$2

  # bash /root/fast.sh run_from_git https://p.ljz.one/https://github.com/zero-ljz/iapp.git 777:8000
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
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    read -p "请输入新的root密码：" password
    curl -fLO https://p.ljz.one/https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && chmod a+rx debi.sh && ./debi.sh --version 11 --cdn --network-console --ethx --bbr --timezone Asia/Shanghai --user root --password ${password}
}


function auto_mode(){
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    system_init
    install_supervisor
    install_docker
    install_frps
    # install_aria2
    install_nodejs

    deploy_mysql
    deploy_redis
    deploy_nginx
    deploy_php_fpm
    deploy_tinyfilemanager
    deploy_adminer






    # deploy_debian

    # deploy_portainer
    # deploy_cloudreve
    # deploy_searxng
    
}

upgrade()
{
if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
    echo "Description: Upgrade this script, Perform this operation in the working directory"
    exit 0
fi
bash -c 'wget --no-cache -O fast.sh https://p.ljz.one/https://raw.githubusercontent.com/zero-ljz/scripts/main/shell/fast.sh && bash fast.sh'
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

