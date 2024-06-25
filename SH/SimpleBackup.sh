#!/bin/bash

##简易备份路径文件执行脚本 修改以下变量
# 设置变量
# 多个源路径
BACKUP_SOURCE_PATHS=("/path/to/wordpress/data" "/path/to/mysql/data")
#打包目标路径  
BACKUP_DESTINATION="/path/to/backup/destination"
#打包文件命名
BACKUP_NAME="backup"
#保存七天备份打包文件
RETENTION_DAYS=7

# 获取当前日期，精确到分钟
TIMESTAMP=$(date +"%Y%m%d%H%M")

# 创建备份文件名
BACKUP_FILE="$BACKUP_DESTINATION/${BACKUP_NAME}_$TIMESTAMP.tar.gz"

# 打包和压缩文件
tar czf $BACKUP_FILE -C / ${BACKUP_SOURCE_PATHS[@]}

# 删除超过保留天数的备份文件
find $BACKUP_DESTINATION -name "${BACKUP_NAME}_*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm -f {} \;

# 打印备份结果
echo "Backup created: $BACKUP_FILE"
