#!/bin/bash
# https://github.com/zero-ljz/scripts/raw/main/shell/backup.sh
# 0 */12 * * * /root/backup.sh

apt -y install rsync sshpass

backup_dir="/backup" && mkdir -p $backup_dir
mysql_root_password=$(cat /root/MYSQL_ROOT_PASSWORD.txt)

remote_server=$1 # root@127.0.0.1
remote_password=$2
remote_dir=${3:-"/"}

# 指定要备份的文件目录
backup_directories=(
    "/docker"
    "/var/www"
)
for dir in "${backup_directories[@]}"; do
    dir_name=$(basename "$dir")
    tar -czvf "${backup_dir}/${dir_name}_backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz" "$dir"
done

# 备份MySQL数据库
docker exec -i mysql1 mysqldump -u root -p"$mysql_root_password" --all-databases > "$backup_dir/mysql_backup_$(date +\%Y\%m\%d_\%H\%M\%S).sql"
[ $? -ne 0 ] && echo "MySQL数据库备份失败！" && exit 1


# 如果不加-o StrictHostKeyChecking=no，就一定要先用ssh命令登录一次目标服务器，并输入yes将远程服务器地址永久添加到known hosts list（已知主机列表）
# ssh root@host

# 使用rsync上传备份文件到远程服务器（使用密码认证）
rsync -avvvz -e "/usr/bin/sshpass -p $remote_password ssh -o StrictHostKeyChecking=no" "$backup_dir" "$remote_server:$remote_dir"
[ $? -ne 0 ] && echo "备份文件上传失败！"


