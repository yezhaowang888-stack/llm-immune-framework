#!/bin/bash
# 使用sshpass进行密码认证的同步脚本

# 配置参数
CLOUD_IP="47.242.48.154"
CLOUD_USER="root"
CLOUD_PASSWORD=""  # 需要用户提供
LOCAL_DIR="/Users/mac/.openclaw/workspace/medical-software/sync-data"
LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
LOG_FILE="$LOG_DIR/sshpass-sync-$(date +%Y%m%d).log"

# 检查sshpass
if ! command -v sshpass &> /dev/null; then
    echo "❌ sshpass未安装，请先安装: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# 检查密码
if [ -z "$CLOUD_PASSWORD" ]; then
    echo "⚠️ 请设置云服务器SSH密码"
    echo "使用方法: CLOUD_PASSWORD='您的密码' ./sync-with-sshpass.sh"
    exit 1
fi

mkdir -p $LOCAL_DIR
mkdir -p $LOG_DIR

echo "=== SSH密码认证同步开始: $(date) ===" >> $LOG_FILE

# 1. 测试连接
echo "[$(date)] 测试SSH连接..." >> $LOG_FILE
sshpass -p "$CLOUD_PASSWORD" ssh -o StrictHostKeyChecking=no $CLOUD_USER@$CLOUD_IP "echo '连接成功'" >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] ✅ SSH连接成功" >> $LOG_FILE
    
    # 2. 导出数据库
    echo "[$(date)] 导出数据库..." >> $LOG_FILE
    DB_FILE="$LOCAL_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql"
    sshpass -p "$CLOUD_PASSWORD" ssh $CLOUD_USER@$CLOUD_IP "docker exec mysql-medgsp mysqldump -uroot -pYourPassword123! med_gsp --single-transaction --skip-lock-tables" > $DB_FILE 2>> $LOG_FILE
    
    if [ $? -eq 0 ]; then
        DB_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE")
        echo "[$(date)] ✅ 数据库导出成功: $DB_FILE (${DB_SIZE} bytes)" >> $LOG_FILE
    else
        echo "[$(date)] ❌ 数据库导出失败" >> $LOG_FILE
    fi
    
    # 3. 同步代码文件
    echo "[$(date)] 同步代码文件..." >> $LOG_FILE
    
    # Web代码
    WEB_DIR="$LOCAL_DIR/web"
    mkdir -p $WEB_DIR
    sshpass -p "$CLOUD_PASSWORD" scp -r $CLOUD_USER@$CLOUD_IP:/usr/share/nginx/html/bio/* $WEB_DIR/ >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        WEB_COUNT=$(find $WEB_DIR -type f 2>/dev/null | wc -l)
        echo "[$(date)] ✅ Web代码同步成功: $WEB_COUNT 个文件" >> $LOG_FILE
    else
        echo "[$(date)] ⚠️ Web代码同步失败" >> $LOG_FILE
    fi
    
    # 应用代码
    SOURCE_DIR="$LOCAL_DIR/source"
    mkdir -p $SOURCE_DIR
    sshpass -p "$CLOUD_PASSWORD" scp -r $CLOUD_USER@$CLOUD_IP:/opt/med-gsp-system/* $SOURCE_DIR/ >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        SOURCE_COUNT=$(find $SOURCE_DIR -type f 2>/dev/null | wc -l)
        echo "[$(date)] ✅ 应用代码同步成功: $SOURCE_COUNT 个文件" >> $LOG_FILE
    else
        echo "[$(date)] ⚠️ 应用代码同步失败" >> $LOG_FILE
    fi
    
    # 4. 验证数据
    echo "[$(date)] 数据验证..." >> $LOG_FILE
    TOTAL_FILES=$((WEB_COUNT + SOURCE_COUNT))
    if [ $TOTAL_FILES -gt 0 ] && [ -f "$DB_FILE" ]; then
        echo "[$(date)] ✅ 同步成功: ${TOTAL_FILES}个文件 + 数据库" >> $LOG_FILE
    else
        echo "[$(date)] ⚠️ 同步部分成功" >> $LOG_FILE
    fi
    
else
    echo "[$(date)] ❌ SSH连接失败" >> $LOG_FILE
fi

echo "=== 同步完成: $(date) ===" >> $LOG_FILE