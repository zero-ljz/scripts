#!/bin/bash

# encoding=utf-8
# line ending=\n

# bash ./ccc.sh

# 获取系统信息
ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/') # amd64
OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g') # debian
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g') # 11
OS_VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2) # bullseye

LOG_FILE="/var/log/ccc_script.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

system_init(){
    # 执行这个函数需用sudo
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装必备组件 && 系统配置------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    echo -e "\n\n\n 配置语言"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        # dpkg-reconfigure locales
        # 启用一个区域设置
        sudo sed -i '/^# zh_CN.UTF-8 UTF-8$/s/^#//' /etc/locale.gen
        # 生成区域设置
        sudo locale-gen
        # 设置系统环境的默认区域
        sudo update-locale LANG=zh_CN.UTF-8
    fi

    echo -e "\n\n\n 配置时区"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        # dpkg-reconfigure tzdata
        sudo timedatectl set-timezone Asia/Shanghai
    fi

    echo -e "\n\n\n 设置ssh 120*720=86400 24小时不断开连接"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        sudo cp "/etc/ssh/sshd_config" "/etc/ssh/sshd_config-OLD-$(date +%y%m%d-%H%M%S)"
        sudo sed -i 's/^#\?TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config
        sudo sed -i 's|#ClientAliveInterval 0|ClientAliveInterval 120|g' /etc/ssh/sshd_config
        sudo sed -i 's|#ClientAliveCountMax 3|ClientAliveCountMax 720|g' /etc/ssh/sshd_config
        sudo systemctl restart sshd
    fi

    if [ ! -f "/swapfile" ]; then
        echo -e "\n\n\n设置 Swap"
        read -t 5 -p "是否继续？ (y):" answer
        if [[ "$answer" == "y" || $? -eq 142 ]]; then
            total_memory_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 1024)}')
            swapfile_length=$(($total_memory_mb * 2))
            log "正在创建 Swap 文件..."
            if sudo fallocate -l ${swapfile_length}M /swapfile 2>/dev/null; then
                log "使用 fallocate 预分配空间成功"
            else
                log "fallocate 失败，正在使用 dd 写入连续块（这可能需要一些时间）..."
                sudo dd if=/dev/zero of=/swapfile bs=1M count=${swapfile_length} status=none
            fi
            sudo chmod 600 /swapfile
            # 格式化为交换分区
            sudo mkswap /swapfile
            # 将文件添加到系统的/etc/fstab文件中，以便在系统启动时自动挂载
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            # 启用交换文件
            sudo swapon /swapfile
        fi
    fi

    if [ ! -f "/etc/systemd/zram-generator.conf" ]; then
        echo -e "\n\n\n开启 ZRAM 内存压缩 (高并发服务器不建议开启)"
        read -t 5 -p "是否继续？ (y):" answer
        if [[ "$answer" == "y" || $? -eq 142 ]]; then
            sudo apt update && sudo apt install -y systemd-zram-generator
            sudo tee /etc/systemd/zram-generator.conf <<EOF >/dev/null
[zram0]
zram-size = ram * 0.75
compression-algorithm = zstd
swap-priority = 100
EOF
            sudo systemctl daemon-reload
            sudo systemctl start systemd-zram-setup@zram0.service
            echo "ZRAM 配置完成，当前状态："
            sudo swapon --show
        fi
    fi

    if [ -z "$(lsmod | grep bbr)" ]; then
        echo -e "\n\n\n启用 Google BBR"
        read -t 5 -p "是否继续？ (y):" answer
        if [[ "$answer" == "y" || $? -eq 142 ]]; then
            sudo sh -c 'echo net.core.default_qdisc=fq >> /etc/sysctl.conf'
            sudo sh -c 'echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf'
            echo -e "\n\n\n从配置文件加载内核参数（需要管理员）"
            sudo sysctl -p
        fi
    fi

    echo -e "\n\n\n 更新sudo apt包索引"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        sudo apt update && sudo apt install -y ca-certificates
    fi

    echo -e "\n\n\n 安装必备组件"
    read -t 5 -p "是否继续？ (y):" answer
    if [[ "$answer" == "y" || $? -eq 142 ]]; then
        sudo apt -y install openssl aptitude unzip wget curl telnet perl lsof
        sudo apt -y install sqlite3 lua5.3 zip

        sudo apt -y install git
        git config --global user.name "zero-ljz"
        git config --global user.email "zero-ljz@qq.com"
    fi

}

