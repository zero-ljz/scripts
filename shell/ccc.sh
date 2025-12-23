#!/bin/bash

# bash ./ccc.sh

# 获取系统信息
OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2) # debian
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g') # 11
OS_VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2) # bullseye

set -e
LOG_FILE="/var/log/ccc_script.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

system_init(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装必备组件 && 系统配置------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    echo -e "\n\n\n 配置语言"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        # dpkg-reconfigure locales
        # 启用一个区域设置
        sed -i '/^# zh_CN.UTF-8 UTF-8$/s/^#//' /etc/locale.gen
        # 生成区域设置
        locale-gen
        # 设置系统环境的默认区域
        update-locale LANG=zh_CN.UTF-8
    fi

    echo -e "\n\n\n 配置时区"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        # dpkg-reconfigure tzdata
        timedatectl set-timezone Asia/Shanghai
    fi

    echo -e "\n\n\n 设置ssh 120*720=86400 24小时不断开连接"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        cp "/etc/ssh/sshd_config" "/etc/ssh/sshd_config-OLD-$(date +%y%m%d-%H%M%S)"
        find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#TCPKeepAlive yes|TCPKeepAlive yes|g'
        find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#ClientAliveInterval 0|ClientAliveInterval 120|g'
        find '/etc/ssh/sshd_config' | xargs perl -pi -e 's|#ClientAliveCountMax 3|ClientAliveCountMax 720|g'
        systemctl restart sshd
    fi

    echo -e "\n\n\n开启 rc.local"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        if [ ! -e "/etc/rc.local" ]; then
            echo -e "\n\n\n配置 rc.local"
            touch /etc/rc.local
            chmod 755 /etc/rc.local
            cat >/etc/rc.local <<EOF
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
    fi

    if [ ! -f "/swapfile" ]; then
        echo -e "\n\n\n设置 Swap"
        read -t 5 -p "是否继续？ (y):" answer
        if [[ "$answer" == "y" || $? -eq 142 ]]; then
            total_memory_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 1024)}')
            swapfile_length=$(($total_memory_mb * 2))
            # 创建swap文件
            fallocate -l ${swapfile_length}M /swapfile
            # 格式化为交换分区
            mkswap /swapfile
            # 将文件添加到系统的/etc/fstab文件中，以便在系统启动时自动挂载
            log '/swapfile none swap sw 0 0' | tee -a /etc/fstab
            # 启用交换文件
            swapon /swapfile
        fi
    fi

    if [ -z "$(lsmod | grep bbr)" ]; then
        echo -e "\n\n\n启用 Google BBR"
        read -t 5 -p "是否继续？ (y):" answer
        if [[ "$answer" == "y" || $? -eq 142 ]]; then
            sh -c 'echo net.core.default_qdisc=fq >> /etc/sysctl.conf'
            sh -c 'echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf'
            echo -e "\n\n\n从配置文件加载内核参数（需要管理员）"
            sysctl -p
        fi
    fi

    echo -e "\n\n\n 更新APT包索引"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        apt update
    fi

    echo -e "\n\n\n 安装必备组件"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        apt -y install sudo openssl aptitude unzip wget curl telnet perl
        apt -y install sqlite3 lua5.3 zip
    fi

    echo -e "\n\n\n 安装 Python 及配套工具"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        apt -y install python3 python3-pip python3-venv python3-dev python3-setuptools

        if read -t 5 -p "是否使用pypi中国大陆镜像源？ (y): " answer && [ "$answer" == "y" ]; then
            pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
        fi

        pip install --user pipx
        python3 -m pipx ensurepath
    fi

    echo -e "\n\n\n 安装 Git"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        apt -y install git
        git config --global user.name "zero-ljz"
        git config --global user.email "zero-ljz@qq.com"
    fi
}

install_supervisor(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 Supervisor 进程管理器------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    
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
    log supervisord -c /etc/supervisor/supervisord.conf >>/etc/rc.local
    supervisord -c /etc/supervisor/supervisord.conf
}

create_supervisor(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} app_name \"command\" working_dir"
        return
    fi

    local app_name="$1"
    local command="$2"
    local working_dir="${3:-"/usr/local/bin/"}"

    cat >/etc/supervisor/conf.d/${app_name}.ini <<EOF
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

