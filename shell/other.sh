
# 允许root用户登录
#sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "/etc/ssh/sshd_config"
# 允许使用密码登录
#sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "/etc/ssh/sshd_config"

# 允许ssh端口转发
#sed -i 's/^#*AllowTcpForwarding\s\+.*$/AllowTcpForwarding yes/' /etc/ssh/sshd_config
#sed -i 's/^#*GatewayPorts\s\+.*$/GatewayPorts yes/' /etc/ssh/sshd_config
#systemctl restart sshd
# 内网穿透客户端连接方式，0代表随机分配端口，R表示远程转发，N表示禁止执行远程命令，T表示禁止分配伪终端
#ssh -NTR 0:localhost:8000 root@iapp.run
# 另一种方式，支持自动重连，-M 指定监视通道端口，以便监控SSH连接的状态
#apt install autossh
#sshpass -p "123123" autossh -o StrictHostKeyChecking=no -M 2345 -NTR 0:localhost:8000 root@iapp.run

#rm -rf /docker
#docker rm -f $(docker ps -a -q)



if [ ! -e "/usr/local/bin/fast" ]; then
echo -e "已将脚本链接到全局命令 fast"
ln -sf $(pwd)/fast.sh /usr/local/bin/fast && chmod +x /usr/local/bin/fast
fi



if [ ! -e "/tmp/ip_country" ]; then
# 首次需要获取服务器所在国家并缓存
apt -y install jq
IP_COUNTRY=$(curl -s https://ipinfo.io/$(curl -s https://api.ipify.org) | jq '.country' | sed 's/"//g')
echo $IP_COUNTRY > /tmp/ip_country
else
IP_COUNTRY=$(cat /tmp/ip_country)
fi

if [ "$OS_ID" = "CN" ]; then

# 默认代理设置
proxy="http://p.520999.xyz/"



cat>~/.config/pip/pip.conf<<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple
EOF
# 或者用命令
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple

fi



# apt-get update
# apt-get install iptables-persistent

# # root用户端口 1:1023
# # 开放单个端口 -A INPUT -p tcp --dport 80 -j ACCEPT
# echo "-A INPUT -p tcp --match multiport --dports 1:65535 -j ACCEPT" >> /etc/iptables/rules.v4

# service netfilter-persistent save
# service netfilter-persistent reload
# #systemctl restart networking



# 在输出中将所有url加上指定前缀
#| sed -E "s#(https?://)#${proxy}\1#g" 

docker exec -t php-fpm1 sh -c "sed -i -E 's#(https?://)#${proxy}\1#g' /etc/apt/sources.list"

# sed -i -E 's#(https?://)#${proxy}\1#g' /etc/apt/sources.list

# sed -i -E 's#(https?://)#${proxy}\1#g' /etc/apt/sources.list


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

install_frp(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 Frp------------------------------"
    echo -e "\n\n\n下载 Frp 二进制包"
    wget --no-check-certificate -O frp_0.58.0_linux_amd64.tar.gz https://github.com/fatedier/frp/releases/download/v0.58.0/frp_0.58.0_linux_amd64.tar.gz
    tar xzvf frp_0.58.0_linux_amd64.tar.gz -C /usr/local/bin/
    mv /usr/local/bin/frp_0.58.0_linux_amd64 /usr/local/bin/frp

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

    if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
        apt -y install openssh-server
    elif [ "$OS_ID" = "alpine" ]; then
        apk add openssh-server
    elif [ "$OS_ID" = "arch" ]; then
        pacman -S openssh-server
    fi

    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
        ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
        ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
        ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
        ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
        echo "root:123qwe123@" | chpasswd
        
    # sed -i 's/#Port 22/Port 222/g' /etc/ssh/sshd_config
    # chmod 0755 /var/run/sshd
    # service ssh restart

    /usr/sbin/sshd

    echo '请使用 ssh root@127.0.0.1 -p 22 连接'
}



systeminfo()
{
    apt -y install lsb-release curl
    uname -a && lsb_release -a && lscpu && cat /etc/os-release && hostnamectl && df -h && free -h && timedatectl && curl ipinfo.io
}



install_python(){
    # 编译安装python
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} version"
    return; fi
    # https://devguide.python.org/getting-started/setup-building/index.html#install-dependencies
    # https://docs.python.org/dev/using/unix.html
    echo -e "\n\n\n------------------------------安装 Python------------------------------"
    echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    version=${1:-3.10.11}
    short_version=${version%%.*} # 3
    # 启用源代码包
    sh -c 'echo "deb-src https://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list'
    # 安装python运行时依赖项
    apt-get update
    apt-get build-dep python3
    apt-get -y install build-essential gdb lcov pkg-config \
        libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
        libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
        lzma lzma-dev tk-dev uuid-dev zlib1g-dev
    # apt -y install build-essential zlib1g zlib1g-dev libffi-dev
    wget https://www.python.org/ftp/python/${version}/Python-${version}.tgz
    tar xzvf Python-${version}.tgz
    cd Python-${version}
    ./configure --prefix=/usr/local --with-ssl
    make && make install
    ln -s  /usr/local/bin/python3 /usr/bin/python
    ln -s  /usr/local/bin/pip3 /usr/bin/pip3
    ln -s  /usr/local/bin/pip3 /usr/bin/pip

    # pip3 install --upgrade certifi
    # pip3 install pyopenssl

    # wget https://bootstrap.pypa.io/get-pip.py -o get-pip.py | python3

}

