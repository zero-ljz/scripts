#!/bin/bash
# https://github.com/zero-ljz/scripts/raw/main/shell/backup.sh
# 0 */12 * * * /root/backup.sh
# 提前在远程服务器上执行 apt install -y rsync

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

SYS_HOSTNAME=$(hostname)
OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g')
OS_ID=${OS_ID:-"unknown_os"}
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="${SYS_HOSTNAME}_${OS_ID}_backup_${DATE}.tar.gz"

mkdir -p $BACKUP_DIR

# 根据选项执行相应的备份操作
if [ "$backup_files" = true ]; then
  echo "备份文件目录..."
  # 指定要备份的文件目录
  backup_dirs=(
      "/etc/"
      "/var/www/"
      "/opt/"
      "/home/"
      "/root/"
      "/var/spool/cron/crontabs/"
      "/usr/local/bin/"
      "/usr/local/sbin/"
      "/usr/local/etc/"
      "/docker/"
      "/var/lib/docker/volumes/"
  )
  for dir in "${backup_dirs[@]}"; do
      if [ ! -d "$dir" ]; then
        echo "提示: 目录 $dir 不存在，已自动跳过。"
        continue
      fi
      safe_name=$(echo "$dir" | sed 's|^/||; s|/$||; s|/|-|g')
      echo "正在打包: $dir -> dir_${safe_name}_backup_${DATE}.tar.gz"
      tar -czf "${BACKUP_DIR}/dir_${safe_name}_backup_${DATE}.tar.gz" "$dir"
      EXIT_CODE=$?
      if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 1 ]; then
          echo "❌ 严重错误: 备份目录 $dir 失败，退出码: $EXIT_CODE"
          exit 1
      fi
  done
fi

echo "记录软件列表..."
dpkg --get-selections > "$BACKUP_DIR/packages_$DATE.txt"

if [ "$backup_databases" = true ]; then
  echo "备份数据库..."
  mysql_root_password=$(cat /root/MYSQL_ROOT_PASSWORD.txt)
  # echo "备份MySQL容器中的所有数据库到一个sql文件"
  # docker exec -i mysql1 mysqldump -u root -p"$mysql_root_password" --all-databases > "$BACKUP_DIR/mysql_backup_${DATE}.sql"
  # 获取所有数据库的列表
  databases=$(docker exec -i mysql1 mysql -u"root" -p"$mysql_root_password" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)")

  # 备份每个数据库到单独的文件
  for db in $databases; do
      echo "正在导出数据库: $db -> db_${db}_backup_${DATE}.sql"
      docker exec -i mysql1 mysqldump -u"root" -p"$mysql_root_password" --databases "$db" > "$BACKUP_DIR/db_${db}_backup_${DATE}.sql"
      [ $? -ne 0 ] && echo "备份数据库 $db 失败" && exit 1

    # 在mysql容器中选择指定数据库执行容器外面的mysql脚本文件
    # docker exec -i mysql1 mysql -h 127.0.0.1 -P 3306 -u root -p123 target_db < backup.sql
  done
fi

if [ "$backup_containers" = true ]; then
  echo "备份容器..."
  # 备份所有正在运行的容器
  containers=$(docker ps -q)
  for container_id in $containers; do
      container_name=$(docker inspect --format '{{.Name}}' $container_id | cut -c 2-)
      backup_image="${container_name}-image"
      backup_file="container_${container_name}_backup_${DATE}.tar"
      echo "正在备份容器: $container_name -> $backup_file"
      # 将容器保存为新镜像
      docker commit "$container_name" "$backup_image"
      # 将镜像保存为压缩文件
      docker save -o "${BACKUP_DIR}/$backup_file" "$backup_image"
      # 备份前一条命令状态码
      SAVE_CODE=$?
      # 删除临时镜像
      docker rmi --force "$backup_image"
      [ $SAVE_CODE -ne 0 ] && echo "备份容器 ${container_name} 失败！" && exit 1
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
  rsync -avvvz -e "/usr/bin/sshpass -p $remote_password ssh -o StrictHostKeyChecking=no" "$BACKUP_DIR" "$remote_server:$remote_dir"
  [ $? -ne 0 ] && echo "备份文件上传失败！"
fi