create_service(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} app_name command working_dir"
        return
    fi

    local app_name="$1"
    local command="$2"
    local working_dir="${3:-"/usr/local/bin/"}"

    touch /etc/systemd/system/${app_name}.service
    chmod 755 /etc/systemd/system/${app_name}.service
    cat >/etc/systemd/system/${app_name}.service <<EOF
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

install_docker(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    echo -e "\n\n\n------------------------------安装 Docker------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    # curl -fsSL https://get.docker.com -o get-docker.sh
    # sh get-docker.sh

    local host="download.docker.com"
    read -t 5 -p "是否使用中国大陆镜像？ (y): " answer && [ "$answer" == "y" ] && host="mirrors.tuna.tsinghua.edu.cn"

    echo -e "\n\n\n 安装包以允许apt通过HTTPS使用存储库"
    apt-get update && apt-get -y install ca-certificates curl gnupg
    
    echo -e "\n\n\n 添加 Docker 的官方 GPG 密钥"
    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://${host}/linux/${OS_ID}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo -e "\n\n\n 设置存储库"
    log "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://${host}/linux/${OS_ID} "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo -e "\n\n\n 安装 Docker Engine、containerd 和 Docker Compose"
    apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if read -t 5 -p "是否使用中国大陆注册表？ (y): " answer && [ "$answer" == "y" ]; then
        cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://p.520999.xyz/https://registry-1.docker.io"]
}
EOF
        # 备用 http://mirrors.ustc.edu.cn http://hub.daocloud.io
    fi
}

install_nodejs(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    echo -e "\n\n\n------------------------------安装 Nodejs------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    
    apt -y install npm
    # 使用版本管理器安装nodejs https://learn.microsoft.com/zh-cn/windows/dev-environment/javascript/nodejs-on-wsl?source=recommendations
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

    # 运行以下操作可以不用重启终端就能使用nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    nvm install 18.19.0

    # npm install -g yarn
    npm install -g pnpm

    # 查看全局包，并且只显示顶级包，而不会列出其依赖项
    #npm list -g --depth 0

    # npm config set registry https://registry.npmjs.org/
    # npm config set registry https://registry.npmmirror.com
}

create_ssl(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} domain_name [acme_dir]"
        return
    fi

    local domain_name="$1"

    # acme_dir=${2:-/var/www/${domain_name}/.well-known/acme-challenge/} 
    local acme_dir="/var/www/challenges/${domain_name}/"

    local SSL_DIR="/var/ssl"
    if [ ! -d "$SSL_DIR" ]; then
        mkdir "$SSL_DIR"
    fi

    local ACME_TINY="/tmp/acme_tiny.py"
    local ACCOUNT_KEY="$SSL_DIR/account.key"
    # 私钥
    local DOMAIN_KEY="$SSL_DIR/${domain_name}.key"
    # 公钥
    local DOMAIN_CRT="$SSL_DIR/${domain_name}.crt"
    # 链接起来的公钥
    local DOMAIN_CHAINED_CRT="$SSL_DIR/${domain_name}.chained.crt"

    local DOMAIN_CSR="$SSL_DIR/${domain_name}.csr"

    # 文件不存在时创建 Let's Encrypt 帐户私钥
    if [ ! -f "$ACCOUNT_KEY" ]; then
        log "Generate account key..."
        openssl genrsa 4096 > "$ACCOUNT_KEY"
    fi

    if [ ! -f "$DOMAIN_KEY" ]; then
        log "Generate domain key 私钥..."
        openssl genrsa 2048 > "$DOMAIN_KEY"
    fi

    log "Generate CSR..."
    openssl req -new -sha256 -key "$DOMAIN_KEY" -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=%s" "DNS:${domain_name},DNS:${domain_name}")) > "${DOMAIN_CSR}"

    # crt文件存在时备份
    if [ -f "$DOMAIN_CRT" ]; then
        mv "$DOMAIN_CRT" "$DOMAIN_CRT-OLD-$(date +%y%m%d-%H%M%S)"
    fi

    mkdir -p "$acme_dir"

    wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O $ACME_TINY -o /dev/null
    python3 $ACME_TINY --account-key "$ACCOUNT_KEY" --csr "${DOMAIN_CSR}" --acme-dir "$acme_dir" > "$DOMAIN_CRT"

    if [ ! -f "lets-encrypt-x3-cross-signed.pem" ]; then
        wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -o /dev/null
    fi
    # 合并为公钥文件
    cat "$DOMAIN_CRT" lets-encrypt-x3-cross-signed.pem > "$DOMAIN_CHAINED_CRT"

    cat << EOF