install_python(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 Python + pyenv + UV ------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    # sudo apt -y install python3 python3-pip python3-venv python3-dev python3-setuptools

    # debian编译依赖包集合
    sudo apt update && sudo apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev uuid-dev -y
    # 安装pyenv
    curl https://pyenv.run | bash
    # 注入环境变量并写入 ~/.bashrc
    if ! grep -q "pyenv init" ~/.bashrc; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
    fi
    # 让当前脚本运行环境中临时生效，以便后续执行 pyenv 命令
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init - bash)"
    eval "$(pyenv virtualenv-init -)"
    # 执行编译安装
    pyenv install 3.10.11
    # pyenv install 3.12.10
    pyenv global 3.10.11

    if read -t 5 -p "是否使用pypi中国大陆镜像源？ (y): " answer && [ "$answer" == "y" ]; then
        pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
    fi

    # 已过时
    # sudo apt install -y pipx
    # pipx ensurepath

    # 安装uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_supervisor(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 Supervisor 进程管理器------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    
    # 使用系统包管理器安装，避免现代操作系统上的 PEP 668 pip 全局安装限制
    sudo apt update && sudo apt install -y supervisor
    
    # 确保配置支持 *.ini 后缀，且是幂等的（避免多次运行脚本重复追加）
    if [ -f "/etc/supervisor/supervisord.conf" ]; then
        if ! grep -q '\*\.ini' /etc/supervisor/supervisord.conf; then
            sudo sed -i 's|files = /etc/supervisor/conf.d/\*.conf|files = /etc/supervisor/conf.d/*.conf /etc/supervisor/conf.d/*.ini|g' /etc/supervisor/supervisord.conf
        fi
    fi
    
    sudo systemctl daemon-reload
    sudo systemctl enable supervisor
    sudo systemctl start supervisor
    log "Supervisor 已通过 Systemd 成功启动并设置开机自启"
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

    sudo tee /etc/supervisor/conf.d/${app_name}.ini <<EOF >/dev/null
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
    sudo supervisorctl reread
    # 应用更改
    sudo supervisorctl update

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

    sudo touch /etc/systemd/system/${app_name}.service
    sudo chmod 755 /etc/systemd/system/${app_name}.service
    sudo tee /etc/systemd/system/${app_name}.service <<EOF >/dev/null
[Unit]
Description=${app_name}
# 确保网络完全在线后再启动（比普通的 network.target 更稳，防止应用启动时因网络未就绪报错）
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
# 建议：如果应用不需要特殊系统权限，将 root 改为低权限用户（如 nobody）
User=root
WorkingDirectory=$working_dir
ExecStart=$command

# 核心续命三件套
Restart=always
RestartSec=5
# 防止程序死循环崩溃时无限重启把 CPU 飙满，如果 60 秒内重启超过 5 次则彻底停止
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target

EOF
}

install_docker(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    echo -e "\n\n\n------------------------------安装 Docker------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    # curl -fsSL https://get.docker.com -o get-docker.sh
    # sh get-docker.sh

    local host="download.docker.com"
    read -t 5 -p "是否使用中国大陆镜像？ (y): " answer && [ "$answer" == "y" ] && host="mirrors.ustc.edu.cn/docker-ce"

    echo -e "\n\n\n 安装包以允许sudo apt通过HTTPS使用存储库"
    sudo apt-get update && sudo apt-get -y install ca-certificates curl gnupg
    
    echo -e "\n\n\n 添加 Docker 的官方 GPG 密钥"
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://${host}/linux/${OS_ID}/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo -e "\n\n\n 设置存储库"
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://${host}/linux/${OS_ID} "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo -e "\n\n\n 安装 Docker Engine、containerd 和 Docker Compose"
    sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if read -t 5 -p "是否使用中国大陆注册表？ (y): " answer && [ "$answer" == "y" ]; then
        sudo tee /etc/docker/daemon.json <<EOF >/dev/null
{
  "registry-mirrors": ["https://p.252525.xyz/https://registry-1.docker.io"]
}
EOF
        # 备用 http://mirrors.ustc.edu.cn http://hub.daocloud.io
    fi
}

