#!/bin/bash
# https://github.com/zero-ljz/scripts/raw/main/shell/backup.sh
# 0 */12 * * * /root/backup.sh

apt -y install rsync sshpass

save_dir="/backup"
mkdir -p $save_dir

mysql_root_password=$(cat /root/MYSQL_ROOT_PASSWORD.txt)

remote_server=$1 # root@127.0.0.1
remote_password=$2
remote_dir=${3:-"/"}

# 指定要备份的文件目录
backup_dirs=(
    "/docker"
    "/var/www"
)
for dir in "${backup_dirs[@]}"; do
    echo "备份目录: $dir"
    dir_name=$(basename "$dir")
    tar -czvf "${save_dir}/${dir_name}_dir_backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz" "$dir"
done

echo "备份MySQL容器中的所有数据库"
docker exec -i mysql1 mysqldump -u root -p"$mysql_root_password" --all-databases > "$save_dir/mysql_backup_$(date +\%Y\%m\%d_\%H\%M\%S).sql"
[ $? -ne 0 ] && echo "MySQL数据库备份失败！" && exit 1

# 备份所有正在运行的容器
containers=$(docker ps -q)
for container_id in $containers; do
    container_name=$(docker inspect --format '{{.Name}}' $container_id | cut -c 2-)
    echo "备份容器: $container_name"
    backup_image="${container_name}-image"
    backup_file="${container_name}_image_backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar"

    docker rmi --force "$backup_image"
    # 将容器保存为新镜像
    docker commit "$container_name" "$backup_image"
    # 将镜像保存为压缩文件
    docker save -o "${save_dir}/$backup_file" "$backup_image"
    [ $? -ne 0 ] && echo "${container_name}容器备份失败！" && exit 1
done

# 从保存的压缩文件中载入镜像
# docker load -i nginx1_backup.tar
# docker run -dp 80:80 --name nginx1 


echo "开始同步备份文件到远程服务器"
# 如果不加-o StrictHostKeyChecking=no，就一定要先用ssh命令登录一次目标服务器，并输入yes将远程服务器地址永久添加到known hosts list（已知主机列表）
# 使用rsync上传备份文件到远程服务器（使用密码认证）
rsync -avvvz -e "/usr/bin/sshpass -p $remote_password ssh -o StrictHostKeyChecking=no" "$save_dir" "$remote_server:$remote_dir"
[ $? -ne 0 ] && echo "备份文件上传失败！"