install_mariadb(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 MariaDB------------------------------"
    echo "是否继续？ (y)"
    read -t 10 answer
    if [ "$answer" = "y" ]; then
        #https://mariadb.com/kb/en/getting-installing-and-upgrading-mariadb/
        #安装MariaDB GPG密钥
        apt-get install software-properties-common dirmngr
        apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
        # 添加MariaDB官方软件包源
        add-apt-repository 'deb [arch=amd64] http://ftp.ubuntu-tw.org/mirror/mariadb/repo/10.4/debian bullseye main'
        echo -e "\n\n\n 安装 MariaDB"
        apt -y install mariadb-client mariadb-server
        systemctl enable mariadb
        systemctl start mariadb
    fi
}

install_redis(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 Redis------------------------------"
    echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    echo -e "\n\n\n 安装 redis-server"
    apt -y install redis-server
    sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf

    systemctl enable redis-server
    systemctl restart redis-server

}

install_nginx(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo "安装 Nginx"
    apt -y install nginx
    # 选择conf.d为子配置文件夹，将sites-enabled注释掉
    find '/etc/nginx/nginx.conf' | xargs perl -pi -e 's|include /etc/nginx/sites-enabled/\*;|#include /etc/nginx/sites-enabled/*;|g'

    create_default_vhost
    service nginx restart
}