install_nodejs(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    echo -e "\n\n\n------------------------------安装 Nodejs + nvm + pnpm ------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    
    sudo apt -y install npm
    # 使用版本管理器安装nodejs https://learn.microsoft.com/zh-cn/windows/dev-environment/javascript/nodejs-on-wsl?source=recommendations
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

    # 运行以下操作可以不用重启终端就能使用nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    # 安装Nodejs 24 LTS
    nvm install 24

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

    # 自动在 crontab 中写入“每天凌晨固定检查”的任务
    local current_script=$(readlink -f "$0")
    # 确保是通过脚本文件执行，而不是直接在终端粘贴函数
    if [[ "$current_script" != *"bash"* ]] && [ -f "$current_script" ]; then
        local cron_job="15 3 * * * CRON_EXECUTION=1 bash $current_script create_ssl $domain_name"
        if ! sudo crontab -l 2>/dev/null | grep -q "create_ssl $domain_name"; then
            (sudo crontab -l 2>/dev/null; echo "$cron_job") | sudo crontab -
            log "SUCCESS: Daily health-check cron job added."
        fi
    fi

    local SSL_DIR="/var/ssl"
    if [ ! -d "$SSL_DIR" ]; then
        sudo mkdir -p "$SSL_DIR"
    fi

    local ACME_TINY="/tmp/acme_tiny.py"
    local ACCOUNT_KEY="$SSL_DIR/account.key"
    # 私钥
    local DOMAIN_KEY="$SSL_DIR/${domain_name}.key"
    # 公钥（完整证书链）
    local DOMAIN_FULLCHAIN_CRT="$SSL_DIR/${domain_name}.fullchain.crt"

    local DOMAIN_CSR="$SSL_DIR/${domain_name}.csr"

    local TMP_FULLCHAIN_CRT="$DOMAIN_FULLCHAIN_CRT.tmp"


    # ==========================================
    # 🆕 智能检查：如果证书存在，且剩余天数大于 30 天，则直接退出，不重复申请
    # ==========================================
    if [ -f "$DOMAIN_FULLCHAIN_CRT" ]; then
        # 获取证书过期的绝对时间戳（秒）
        local expire_time=$(openssl x509 -enddate -noout -in "$DOMAIN_FULLCHAIN_CRT" | cut -d= -f2)
        local expire_timestamp=$(date -d "$expire_time" +%s)
        # 获取当前时间戳
        local current_timestamp=$(date +%s)
        # 计算剩余天数
        local rem_days=$(( (expire_timestamp - current_timestamp) / 86400 ))

        # 如果是日常定时任务检查，且剩余天数大于 30 天，则静默退出
        if [ "$CRON_EXECUTION" = "1" ] && [ "$rem_days" -gt 30 ]; then
            # 记录一条简短日志说明证书还很安全
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Certificate for $domain_name is still valid for $rem_days days. No renewal needed." >> /var/log/ssl_renew_${domain_name}.log
            return 0
        fi
        log "Current certificate expires in $rem_days days. Proceeding..."
    fi


    # 文件不存在时创建 Let's Encrypt 帐户私钥
    if [ ! -f "$ACCOUNT_KEY" ]; then
        log "Generate account key..."
        sudo openssl genrsa -out "$ACCOUNT_KEY" 4096
    fi

    if [ ! -f "$DOMAIN_KEY" ]; then
        log "Generate domain key 私钥..."
        sudo openssl genrsa -out "$DOMAIN_KEY" 2048
    fi

    log "Generate CSR..."
    sudo openssl req -new -sha256 -key "$DOMAIN_KEY" -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=%s" "DNS:${domain_name}")) -out "${DOMAIN_CSR}"

    sudo mkdir -p "$acme_dir"

    wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O "$ACME_TINY" --quiet
    sudo /usr/bin/python3 $ACME_TINY --account-key "$ACCOUNT_KEY" --csr "${DOMAIN_CSR}" --acme-dir "$acme_dir" | sudo tee "$TMP_FULLCHAIN_CRT" > /dev/null

    if [ $? -eq 0 ] && sudo openssl x509 -in "$TMP_FULLCHAIN_CRT" -noout >/dev/null 2>&1; then
        sudo mv "$TMP_FULLCHAIN_CRT" "$DOMAIN_FULLCHAIN_CRT"
        cat << EOF
执行 nano /etc/nginx/conf.d/${domain_name}.conf

在nginx网站配置的server块中添加以下内容:

    listen 443 ssl;
    ssl_certificate /var/ssl/${domain_name}.fullchain.crt;
    ssl_certificate_key /var/ssl/${domain_name}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
EOF
    log "Please restart nginx"
    else
        sudo rm -f "$TMP_FULLCHAIN_CRT"
        log "ERROR: SSL generation failed!"
        return 1
    fi
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
    # ssl_certificate /var/ssl/${domain_name}.fullchain.crt;
    # ssl_certificate_key /var/ssl/${domain_name}.key;
    # ssl_protocols TLSv1.2 TLSv1.3;

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

        # WebSocket 转发支持
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

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
    sudo cp ./${domain_name}.conf /etc/nginx/conf.d/${domain_name}.conf

    if command -v nginx >/dev/null 2>&1; then
        sudo nginx -t && sudo nginx -s reload
    fi
    if sudo docker ps --format '{{.Names}}' | grep -q '^nginx1$'; then
        sudo docker exec nginx1 nginx -t && sudo docker exec nginx1 nginx -s reload
    fi
}