执行 nano /etc/nginx/conf.d/${domain_name}.conf

在nginx网站配置的server块中添加以下内容:

    listen 443 ssl;
    ssl_certificate /var/ssl/${domain_name}.chained.crt;
    ssl_certificate_key /var/ssl/${domain_name}.key;
EOF
    log "Please restart nginx"
}

create_proxy(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then 
        log "Usage: ${FUNCNAME} domain_name local_port"
        return
    fi

    local domain_name="$1"
    local local_port="$2"

    cat >${domain_name}.conf <<EOF
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

    # if (\$scheme = http ) {
    #     return 301 https://\$host\$request_uri;
    # }

    # SSL/TLS 配置
    # listen 443 ssl;
    # ssl_certificate /var/ssl/${domain_name}.chained.crt;
    # ssl_certificate_key /var/ssl/${domain_name}.key;

    # 申请证书需要用到的配置
    location /.well-known/acme-challenge/ {
        alias /var/www/challenges/${domain_name}/;
        try_files \$uri =404;
    }

    location / {
        # 设置代理缓存
        #proxy_cache my_cache;
        #proxy_cache_valid 200 10m;

        #add_header Content-Security-Policy upgrade-insecure-requests;
        proxy_http_version 1.1;
        proxy_pass_header Server;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${local_port};

        # wordpress容器需要设置
        # proxy_redirect off;

        # 安全配置
        # 设置请求头
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

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

    systemctl restart nginx
    docker restart nginx1
}

deploy_mysql(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-3306}
    docker network create network1
    docker volume create mysql-data

    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
    log "${MYSQL_ROOT_PASSWORD}" > MYSQL_ROOT_PASSWORD.txt

    log "安装 MySQL"
    # docker run -dp ${port}:3306 --name mysql1 --restart=always --network network1 --network-alias mysql -v mysql-data:/var/lib/mysql \
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

    docker run -dp "${port}:3306" \
        --name mysql1 \
        --restart=always \
        --network network1 \
        --network-alias mysql \
        -v mysql-data:/var/lib/mysql \
        --env MARIADB_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
        --env TZ=Asia/Shanghai \
        --env MARIADB_USER=user1 \
        --env MARIADB_PASSWORD=123 \
        --env MARIADB_DATABASE=db1 \
        --env MARIADB_CHARSET=utf8mb4 \
        --env MARIADB_COLLATION=utf8mb4_unicode_ci \
        mariadb:10.6-focal \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci

    # 旧版本
    # docker exec -it mysql1 sed -i -E 's/max_connections(\s*)= [0-9]+/max_connections\1= 1000/g' /etc/mysql/my.cnf
    # docker exec -it mysql1 sed -i -E 's/wait_timeout(\s*)= [0-9]+/wait_timeout\1= 86400/g' /etc/mysql/my.cnf

    docker exec -it mysql1 sed -i -E 's/max_connections(\s*)= [0-9]+/max_connections\1= 1000/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    docker exec -it mysql1 sed -i -E 's/wait_timeout(\s*)= [0-9]+/wait_timeout\1= 86400/g' /etc/mysql/mariadb.conf.d/50-server.cnf
}

create_database(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} domain_name"
        return
    fi
    
    local domain_name="$1"
    MYSQL_ROOT_PASSWORD=$(cat MYSQL_ROOT_PASSWORD.txt)

    # 将创建数据库的sql语句写入sql文件并通过-i参数和<输入重定向符号传递给容器内的命令执行
    local db_password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
    local db_user=${domain_name//./_}
    
    cat >${domain_name}.sql <<EOF
CREATE DATABASE ${db_user}_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
CREATE USER '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_user}_db.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
EOF

    local cmd="mysql -h 127.0.0.1 -P 3306 -u root -p${MYSQL_ROOT_PASSWORD} < ${domain_name}.sql"
    log "请执行${cmd}创建数据库和用户 mysql://${db_user}:${db_password}@mysql:3306/${db_user}_db"
    log "在容器内创建需执行 docker exec -i mysql1 ${cmd}"
}