install_mysql() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 MySQL------------------------------"
    echo "是否继续？ (y)"
    read -t 10 answer
    if [ "$answer" = "y" ]; then
        apt update && apt -y install wget lsb-release gnupg
        # mysql 8.0
        wget --no-check-certificate https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
        dpkg -i mysql-apt-config_0.8.29-1_all.deb

        apt update && apt -y install mysql-client mysql-server

        systemctl enable mysql
        systemctl start mysql

        echo '
        使用以下命令 设置 MySQL 安全选项
        mysql_secure_installation
        '

        echo '
        使用以下命令连接到MySQL服务器
        mysql -h 127.0.0.1 -P 3306 -u root -p
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


    # echo -e "\n\n\n配置防火墙"
    #  apt -y install ufw
    
    #  ufw allow ssh
    #  ufw allow http
    #  ufw allow https
    #  ufw allow mysql
    #  ufw allow 8000:8100/tcp
    #  ufw allow 10000:20000/tcp
    #  ufw allow 1024:65535/tcp

    # ufw deny 9000


    # ufw enable
    # ufw reload


    # 查看所有规则编号
    # ufw status numbered
    # ufw delete allow 端口号或者编号
    # ufw disable
    # ufw enable
    # ufw reset



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

    # 静态资源路径，必须是在nginx容器内有效的路径
    root   /var/www/${domain_name};

    #access_log  /var/log/nginx/${domain_name}.access.log  main;

    # if (\$scheme = http ) {
    #     return 301 https://\$host\$request_uri;
    # }

    #listen 443 ssl;
    #ssl_certificate /var/ssl/${domain_name}.chained.crt;
    #ssl_certificate_key /var/ssl/${domain_name}.key;

    # 申请证书需要用到的配置
    location /.well-known/acme-challenge/ {
        alias /var/www/challenges/${domain_name}/;
        try_files \$uri =404;
    }

    location / {
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$args;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # 将 PHP 脚本传递给在 127.0.0.1:9000 上侦听的 FastCGI 服务器
    #
    location ~ \.php$ {
        # include snippets/fastcgi-php.conf;
        # 以下为 snippets/fastcgi-php.conf 中的内容
        # regex to split $uri to $fastcgi_script_name and $fastcgi_path
        fastcgi_split_path_info ^(.+?\.php)(/.*)\$;

        # Check that the PHP script exists before passing it
        try_files \$fastcgi_script_name =404;

        # Bypass the fact that try_files resets $fastcgi_path_info
        # see: http://trac.nginx.org/nginx/ticket/321
        set \$path_info \$fastcgi_path_info;
        fastcgi_param PATH_INFO \$path_info;

        fastcgi_index index.php;

        # PHP脚本文件路径，document_root表示使用静态资源相同目录，目录路径必须是在php-fpm容器内有效的目录路径
        fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;

        fastcgi_param PHP_VALUE "post_max_size=100M
                max_execution_time=3600
                upload_max_filesize=100M
                memory_limit=256M";

        # 本地安装的php-fpm默认是只能通过套接字通信，且只能和本地安装的nginx通信，非nginx容器
        fastcgi_pass unix:/run/php/php-fpm.sock;
        # fastcgi_pass   127.0.0.1:9000;
    }

    # 设置请求大小限制
    client_max_body_size 100m;

}
EOF
    #docker cp ./${domain_name}.conf nginx1:/etc/nginx/conf.d/${domain_name}.conf
    cp ${domain_name}.conf /etc/nginx/conf.d/${domain_name}.conf

    download_php_apps /var/www/${domain_name}

    chown -R www-data:www-data /var/www/${domain_name}
    chmod -R 777 /var/www/${domain_name}

    systemctl restart nginx
    docker restart nginx1
}

download_php_apps(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} root_dir"
    return; fi

    root_dir=$1
    echo "远程下载默认网站 源码文件"
    echo '<?php echo phpinfo(); ?>' >> ${root_dir}/phpinfo.php
    wget -O ${root_dir}/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
    wget -O ${root_dir}/editor.php https://github.com/vrana/adminer/releases/download/v4.8.1/editor-4.8.1.php

    wget -O ${root_dir}/tinyfilemanager.php https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
    sed -i "s/use_auth = true/use_auth = false/g" ${root_dir}/tinyfilemanager.php

    wget -O ${root_dir}/index.php https://raw.githubusercontent.com/lorenzos/Minixed/master/index.php

    wget -O ${root_dir}/fast.php https://raw.githubusercontent.com/zero-ljz/scripts/main/php/fast.php

    wget -P ${root_dir} https://github.com/nickola/web-console/releases/download/v0.9.7/webconsole-0.9.7.zip
    unzip -d ${root_dir} ${root_dir}/webconsole-0.9.7.zip
    mv ${root_dir}/webconsole/webconsole.php ${root_dir}/webconsole.php
    sed -i "s/NO_LOGIN = false/NO_LOGIN = true/g" ${root_dir}/webconsole.php # 开启免登录
    rm -rf ${root_dir}/webconsole-0.9.7.zip ${root_dir}/webconsole

    # wget -O phpMyAdmin.zip https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
    # unzip -d ${root_dir} phpMyAdmin.zip > /dev/null
    # mv ${root_dir}/phpMyAdmin-5.2.1-all-languages ${root_dir}/phpMyAdmin
    # mv ${root_dir}/phpMyAdmin/config.sample.inc.php ${root_dir}/phpMyAdmin/config.inc.php && chmod 755 ${root_dir}/phpMyAdmin/config.inc.php
    # sed -i "s/localhost/mysql/g" ${root_dir}/phpMyAdmin/config.inc.php

    #https://cn.wordpress.org/latest-zh_CN.zip
    #https://github.com/typecho/typecho/releases/latest/download/typecho.zip
}