deploy_mysql(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-3306}
    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1
    sudo docker volume create mysql-data

    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
    echo "${MYSQL_ROOT_PASSWORD}" > MYSQL_ROOT_PASSWORD.txt

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

    sudo docker run -dp "${port}:3306" \
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
        mariadb:10.6-jammy \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci

    # 旧版本
    # docker exec -it mysql1 sed -i -E 's/max_connections(\s*)= [0-9]+/max_connections\1= 1000/g' /etc/mysql/my.cnf
    # docker exec -it mysql1 sed -i -E 's/wait_timeout(\s*)= [0-9]+/wait_timeout\1= 86400/g' /etc/mysql/my.cnf

    sudo docker exec -it mysql1 sed -i -E 's/max_connections(\s*)= [0-9]+/max_connections\1= 1000/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    sudo docker exec -it mysql1 sed -i -E 's/wait_timeout(\s*)= [0-9]+/wait_timeout\1= 86400/g' /etc/mysql/mariadb.conf.d/50-server.cnf
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
    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1

    sudo mkdir -p /docker/redis1
    sudo chmod 777 /docker/redis1
    log "安装 Redis" 
    sudo docker run -dp "${port}:6379" \
        --name redis1 \
        --restart=always \
        --network network1 \
        --network-alias redis \
        -v /docker/redis1:/data \
        -e TZ=Asia/Shanghai \
        redis:7.2-bookworm \
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
    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1
    sudo docker volume create postgre-data
    
    PGSQL_ROOT_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
    echo "${PGSQL_ROOT_PASSWORD}" > PGSQL_ROOT_PASSWORD.txt

    log "安装 PostgreSQL"
    sudo docker run -dp "${port}:5432" \
        --name postgres1 \
        --restart=always \
        --network network1 \
        --network-alias postgres \
        -e TZ=Asia/Shanghai \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD="${PGSQL_ROOT_PASSWORD}" \
        -e POSTGRES_DB=postgres \
        -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C" \
        -e PGDATA=/var/lib/postgresql/data \
        -v postgre-data:/var/lib/postgresql/data \
        postgres:16-bookworm -c shared_buffers=256MB -c max_connections=200
}

deploy_rabbitmq(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi
    
    local port=${1:-5672}
    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1

    log "安装 RabbitMQ"
    sudo docker run -dp "${port}:5672" -p 15672:15672 \
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
    sudo mkdir -p /var/www/html
    sudo touch /var/www/html/index.html
    sudo chmod 755 /var/www/html/index.html
    sudo tee /var/www/html/index.html <<EOF >/dev/null
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

    sudo tee /etc/nginx/conf.d/default.conf << 'EOF' >/dev/null
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/html;

  index index.html index.htm index.nginx-debian.html;

  server_name _;

  location / {
   try_files $uri $uri/ =404;
  }
}
EOF
}

deploy_nginx(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    
    log "安装 Nginx"
    if lsof -i :80 >/dev/null 2>&1; then
        log "错误: 宿主机 80 端口已被占用，请先停止相关服务后再部署 Docker Nginx！"
        return 1
    fi
    sudo docker run -d \
        --name nginx1 \
        --restart=always \
        --network host \
        -v /var/www:/var/www \
        -v /var/ssl:/var/ssl \
        -v /etc/nginx/conf.d:/etc/nginx/conf.d \
        -e TZ=Asia/Shanghai \
        nginx:stable-bullseye

    create_default_vhost
    sudo docker exec nginx1 nginx -t && sudo docker exec nginx1 nginx -s reload
}

