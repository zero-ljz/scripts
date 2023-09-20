#!/bin/bash
# https://github.com/zero-ljz/scripts/raw/main/shell/backup.sh
# 0 */12 * * * /root/backup.sh

# 定义帮助文本
usage() {
  echo "用法: $0 [-s server] [-p password] [-d remote_dir] [-fbc]"
  echo "选项:"
  echo "  -s, --server     远程服务器地址和用户名 (例如 root@127.0.0.1)"
  echo "  -p, --password   远程服务器密码"
  echo "  -d, --dir        远程目录 (默认为 /)"
  echo "  -f, --files      备份文件目录"
  echo "  -b, --databases  备份数据库"
  echo "  -c, --containers 备份容器"
  exit 1
}

# 初始化变量，用于存储选项的默认值
remote_server=""
remote_password=""
remote_dir="/"
backup_files=false
backup_databases=false
backup_containers=false

# 使用 getopt 定义选项
OPTS=$(getopt -o s:p:d:fbc --long server:,password:,dir:,files,databases,containers -n "$0" -- "$@")

if [ $? != 0 ]; then
  usage
fi

eval set -- "$OPTS"

# 解析选项和参数
while true; do
  case "$1" in
    -s | --server)
      remote_server="$2"
      shift 2
      ;;
    -p | --password)
      remote_password="$2"
      shift 2
      ;;
    -d | --dir)
      remote_dir="$2"
      shift 2
      ;;
    -f | --files)
      backup_files=true
      shift
      ;;
    -b | --databases)
      backup_databases=true
      shift
      ;;
    -c | --containers)
      backup_containers=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
  esac
done


apt -y install rsync sshpass
save_dir="/backup"
mkdir -p $save_dir

# 根据选项执行相应的备份操作
if [ "$backup_files" = true ]; then
  echo "备份文件目录..."
  # 指定要备份的文件目录
  backup_dirs=(
      "/docker"
      "/var/www"
  )
  for dir in "${backup_dirs[@]}"; do
      dir_name=$(basename "$dir")
      tar -czvf "${save_dir}/${dir_name}_dir_backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz" "$dir"
      [ $? -ne 0 ] && echo "备份目录 $dir 失败" && exit 1
  done
fi

if [ "$backup_databases" = true ]; then
  echo "备份数据库..."
  mysql_root_password=$(cat MYSQL_ROOT_PASSWORD.txt)
  # echo "备份MySQL容器中的所有数据库到一个sql文件"
  # docker exec -i mysql1 mysqldump -u root -p"$mysql_root_password" --all-databases > "$save_dir/mysql_backup_$(date +\%Y\%m\%d_\%H\%M\%S).sql"
  # 获取所有数据库的列表
  databases=$(docker exec -i mysql1 mysql -u"root" -p"$mysql_root_password" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)")

  # 备份每个数据库到单独的文件
  for db in $databases; do
      docker exec -i mysql1 mysqldump -u"root" -p"$mysql_root_password" --databases "$db" > "$save_dir/${db}_backup_$(date +\%Y\%m\%d_\%H\%M\%S).sql"
      [ $? -ne 0 ] && echo "备份数据库 $db 失败" && exit 1
  done
fi

if [ "$backup_containers" = true ]; then
  echo "备份容器..."
  # 备份所有正在运行的容器
  containers=$(docker ps -q)
  for container_id in $containers; do
      container_name=$(docker inspect --format '{{.Name}}' $container_id | cut -c 2-)
      backup_image="${container_name}-image"
      backup_file="${container_name}_image_backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar"

      docker rmi --force "$backup_image"
      # 将容器保存为新镜像
      docker commit "$container_name" "$backup_image"
      # 将镜像保存为压缩文件
      docker save -o "${save_dir}/$backup_file" "$backup_image"
      [ $? -ne 0 ] && echo "备份容器 ${container_name} 失败！" && exit 1
      # 从保存的压缩文件中载入镜像
      # docker load -i xxx.tar
  done
fi

if [ -n "$remote_server" ] && [ -n "$remote_password" ]; then
  # 输出选项的值
  echo "远程服务器: $remote_server"
  echo "远程目录: $remote_dir"

  echo "开始同步备份文件到远程服务器"
  # 如果不加-o StrictHostKeyChecking=no，就一定要先用ssh命令登录一次目标服务器，并输入yes将远程服务器地址永久添加到known hosts list（已知主机列表）
  # 使用rsync上传备份文件到远程服务器（使用密码认证）
  rsync -avvvz -e "/usr/bin/sshpass -p $remote_password ssh -o StrictHostKeyChecking=no" "$save_dir" "$remote_server:$remote_dir"
  [ $? -ne 0 ] && echo "备份文件上传失败！"
fi