deploy_memcached(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} [port]"
    return; fi
    port=${1:-11211}
    docker network create network1

    echo "安装 Memcached" 
    docker run -dp ${port}:11211 --name memcached1 --restart=always --network network1 --network-alias memcached -v /docker/memcached1:/data -e TZ=Asia/Shanghai \
    memcached:bullseye
}

deploy_mongo(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} [port]"
    return; fi
    port=${1:-27017}
    docker network create network1

    echo "安装 MongoDB"
    docker run -dp ${port}:27017 --name mongo1 --restart=always --network network1 --network-alias mongo -v /docker/mongo1:/data/db -e TZ=Asia/Shanghai \
    -e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
    -e MONGO_INITDB_ROOT_PASSWORD=123qwe123@ \
    mongo:jammy

    # mongodb://admin:password@localhost:27017
}

deploy_mongo_express(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} [port]"
    return; fi
    port=${1:-8081}

    echo "安装 mongo-express"
    docker run -dp ${port}:8081 --name mongo-express1 --restart=always --network network1 \
    -e ME_CONFIG_MONGODB_SERVER=mongo \
    -e ME_CONFIG_MONGODB_ADMINUSERNAME='mongoadmin' \
    -e ME_CONFIG_MONGODB_ADMINPASSWORD='123qwe123@' \
    -e ME_CONFIG_BASICAUTH_USERNAME=admin \
    -e ME_CONFIG_BASICAUTH_PASSWORD=123qwe123@ \
    mongo-express
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
    docker run -d -p 127.0.0.1:${local_port}:9000 --name php-fpm1 --restart=always --network network1 -v /var/www:/var/www -e TZ=Asia/Shanghai php:7.4-fpm-bullseye




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
    docker exec -t php-fpm1 docker-php-ext-install -j "$(nproc)" bcmath exif gd intl mysqli zip  pdo_mysql soap bz2 gettext sockets

    # 用 pecl 安装扩展
    docker exec php-fpm1 pecl install imagick-3.6.0 redis
    docker exec php-fpm1 docker-php-ext-enable imagick redis
    docker exec -t php-fpm1 rm -r /tmp/pear

    #docker exec -t php-fpm1 apt-get install -y libbz2-dev sqlite3 libsqlite3-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libonig-dev libreadline-dev libtidy-dev libxslt-dev libzip-dev
    # docker-php-ext-install 全部可安装扩展
    #docker exec -t php-fpm1 docker-php-ext-install bcmath bz2 calendar ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp hash iconv imap intl json ldap mbstring mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection session shmop simplexml snmp soap sockets sodium spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlrpc xmlwriter xsl zend_test zip

    docker restart php-fpm1

}


install_php_fpm(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 PHP FPM------------------------------"
    echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    apt -y install php-fpm composer 
    # 安装php扩展
    apt -y install php-json php-mbstring php-mysql php-xml php-zip php-curl php-imagick php-gd file php-pear php-redis php-sqlite3 php-mongodb php-bcmath php-soap php-intl php-igbinary php-xdebug

    mkdir -p /run/php/
    #直接后台启动命令 php-fpm7.4

    # systemctl enable php7.4-fpm
    # systemctl start php7.4-fpm
    systemctl enable php8.2-fpm
    systemctl start php8.2-fpm

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
    local_port=${2:-9000}
    create_database ${domain_name}

    docker run -dp 127.0.0.1:${local_port}:9000 --name wordpress1 --restart=always --network network1 -v /var/www/${domain_name}:/var/www/html -e TZ=Asia/Shanghai \
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

    systemctl restart nginx
    docker restart nginx1
}