deploy_redis(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-6379}
    docker network create network1

    log "安装 Redis" 
    docker run -dp "${port}:6379" \
        --name redis1 \
        --restart=always \
        --network network1 \
        --network-alias redis \
        -v /docker/redis1:/data \
        -e TZ=Asia/Shanghai \
        redis:6-bullseye \
        redis-server --save 60 1 --loglevel warning --requirepass "123qweQ!"
    # 传给redis服务器的启动参数：若每60秒至少有一个键被修改了1次，就将数据持久化到磁盘，只记录警告及更高级别的日志
    # 连接字符串
    # redis://default:123qweQ!@localhost:6379/0
    # 连接方式：redis-cli
    # docker run -it --network redis --rm redis redis-cli -h redis1
}

deploy_postgres(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-5432}
    docker network create network1
    docker volume create postgre-data
    
    log "安装 PostgreSQL"
    docker run -dp "${port}:5432" \
        --name postgres1 \
        --restart=always \
        --network network1 \
        --network-alias postgres \
        -e TZ=Asia/Shanghai \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=123qwe123@21 \
        -e POSTGRES_DB=postgres \
        -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C" \
        -e PGDATA=/var/lib/postgresql/data \
        -v postgre-data:/var/lib/postgresql/data \
        postgres:13-bullseye -c shared_buffers=256MB -c max_connections=200
}

deploy_rabbitmq(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-5672}
    docker network create network1

    log "安装 RabbitMQ"
    docker run -dp "${port}:5672" -p 15672:15672 \
        --name rabbitmq1 \
        --restart=always \
        --network network1 \
        --network-alias rabbitmq \
        -e TZ=Asia/Shanghai \
        -e RABBITMQ_DEFAULT_USER=user1 \
        -e RABBITMQ_DEFAULT_PASS=123qwe123@ \
        rabbitmq
}

create_default_vhost(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    mkdir -p /var/www/html
    touch /var/www/html/index.html
    chmod 755 /var/www/html/index.html
    cat >/var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="zh-Hans">
<head>
    <meta charset="UTF-8">
    <link rel="icon" href="data:,">
    <title>404 未找到站点</title>
</head>
<body>
    <center><h1>404 未找到站点</h1></center><hr>
    <center><p>抱歉，您访问的站点不存在。</p></center>
</body>
</html>
EOF

    cat >/etc/nginx/conf.d/default.conf <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/html;

  index index.html index.htm index.nginx-debian.html;

  server_name _;

  location / {
   try_files \$uri \$uri/ =404;
  }
}
EOF
}

deploy_nginx(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    log "安装 Nginx"
    docker run -d \
        --name nginx1 \
        --restart=always \
        --network host \
        -v /var/www:/var/www \
        -v /var/ssl:/var/ssl \
        -v /etc/nginx/conf.d:/etc/nginx/conf.d \
        -e TZ=Asia/Shanghai \
        nginx:stable-bullseye

    create_default_vhost
    docker restart nginx1
}

deploy_portainer(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [local_port]"
        return
    fi
    
    echo -e "\n\n\n------------------------------部署 Portainer------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-9000}
    # https://docs.portainer.io/start/install/server/docker/linux
    docker volume create portainer_data
    docker run -d -p "${local_port}:9000" \
        --name portainer1 \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        -e TZ=Asia/Shanghai \
        portainer/portainer-ce
    # 汉化版
    # docker run -d -p ${local_port}:9000 --name portainer1 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -e TZ=Asia/Shanghai 6053537/portainer
}

