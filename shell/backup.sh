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


# 容器备份 右边是镜像名
# docker commit nginx1 nginx1
# docker save -o nginx1_backup.tar nginx1

# docker load -i nginx1_backup.tar
# docker run -dp 80:80 --name nginx1 

containers=$(docker ps -q)
for container_id in $containers; do
    container_name=$(docker inspect --format '{{.Name}}' $container_id | cut -c 2-)
    backup_image="${container_name}-image-backup_$(date +\%Y\%m\%d_\%H\%M\%S)"
    backup_file="${container_name}-image-backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar"

    # 备份容器的镜像
    docker commit "$container_name" "$backup_image"
    docker save -o "$backup_file" "$backup_image"

    # 保存容器镜像到备份目录
    docker save -o "$backup_dir/$timestamp/container_image.tar" "$backup_dir/$timestamp/container_image"

    echo "容器备份完成"


# 如果不加-o StrictHostKeyChecking=no，就一定要先用ssh命令登录一次目标服务器，并输入yes将远程服务器地址永久添加到known hosts list（已知主机列表）
# ssh root@host

# 使用rsync上传备份文件到远程服务器（使用密码认证）
rsync -avvvz -e "/usr/bin/sshpass -p $remote_password ssh -o StrictHostKeyChecking=no" "$backup_dir" "$remote_server:$remote_dir"
[ $? -ne 0 ] && echo "备份文件上传失败！"



