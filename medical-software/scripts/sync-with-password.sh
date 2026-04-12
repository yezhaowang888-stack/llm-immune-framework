#!/bin/bash
# 使用密码认证的同步脚本（临时方案）

CLOUD_IP="47.242.48.154"
CLOUD_USER="root"
CLOUD_PASSWORD="123456"  # 云服务器root密码
LOCAL_BACKUP_DIR="/Users/mac/.openclaw/workspace/medical-software/backup-temp"
LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
SYNC_LOG="$LOG_DIR/password-sync-$(date +%Y%m%d).log"

mkdir -p $LOG_DIR
mkdir -p $LOCAL_BACKUP_DIR

echo "=== 密码认证同步开始: $(date) ===" >> $SYNC_LOG

# 使用sshpass进行密码认证（需要先安装sshpass）
if ! command -v sshpass &> /dev/null; then
    echo "[$(date)] ❌ sshpass未安装，请先安装: brew install hudochenkov/sshpass/sshpass" >> $SYNC_LOG
    exit 1
fi

# 1. 测试连接
echo "[$(date)] 测试SSH连接..." >> $SYNC_LOG
sshpass -p "$CLOUD_PASSWORD" ssh -o StrictHostKeyChecking=no $CLOUD_USER@$CLOUD_IP "echo '连接测试成功'" >> $SYNC_LOG 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] ✅ SSH连接成功" >> $SYNC_LOG
    
    # 2. 导出数据库
    echo "[$(date)] 导出数据库..." >> $SYNC_LOG
    DB_FILE="$LOCAL_BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql"
    sshpass -p "$CLOUD_PASSWORD" ssh $CLOUD_USER@$CLOUD_IP "mysqldump -uroot -p123456 medgsp --single-transaction --skip-lock-tables" > $DB_FILE 2>> $SYNC_LOG
    
    if [ $? -eq 0 ]; then
        DB_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE")
        echo "[$(date)] ✅ 数据库导出成功: $DB_FILE (${DB_SIZE} bytes)" >> $SYNC_LOG
    else
        echo "[$(date)] ❌ 数据库导出失败" >> $SYNC_LOG
    fi
    
    # 3. 同步代码文件
    echo "[$(date)] 同步代码文件..." >> $SYNC_LOG
    
    # Web代码
    WEB_DIR="$LOCAL_BACKUP_DIR/web"
    mkdir -p $WEB_DIR
    sshpass -p "$CLOUD_PASSWORD" scp -r $CLOUD_USER@$CLOUD_IP:/usr/share/nginx/html/bio/* $WEB_DIR/ >> $SYNC_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        WEB_COUNT=$(find $WEB_DIR -type f 2>/dev/null | wc -l)
        echo "[$(date)] ✅ Web代码同步成功: $WEB_COUNT 个文件" >> $SYNC_LOG
    else
        echo "[$(date)] ⚠️ Web代码同步部分失败" >> $SYNC_LOG
    fi
    
    # 应用代码
    SOURCE_DIR="$LOCAL_BACKUP_DIR/source"
    mkdir -p $SOURCE_DIR
    sshpass -p "$CLOUD_PASSWORD" scp -r $CLOUD_USER@$CLOUD_IP:/root/medgsp/* $SOURCE_DIR/ >> $SYNC_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        SOURCE_COUNT=$(find $SOURCE_DIR -type f 2>/dev/null | wc -l)
        echo "[$(date)] ✅ 应用代码同步成功: $SOURCE_COUNT 个文件" >> $SYNC_LOG
    else
        echo "[$(date)] ⚠️ 应用代码同步部分失败" >> $SYNC_LOG
    fi
    
else
    echo "[$(date)] ❌ SSH连接失败" >> $SYNC_LOG
fi

echo "=== 密码认证同步完成: $(date) ===" >> $SYNC_LOG