deploy_nextcloud(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ $1 = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ${FUNCNAME} [local_port]"
    return; fi
    echo -e "\n\n\n------------------------------部署 NextCloud------------------------------"
    echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local_port=${1:-8000}
    docker run -dp 127.0.0.1:${local_port}:80 --name nextcloud1 --restart=always --network network1  -v /docker/nextcloud:/var/www/html -e TZ=Asia/Shanghai nextcloud

    # 用mysql性能不好

}



install_utils(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装一些实用的命令行程序------------------------------"
    echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    # 更多命令行工具 
    # https://github.com/rothgar/awesome-tuis
    # https://github.com/ibraheemdev/modern-unix

    apt -y install mc

    # echo -e "\n\n\n 安装适用于 API 时代的现代、用户友好的命令行 HTTP 客户端"
    pip3 install httpie
    # echo -e "\n\n\n 安装数据库第三方命令行工具。"
    pip3 install mycli litecli iredis

    # filebrowser
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash 
    # filebrowser -r / -a 0.0.0.0 -p 8080
    # 默认账户 admin / admin

    # webssh
    pip install webssh
    # wssh --address='0.0.0.0' --port=8888 --fbidhttp=False

    # 文件发送工具：轻松安全地将内容从一台计算机发送到另一台计算机
    curl https://getcroc.schollz.com | bash
    # 发 croc send --code 123123 [file(s)-or-folder]
    # 收 croc 123123

    # alist
    # curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install /opt
    # cd /opt/alist
    # ./alist admin set 123123
    # systemctl restart alist
    # nano /opt/alist/data/config.json
    # 默认端口5244

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
    # echo -e "\n\n\n 安装命令行 JSON 处理器，可以帮助您以可读的方式解析和格式化 JSON 数据。"
    # apt -y install jq
    # echo -e "\n\n\n 安装实时网络带宽监控器。"
    # apt -y install bmon

    # echo -e "\n\n\n 安装网络扫描工具，用于检测主机和服务。其他替代品：masscan"
    # apt -y install nmap

    echo -e "\n\n\n 安装可帮助您在终端中以树形结构显示目录结构。"
    apt -y install tree


    # echo -e "\n\n\n 安装 exa 替代ls，一个更好的 ls 命令替代品，可以帮助你更好地查看文件和目录的详细信息。"
    # if [ "$OS_ID" = "ubuntu" ]; then
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

    # apt -y install apache2-utils
    # Apache Benchmarking Tool，t最大持续时间 n总请求数 c并发连接数 v信息详细程度
    #ab -t 30 -n 5000 -c 100 -v 1 http://example.com/

    apt -y install wrk
    # WRK，t线程数 c并发连接数 d最大持续时间
    # wrk -t12 -c600 -d60s http://example.com

    # echo -e "\n\n\n 安装 fd 文件搜索工具，一个更好的 find 命令替代品，可以帮助你更快地查找文件，支持快速查找和过滤。"
    # wget -O fd_8.4.0_amd64.deb https://github.com/sharkdp/fd/releases/download/v8.4.0/fd_8.4.0_amd64.deb
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
    # pip3 install --user glances

    # 安装GoTTY - 将您的终端共享为 Web 应用程序
    # wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
    # tar -xzf gotty_linux_amd64.tar.gz
    # mv gotty /usr/local/bin/
    # 命令：gotty top


    # 部署theia ide 
    # https://theia--ide-org.translate.goog/docs/composing_applications?_x_tr_hist=true&_x_tr_sl=auto&_x_tr_tl=zh-CN&_x_tr_hl=zh-CN

}


function reinstall_debian(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
        read -p "请输入新的root密码：" password
        curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && chmod a+rx debi.sh && ./debi.sh --version 11 --cdn --network-console --ethx --bbr --timezone Asia/Shanghai --user root --password ${password}
}