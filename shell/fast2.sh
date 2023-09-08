
install_trojan(){
echo -e "\n\n\n------------------------------安装 Trojan------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

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

}

install_v2ray(){
echo -e "\n\n\n------------------------------安装 V2Ray------------------------------"
echo "是否继续？ (y)" && read -t 5 answer && [ ! $? -eq 142 ] && [ "$answer" != "y" ] && return

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

}



install_v2ray2(){
curl -LkOJ http://us.iapp.run/proxy/https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip
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