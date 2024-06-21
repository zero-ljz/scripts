#!/bin/bash

# Debian 12 wsl 阿里云源
bash -c "cat << EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/debian bookworm main
deb http://mirrors.aliyun.com/debian bookworm-updates main
deb http://mirrors.aliyun.com/debian-security bookworm-security main
deb http://mirrors.aliyun.com/debian bookworm-backports main
EOF"

apt update 

# https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config
# 启用systemd
bash -c "cat << EOF > /etc/wsl.conf
[boot]
systemd=true
memory=2GB
processors=2
swap=4GB
EOF"

# 安装命令行工具
apt -y install wget
apt -y install python3 python3-pip python3-venv

# 安装pipx
sudo apt -y install pipx
pipx ensurepath

# 安装mariadb
# sudo apt -y install mariadb-client mariadb-server
# sudo systemctl start mariadb
# sudo systemctl enable mariadb
# sudo mysql_secure_installation

# 安装redis
# sudo apt -y install redis-server

# 安装GUI应用
# GNOME 文件管理器
# sudo apt install nautilus -y
# GNOME 文本编辑器
# sudo apt install gnome-text-editor -y
# Google Chrome
wget https://p.520999.xyz/https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
sudo apt install --fix-missing /tmp/google-chrome-stable_current_amd64.deb