deploy_wordpress(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [local_port]"
        return
    fi
    
    echo -e "\n\n\n------------------------------部署 Wordpress------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-8000}
    docker run -dp "127.0.0.1:${local_port}:80" \
        --name wordpress1 \
        --restart=always \
        --network network1 \
        -v /docker/wordpress1:/var/www/html \
        -e TZ=Asia/Shanghai \
        -e WORDPRESS_CONFIG_EXTRA="define( 'FORCE_SSL_ADMIN', true ); if( strpos( \$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false ) { \$_SERVER['HTTPS'] = 'on'; }" \
        wordpress
}

deploy_gitea(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [local_port] [ssh_port]"
        return
    fi
    
    echo -e "\n\n\n------------------------------部署 Gitea------------------------------"
    log "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-3000}
    local ssh_port=${2:-222}
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
        -p "127.0.0.1:${local_port}:3000" -p "${ssh_port}:22" \
        -e USER_UID=$(id -u git) \
        -e USER_GID=$(id -g git) \
        -v /docker/gitea:/data \
        -v /etc/timezone:/etc/timezone:ro \
        -v /etc/localtime:/etc/localtime:ro \
        gitea/gitea:1.19

    # 记得配置SSH_PORT=222，SSH_LISTEN_PORT=22

    # ssh://git@git.iapp.run:222/zero-ljz/repo.git
}

function docker_build_run(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} repo_url port_port"
        return
    fi
    
    local url="$1"
    local p="$2"

    # bash /root/fast.sh docker_build_run https://github.com/zero-ljz/iapp.git 777:8000
    # 请在repos目录使用此函数
    local repo=$(echo "$url" | sed 's|.*/\([^/]*\)\.git|\1|')
    docker rm -f ${repo}1
    docker image rm ${repo}
    rm -rf ${repo}

    git clone ${url}
    docker build -t ${repo} ${repo}
    docker run -p ${p} --name ${repo}1 ${repo}
    docker exec -it ${repo}1 sh
}

deploy_debian() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    # 创建空的 Debian 容器并保持运行
    docker run -d --name debian1 --network host debian:bullseye sleep infinity

    local commands=$(cat <<EOF
apt update && apt -y install --no-install-recommends wget curl nano micro
rm -rf /var/lib/apt/lists/*
EOF
    )
    docker exec debian1 bash -c "$commands"
}

deploy_python_app() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} repo_url http_port command"
        return
    fi
    # sudo docker rm -f iapp && sudo bash fast.sh deploy_python_app https://github.com/zero-ljz/iapp.git 8000 "python3 -m gunicorn -w 2 -b 0.0.0.0:8000 -k gevent app:app"
    local repo_url="${1}"
    local http_port="${2:-8000}"
    local command="${3:-"python3 -m gunicorn -b 0.0.0.0:8000 app:app"}"
    local repo=$(echo "$repo_url" | sed 's|.*/\([^/]*\)\.git|\1|')
    local commands=$(cat <<EOF

apt update && apt -y install git wget
git clone ${repo_url} .
# pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
python3 -m pip install -r requirements.txt
${command}
EOF
    )
    docker run -d -p "${http_port}:8000" \
        --name ${repo} \
        --restart=always \
        -v "/docker/${repo}:/usr/src/app" \
        -w /usr/src/app \
        -e TZ=Asia/Shanghai \
        python:3.10.11-slim-bullseye bash -c "$commands"
    docker logs ${repo}
}

deploy_node_app() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} repo_url http_port command"
        return
    fi

    local repo_url="${1}"
    local http_port="${2:-3000}"
    local command="${3:-"npm start"}"
    local repo=$(echo "$repo_url" | sed 's|.*/\([^/]*\)\.git|\1|')
    local commands=$(cat <<EOF

apt update && apt -y install git wget
git clone ${repo_url} .
npm install --production --silent
${command}
EOF
)
    docker run -d -p "${http_port}:3000" \
        --name ${repo} \
        --restart=always \
        -v "/docker/${repo}:/usr/src/app" \
        -w /usr/src/app \
        -e TZ=Asia/Shanghai \
        -e NODE_ENV=production \
        node:lts-bullseye-slim bash -c "$commands"
    docker logs ${repo}
}

