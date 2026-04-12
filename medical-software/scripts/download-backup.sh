#!/bin/bash
# 下载云服务器备份脚本

BACKUP_URL="http://47.242.48.154/medgsp_complete_*.tar.gz"
LOCAL_DIR="/Users/mac/.openclaw/workspace/medical-software/backup-received"
LOG_FILE="/Users/mac/.openclaw/workspace/medical-software/logs/download-$(date +%Y%m%d).log"

mkdir -p $LOCAL_DIR
mkdir -p $(dirname $LOG_FILE)

echo "=== 备份下载开始: $(date) ===" >> $LOG_FILE

# 1. 尝试下载
echo "[$(date)] 尝试下载备份文件..." >> $LOG_FILE

# 先获取可能的文件名
BACKUP_FILE="medgsp_complete_$(date +%Y%m%d)*.tar.gz"
FULL_URL="http://47.242.48.154/$BACKUP_FILE"

curl -s -I $FULL_URL 2>> $LOG_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] 备份文件可访问，开始下载..." >> $LOG_FILE
    
    # 下载文件
    LOCAL_FILE="$LOCAL_DIR/medgsp_backup_$(date +%Y%m%d_%H%M).tar.gz"
    curl -o $LOCAL_FILE $FULL_URL 2>> $LOG_FILE
    
    if [ $? -eq 0 ]; then
        FILE_SIZE=$(stat -f%z "$LOCAL_FILE" 2>/dev/null || stat -c%s "$LOCAL_FILE")
        echo "[$(date)] ✅ 下载成功: $LOCAL_FILE (${FILE_SIZE} bytes)" >> $LOG_FILE
        
        # 解压验证
        echo "[$(date)] 解压验证..." >> $LOG_FILE
        tar -tzf $LOCAL_FILE > /dev/null 2>> $LOG_FILE
        
        if [ $? -eq 0 ]; then
            echo "[$(date)] ✅ 备份文件完整" >> $LOG_FILE
            
            # 解压到目录
            EXTRACT_DIR="$LOCAL_DIR/extracted_$(date +%Y%m%d_%H%M)"
            mkdir -p $EXTRACT_DIR
            tar -xzf $LOCAL_FILE -C $EXTRACT_DIR --strip-components=1 2>> $LOG_FILE
            
            if [ $? -eq 0 ]; then
                FILE_COUNT=$(find $EXTRACT_DIR -type f 2>/dev/null | wc -l)
                echo "[$(date)] ✅ 解压成功: $FILE_COUNT 个文件" >> $LOG_FILE
                
                # 检查内容
                echo "[$(date)] 备份内容:" >> $LOG_FILE
                ls -la $EXTRACT_DIR/ >> $LOG_FILE
                
                # 检查数据库文件
                if [ -f "$EXTRACT_DIR/database.sql" ]; then
                    DB_SIZE=$(stat -f%z "$EXTRACT_DIR/database.sql" 2>/dev/null || stat -c%s "$EXTRACT_DIR/database.sql")
                    echo "[$(date)] ✅ 数据库备份: ${DB_SIZE} bytes" >> $LOG_FILE
                else
                    echo "[$(date)] ⚠️ 未找到数据库备份" >> $LOG_FILE
                fi
                
            else
                echo "[$(date)] ❌ 解压失败" >> $LOG_FILE
            fi
        else
            echo "[$(date)] ❌ 备份文件损坏" >> $LOG_FILE
        fi
    else
        echo "[$(date)] ❌ 下载失败" >> $LOG_FILE
    fi
else
    echo "[$(date)] ⚠️ 备份文件不可访问" >> $LOG_FILE
    echo "[$(date)] 请手动下载: $FULL_URL" >> $LOG_FILE
fi

echo "=== 下载完成: $(date) ===" >> $LOG_FILE