deploy_portainer(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [local_port]"
        return
    fi
    
    echo -e "\n\n\n------------------------------部署 Portainer------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-9000}
    # https://docs.portainer.io/start/install/server/docker/linux
    sudo docker volume create portainer_data
    sudo docker run -d -p "${local_port}:9000" \
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
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-8000}
    sudo mkdir -p /docker/wordpress1
    sudo chmod 777 /docker/wordpress1
    sudo docker run -dp "127.0.0.1:${local_port}:80" \
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
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local local_port=${1:-3000}
    local ssh_port=${2:-222}
    sudo adduser \
        --system \
        --shell /bin/bash \
        --gecos 'Git Version Control' \
        --group \
        --disabled-password \
        --home /home/git \
        git
    
    sudo mkdir -p /docker/gitea
    sudo chmod 777 /docker/gitea
    sudo docker run -d \
        --name gitea1 \
        --restart=always \
        -p "127.0.0.1:${local_port}:3000" -p "${ssh_port}:2222" \
        -e USER_UID=$(id -u git) \
        -e USER_GID=$(id -g git) \
        -v /docker/gitea:/data \
        -v /etc/timezone:/etc/timezone:ro \
        -v /etc/localtime:/etc/localtime:ro \
        gitea/gitea:1-rootless
    # rootless版默认监听2222, 否则监听22

    # 记得配置SSH_PORT=222，SSH_LISTEN_PORT=22

    # ssh://git@git.iapp.run:222/zero-ljz/repo.git
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