deploy_php_app() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} app_name http_port"
        return
    fi

    local app_name="$1"
    local http_port="$2"
    docker run -d -p "${http_port}:80" --name ${app_name} -v "/docker/${app_name}:/var/www/html" php:7.4-apache
    # 容器内站点配置文件 /etc/apache2/sites-available/000-default.conf
    # 在php官方docker镜像中安装扩展
    docker exec -t ${app_name} curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - | sh -s gd xdebug pdo_mysql
    #docker exec -t ${app_name} chmod -R 755 /var/www/html
    download_php_apps /docker/${app_name}
}

docker_run_app(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [interpreter] [command]..."
        return
    fi

    local interpreter=${1:-"python3"}
    shift 1
    local command=""
    
    if [ "$interpreter" = "python3" ]; then
        command=${@:-"python3 -m pip install -r requirements.txt && python3 app.py"}
        # 3.11-alpine3.17
        docker run -it --rm -p 8000:8000 --name py1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp python:3.10.11-slim-bullseye bash -c "${command}"
    elif [ "$interpreter" = "python" ]; then
        command=${@:-"python -m pip install -r requirements.txt && python app.py"}
        docker run -it --rm -p 8000:8000 --name py1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp python:2.7.18-slim-buster bash -c "${command}"
    elif [ "$interpreter" = "php" ]; then
        command=${@:-""}
        docker run -it --rm -p 8000:80 --name php-httpd1 -v "$PWD":/var/www/html php:7.4-apache ${command}
    elif [ "$interpreter" = "php-cli" ]; then
        command=${@:-"php app.php"}
        docker run -it --rm -p 8000:8000 --name php-cli1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp php:7.4-cli ${command}
    elif [ "$interpreter" = "node" ]; then
        command=${@:-"node app.js"}
        docker run -it --rm -p 8000:8000 --name node1 -v "$PWD":/usr/src/app -w /usr/src/app node:18-bullseye-slim ${command}
    elif [ "$interpreter" = "ruby" ]; then
        command=${@:-"ruby app.rb"}
        docker run -it --rm -p 8000:8000 --name ruby1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp ruby:2.7.2-bullseye ${command}
    elif [ "$interpreter" = "perl" ]; then
        command=${@:-"perl app.pl"}
        docker run -it --rm --name perl1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp perl:5.34.0-bullseye ${command}
    fi
}

# nginx 部署静态网站
# docker run -dp 8080:80 --name web1 --restart=always -v /docker/web1:/usr/share/nginx/html nginx:stable-alpine-slim

function auto_mode(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    system_init
    install_supervisor
    install_docker

    deploy_nginx
    deploy_mysql
    deploy_redis


    # tinyfilemanager admin/admin@123
    # docker run -d -v /:/var/www/html/data -p 8020:80 --restart=always --name tinyfilemanager1 tinyfilemanager/tinyfilemanager:master

    # adminer
    # docker run -d --link mysql1:db --network network1 -p 8021:8080 --restart=always --name adminer1 adminer

    # deploy_portainer 9001
    # create_proxy docker.iapp.run 9001

    local domain_name=blog.iapp.run
    local port=8010
    deploy_wordpress ${port}
    create_database ${domain_name}
    create_proxy ${domain_name} ${port}
    create_ssl ${domain_name}

    # domain_name=a.iapp.run
    # create_vhost ${domain_name}
    # create_ssl ${domain_name}
    # create_database ${domain_name}
}

upgrade()
{
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Description: Upgrade this script, Perform this operation in the working directory"
        exit 0
    fi
    local url="https://raw.githubusercontent.com/zero-ljz/scripts/main/shell/ccc.sh"
    log "正在从 ${url} 下载最新版本脚本..."
    # bash -c "wget --no-cache --no-check-certificate -O /root/ccc.sh ${url}"
    bash -c "curl -LkO ${url}"
}

# 获取函数名
function_name=${1:-default}
shift  # 移除第一个参数，剩下的参数会被传递给函数

# 获取可用函数列表
function_list=$(compgen -A function)

# 定义在不传入参数时默认执行的函数
function default()
{
    log "Usage: ${FUNCNAME} [function_name] [-h] [arguments]"
    echo -e "\nAvailable functions:"
    for func in $function_list; do
        log "  $func"
    done
    echo
}

# 调用指定的函数，并传递参数
"$function_name" "$@"