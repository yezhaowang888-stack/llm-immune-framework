#!/bin/bash
# 每2小时同步脚本

# 配置参数
CLOUD_IP="47.242.48.154"
CLOUD_USER="root"
SSH_KEY="$HOME/.ssh/cloud_sync_2h"
LOCAL_MYSQL_HOST="localhost"
LOCAL_MYSQL_PORT="3307"
LOCAL_MYSQL_USER="root"
LOCAL_MYSQL_PASSWORD="local123456"
CLOUD_MYSQL_USER="root"
CLOUD_MYSQL_PASSWORD="123456"
DATABASE="medgsp"
LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
SYNC_LOG="$LOG_DIR/sync-$(date +%Y%m%d).log"
BACKUP_DIR="/Users/mac/.openclaw/workspace/medical-software/mysql/backup"

# 创建日志目录
mkdir -p $LOG_DIR

# 记录开始
echo "=== 2小时同步开始: $(date) ===" >> $SYNC_LOG

# 1. 从云服务器导出增量数据
echo "[$(date)] 从云服务器导出增量数据..." >> $SYNC_LOG

# 获取上次同步时间
LAST_SYNC_FILE="$BACKUP_DIR/last_sync_time.txt"
if [ -f "$LAST_SYNC_FILE" ]; then
    LAST_SYNC=$(cat $LAST_SYNC_FILE)
else
    # 如果是第一次同步，同步最近24小时的数据
    LAST_SYNC=$(date -v-24H +"%Y-%m-%d %H:%M:%S")
fi

# 导出增量数据
INCREMENTAL_FILE="$BACKUP_DIR/incremental_$(date +%Y%m%d_%H%M%S).sql"
ssh -i $SSH_KEY $CLOUD_USER@$CLOUD_IP "mysqldump -u$CLOUD_MYSQL_USER -p$CLOUD_MYSQL_PASSWORD $DATABASE \
    --single-transaction \
    --skip-lock-tables \
    --where=\"updated_at > '$LAST_SYNC' OR created_at > '$LAST_SYNC'\" \
    --no-create-info" > $INCREMENTAL_FILE 2>> $SYNC_LOG

if [ $? -eq 0 ] && [ -s "$INCREMENTAL_FILE" ]; then
    INCREMENTAL_SIZE=$(stat -f%z "$INCREMENTAL_FILE" 2>/dev/null || stat -c%s "$INCREMENTAL_FILE")
    echo "[$(date)] 增量数据导出成功: $INCREMENTAL_FILE (${INCREMENTAL_SIZE} bytes)" >> $SYNC_LOG
    
    # 2. 导入到本地MySQL
    echo "[$(date)] 导入数据到本地MySQL..." >> $SYNC_LOG
    mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE < $INCREMENTAL_FILE 2>> $SYNC_LOG
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] 数据导入成功" >> $SYNC_LOG
        
        # 3. 同步代码文件
        echo "[$(date)] 同步代码文件..." >> $SYNC_LOG
        CODE_BACKUP_DIR="/Users/mac/.openclaw/workspace/medical-software/code-backup/$(date +%Y%m%d_%H%M)"
        mkdir -p $CODE_BACKUP_DIR
        
        # 同步Web代码
        rsync -avz -e "ssh -i $SSH_KEY" \
            --progress \
            --delete \
            $CLOUD_USER@$CLOUD_IP:/usr/share/nginx/html/bio/ \
            $CODE_BACKUP_DIR/web/ >> $SYNC_LOG 2>&1
        
        # 同步应用代码
        rsync -avz -e "ssh -i $SSH_KEY" \
            --progress \
            $CLOUD_USER@$CLOUD_IP:/root/medgsp/ \
            $CODE_BACKUP_DIR/source/ >> $SYNC_LOG 2>&1
        
        # 4. 更新同步时间
        echo $(date +"%Y-%m-%d %H:%M:%S") > $LAST_SYNC_FILE
        echo "[$(date)] 同步时间已更新" >> $SYNC_LOG
        
        # 5. 数据验证
        echo "[$(date)] 执行数据验证..." >> $SYNC_LOG
        
        # 检查本地数据行数
        LOCAL_COUNT=$(mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE -e "SELECT COUNT(*) FROM product_catalog" -s -N)
        echo "[$(date)] 本地产品表记录数: $LOCAL_COUNT" >> $SYNC_LOG
        
        # 检查云数据行数
        CLOUD_COUNT=$(ssh -i $SSH_KEY $CLOUD_USER@$CLOUD_IP "mysql -u$CLOUD_MYSQL_USER -p$CLOUD_MYSQL_PASSWORD $DATABASE -e 'SELECT COUNT(*) FROM product_catalog' -s -N")
        echo "[$(date)] 云服务器产品表记录数: $CLOUD_COUNT" >> $SYNC_LOG
        
        if [ "$LOCAL_COUNT" = "$CLOUD_COUNT" ]; then
            echo "[$(date)] ✅ 数据一致性验证通过" >> $SYNC_LOG
        else
            echo "[$(date)] ⚠️ 数据不一致: 本地$LOCAL_COUNT vs 云$CLOUD_COUNT" >> $SYNC_LOG
        fi
        
    else
        echo "[$(date)] ❌ 数据导入失败" >> $SYNC_LOG
    fi
else
    echo "[$(date)] ℹ️ 无新增数据需要同步" >> $SYNC_LOG
fi

# 6. 清理旧备份（保留最近7天）
echo "[$(date)] 清理旧备份..." >> $SYNC_LOG
find $BACKUP_DIR -name "incremental_*.sql" -mtime +7 -delete >> $SYNC_LOG 2>&1
find /Users/mac/.openclaw/workspace/medical-software/code-backup -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

echo "=== 2小时同步完成: $(date) ===" >> $SYNC_LOG
echo "" >> $SYNC_LOG