install_frp(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    echo -e "\n\n\n------------------------------安装 Frp------------------------------"
    echo -e "\n\n\n下载 Frp 二进制包"
    wget --no-check-certificate -O frp_0.58.0_linux_${ARCH}.tar.gz https://github.com/fatedier/frp/releases/download/v0.58.0/frp_0.58.0_linux_${ARCH}.tar.gz
    tar xzvf frp_0.58.0_linux_${ARCH}.tar.gz -C /usr/local/bin/
    mv /usr/local/bin/frp_0.58.0_linux_${ARCH} /usr/local/bin/frp

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


install_gost(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 Gost 隧道工具------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return
    
    # 更新系统并安装解压工具
    sudo apt update && sudo apt install -y wget gzip

    # 下载最新的 gost 2.11.5 版本（这是最经典的稳定版本）
    wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-${ARCH}-2.11.5.gz

    # 解压并重命名
    gzip -d gost-linux-${ARCH}-2.11.5.gz
    mv gost-linux-${ARCH}-2.11.5 gost

    # 赋予执行权限并移动到系统目录
    chmod +x gost
    sudo mv gost /usr/local/bin/
    
    echo -e "\n\n\n 生成配置文件"
    mkdir /etc/gost
    
    cat >/etc/gost/config.json << 'EOF'
{
"Debug": true,
"Retries": 3,
"ServeNodes": [
    "tcp://:9999/111.111.111.111:8888",
    "udp://:9999/111.111.111.111:8888",

    "tcp://:7777/111.111.111.111:5555",
    "udp://:7777/111.111.111.111:5555"
]
}
EOF

    # 在中转机上执行，把本地的 9999 端口流量转发到高延迟机的 8888 端口
    # /usr/local/bin/gost -L tcp://:9999/111.111.111.111:8888 -L udp://:9999/111.111.111.111:8888

    echo -e "\n\n\n 使用 Systemd 配置 Gost 开机自启"
    GOST_BIN=$(which gost || echo "/usr/local/bin/gost")
    create_service "gost" "${GOST_BIN} -C /etc/gost/config.json" "/etc/gost"
    systemctl daemon-reload
    systemctl enable gost
    systemctl start gost
    log "Gost 已通过 Systemd 成功启动并设置开机自启"
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
    sudo docker rm -f ${repo}1
    sudo docker image rm ${repo}
    rm -rf ${repo}

    git clone ${url}
    sudo docker build -t ${repo} ${repo}
    sudo docker run -p ${p} --name ${repo}1 ${repo}
    sudo docker exec -it ${repo}1 sh
}

deploy_debian() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    # 创建空的 Debian 容器并保持运行
    sudo docker run -d --name debian1 --network host debian:bullseye sleep infinity

    local commands=$(cat <<EOF
sudo apt update && sudo apt -y install --no-install-recommends wget curl nano micro
rm -rf /var/lib/apt/lists/*
EOF
    )
    sudo docker exec debian1 bash -c "$commands"
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

sudo apt update && sudo apt -y install git wget
if [ -d .git ]; then git pull; else git clone ${repo_url} .; fi
# pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple/
python3 -m pip install -r requirements.txt
${command}
EOF
    )
    sudo docker run -d -p "${http_port}:8000" \
        --name ${repo} \
        --restart=always \
        -v "/docker/${repo}:/usr/src/app" \
        -w /usr/src/app \
        -e TZ=Asia/Shanghai \
        python:3.10.11-slim-bullseye bash -c "$commands"
    sudo docker logs ${repo}
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

sudo apt update && sudo apt -y install git wget
if [ -d .git ]; then git pull; else git clone ${repo_url} .; fi
npm install --production --silent
${command}
EOF
)
    sudo docker run -d -p "${http_port}:3000" \
        --name ${repo} \
        --restart=always \
        -v "/docker/${repo}:/usr/src/app" \
        -w /usr/src/app \
        -e TZ=Asia/Shanghai \
        -e NODE_ENV=production \
        node:lts-bullseye-slim bash -c "$commands"
    sudo docker logs ${repo}
}

deploy_php_app() {
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} app_name http_port"
        return
    fi

    local app_name="$1"
    local http_port="$2"
    sudo docker run -d -p "${http_port}:80" --name ${app_name} -v "/docker/${app_name}:/var/www/html" php:7.4-apache
    # 容器内站点配置文件 /etc/apache2/sites-available/000-default.conf
    # 在php官方docker镜像中安装扩展
    sudo docker exec -t ${app_name} curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - | sh -s gd xdebug pdo_mysql
    #docker exec -t ${app_name} chmod -R 755 /var/www/html
    # download_php_apps /docker/${app_name}
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
        sudo docker run -it --rm -p 8000:8000 --name py1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp python:3.10.11-slim-bullseye bash -c "${command}"
    elif [ "$interpreter" = "python" ]; then
        command=${@:-"python -m pip install -r requirements.txt && python app.py"}
        sudo docker run -it --rm -p 8000:8000 --name py1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp python:2.7.18-slim-buster bash -c "${command}"
    elif [ "$interpreter" = "php" ]; then
        command=${@:-""}
        sudo docker run -it --rm -p 8000:80 --name php-httpd1 -v "$PWD":/var/www/html php:7.4-apache ${command}
    elif [ "$interpreter" = "php-cli" ]; then
        command=${@:-"php app.php"}
        sudo docker run -it --rm -p 8000:8000 --name php-cli1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp php:7.4-cli ${command}
    elif [ "$interpreter" = "node" ]; then
        command=${@:-"node app.js"}
        sudo docker run -it --rm -p 8000:8000 --name node1 -v "$PWD":/usr/src/app -w /usr/src/app node:18-bullseye-slim ${command}
    elif [ "$interpreter" = "ruby" ]; then
        command=${@:-"ruby app.rb"}
        sudo docker run -it --rm -p 8000:8000 --name ruby1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp ruby:2.7.2-bullseye ${command}
    elif [ "$interpreter" = "perl" ]; then
        command=${@:-"perl app.pl"}
        sudo docker run -it --rm --name perl1 -v "$PWD":/usr/src/myapp -w /usr/src/myapp perl:5.34.0-bullseye ${command}
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

install_fail2ban(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 fail2ban------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    sudo apt update && sudo apt install -y fail2ban
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    log "fail2ban 安装完成并已启动，默认已对 sshd 启用保护"
}

install_monitoring_tools(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装系统监控工具 (htop, btop, ncdu)------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    sudo apt update && sudo apt install -y htop btop ncdu
    log "系统监控工具 (htop, btop, ncdu) 安装完成！"
}

deploy_netdata(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi

    echo -e "\n\n\n------------------------------部署 Netdata 监控------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local port=${1:-19999}
    sudo docker run -d --name=netdata1 \
        -p "${port}:19999" \
        --pid=host \
        -v netdataconfig:/etc/netdata \
        -v netdatalib:/var/lib/netdata \
        -v netdatacache:/var/cache/netdata \
        -v /etc/passwd:/host/etc/passwd:ro \
        -v /etc/group:/host/etc/group:ro \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro \
        -v /etc/os-release:/host/etc/os-release:ro \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        --restart always \
        --cap-add SYS_PTRACE \
        --security-opt apparmor=unconfined \
        netdata/netdata
    log "Netdata 部署成功，请访问 http://IP:${port}"
}

deploy_adminer(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port]"
        return
    fi

    echo -e "\n\n\n------------------------------部署 Adminer 数据库管理工具------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local port=${1:-8080}
    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1
    sudo docker run -d --name adminer1 \
        --restart always \
        --network network1 \
        -p "${port}:8080" \
        adminer
    log "Adminer 部署成功，请访问 http://IP:${port} (可在登录页指定主机为 mysql1 等)"
}

deploy_redis_commander(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port] [redis_host] [redis_port] [redis_password]"
        return
    fi

    echo -e "\n\n\n------------------------------部署 Redis Commander 可视化后台------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local port=${1:-8081}
    local redis_host=${2:-"redis1"}
    local redis_port=${3:-6379}
    local redis_pass=${4:-"123qweQ!"}

    sudo docker network inspect network1 >/dev/null 2>&1 || sudo docker network create network1
    sudo docker run -d --name redis-commander1 \
        --restart always \
        --network network1 \
        -p "${port}:8081" \
        -e REDIS_HOSTS="${redis_host}:${redis_port}:0:${redis_pass}" \
        rediscommander/redis-commander:latest
    log "Redis Commander 部署成功，请访问 http://IP:${port}"
}

deploy_watchtower(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------部署 Watchtower 容器自动更新工具------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    sudo docker run -d --name watchtower1 \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        containrrr/watchtower \
        --cleanup \
        --schedule "0 0 3 * * *"
    log "Watchtower 部署成功，每日凌晨 3 点会自动检测并更新所有容器的镜像，并清理旧镜像。"
}

install_rclone(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi

    echo -e "\n\n\n------------------------------安装 Rclone 备份/同步工具------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    curl https://rclone.org/install.sh | sudo bash
    log "Rclone 安装完成，请输入 rclone config 配置您的云盘/对象存储"
}

deploy_filebrowser(){
    if [ "$1" = "-d" ] || [ "$1" = "--declare" ]; then declare -f ${FUNCNAME}; return; fi
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        log "Usage: ${FUNCNAME} [port] [root_dir]"
        return
    fi

    echo -e "\n\n\n------------------------------部署 File Browser 网盘与文件管理器------------------------------"
    read -p "是否继续？ (y)" -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

    local port=${1:-8082}
    local root_dir=${2:-"/"}

    sudo mkdir -p /docker/filebrowser
    sudo touch /docker/filebrowser/filebrowser.db
    sudo chmod 666 /docker/filebrowser/filebrowser.db

    sudo docker run -d --name filebrowser1 \
        --restart always \
        -v "${root_dir}:/srv" \
        -v /docker/filebrowser/filebrowser.db:/database/filebrowser.db \
        -p "${port}:80" \
        -e TZ=Asia/Shanghai \
        filebrowser/filebrowser
    log "File Browser 部署成功，请访问 http://IP:${port} (默认用户名/密码: admin/admin)"
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
    
    local script_path
    script_path=$(readlink -f "$0")
    
    if [ -f "$script_path" ]; then
        local tmp_file
        tmp_file=$(mktemp)
        if curl -LfsS "$url" -o "$tmp_file"; then
            if [ -s "$tmp_file" ]; then
                chmod --reference="$script_path" "$tmp_file" 2>/dev/null || chmod +x "$tmp_file"
                mv -f "$tmp_file" "$script_path"
                log "脚本更新成功！"
                exit 0
            else
                log "错误：下载的文件为空"
                rm -f "$tmp_file"
                return 1
            fi
        else
            log "错误：下载失败"
            rm -f "$tmp_file"
            return 1
        fi
    else
        log "错误：无法确定脚本路径，升级失败"
        return 1
    fi
}

systeminfo()
{
    apt -y install lsb-release curl
    uname -a && lsb_release -a && lscpu && cat /etc/os-release && hostnamectl && df -h && free -h && timedatectl && curl ipinfo.io
}

systeminfo()
{
    apt -y install lsb-release curl
    uname -a && lsb_release -a && lscpu && cat /etc/os-release && hostnamectl && df -h && free -h && timedatectl && curl ipinfo.io
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
        echo "  $func"
    done
    echo
}

# 调用指定的函数，并传递参数
"$function_name" "$@"