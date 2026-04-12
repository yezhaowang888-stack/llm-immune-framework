#!/bin/bash
# 全量同步脚本（首次使用）

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
FULL_LOG="$LOG_DIR/full-sync-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/Users/mac/.openclaw/workspace/medical-software/mysql/backup"

# 创建日志目录
mkdir -p $LOG_DIR

echo "=== 全量同步开始: $(date) ===" > $FULL_LOG

# 1. 从云服务器导出完整数据库
echo "[$(date)] 导出完整数据库..." >> $FULL_LOG
FULL_DUMP_FILE="$BACKUP_DIR/full_dump_$(date +%Y%m%d_%H%M%S).sql"
ssh -i $SSH_KEY $CLOUD_USER@$CLOUD_IP "mysqldump -u$CLOUD_MYSQL_USER -p$CLOUD_MYSQL_PASSWORD $DATABASE \
    --single-transaction \
    --skip-lock-tables \
    --routines \
    --triggers \
    --events" > $FULL_DUMP_FILE 2>> $FULL_LOG

if [ $? -eq 0 ]; then
    DUMP_SIZE=$(stat -f%z "$FULL_DUMP_FILE" 2>/dev/null || stat -c%s "$FULL_DUMP_FILE")
    echo "[$(date)] 完整数据库导出成功: $FULL_DUMP_FILE (${DUMP_SIZE} bytes)" >> $FULL_LOG
    
    # 2. 清空本地数据库并导入
    echo "[$(date)] 清空并导入本地数据库..." >> $FULL_LOG
    
    # 先删除数据库（如果存在）
    mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD -e "DROP DATABASE IF EXISTS $DATABASE" 2>> $FULL_LOG
    
    # 创建数据库
    mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD -e "CREATE DATABASE $DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>> $FULL_LOG
    
    # 导入数据
    mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE < $FULL_DUMP_FILE 2>> $FULL_LOG
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] 完整数据库导入成功" >> $FULL_LOG
        
        # 3. 同步所有代码文件
        echo "[$(date)] 同步所有代码文件..." >> $FULL_LOG
        CODE_DIR="/Users/mac/.openclaw/workspace/medical-software/code"
        mkdir -p $CODE_DIR
        
        # 同步Web代码
        rsync -avz -e "ssh -i $SSH_KEY" \
            --progress \
            --delete \
            $CLOUD_USER@$CLOUD_IP:/usr/share/nginx/html/bio/ \
            $CODE_DIR/web/ >> $FULL_LOG 2>&1
        
        # 同步应用代码
        rsync -avz -e "ssh -i $SSH_KEY" \
            --progress \
            $CLOUD_USER@$CLOUD_IP:/root/medgsp/ \
            $CODE_DIR/source/ >> $FULL_LOG 2>&1
        
        # 4. 初始化同步时间
        echo $(date +"%Y-%m-%d %H:%M:%S") > "$BACKUP_DIR/last_sync_time.txt"
        echo "[$(date)] 同步时间已初始化" >> $FULL_LOG
        
        # 5. 验证数据完整性
        echo "[$(date)] 验证数据完整性..." >> $FULL_LOG
        
        # 检查表数量
        LOCAL_TABLES=$(mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE -e "SHOW TABLES" -s | wc -l)
        echo "[$(date)] 本地数据库表数量: $LOCAL_TABLES" >> $FULL_LOG
        
        # 检查产品数据
        PRODUCT_COUNT=$(mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE -e "SELECT COUNT(*) FROM product_catalog" -s -N)
        echo "[$(date)] 产品表记录数: $PRODUCT_COUNT" >> $FULL_LOG
        
        # 检查客户数据
        CUSTOMER_COUNT=$(mysql -h $LOCAL_MYSQL_HOST -P $LOCAL_MYSQL_PORT -u$LOCAL_MYSQL_USER -p$LOCAL_MYSQL_PASSWORD $DATABASE -e "SELECT COUNT(*) FROM business_partner" -s -N)
        echo "[$(date)] 客户表记录数: $CUSTOMER_COUNT" >> $FULL_LOG
        
        echo "[$(date)] ✅ 全量同步完成" >> $FULL_LOG
        
    else
        echo "[$(date)] ❌ 数据库导入失败" >> $FULL_LOG
    fi
else
    echo "[$(date)] ❌ 数据库导出失败" >> $FULL_LOG
fi

echo "=== 全量同步结束: $(date) ===" >> $FULL_LOG