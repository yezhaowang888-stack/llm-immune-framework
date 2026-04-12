#!/bin/bash
# 仅同步代码文件（不依赖MySQL容器）

CLOUD_IP="47.242.48.154"
CLOUD_USER="root"
SSH_KEY="$HOME/.ssh/cloud_sync_2h"
LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
SYNC_LOG="$LOG_DIR/code-sync-$(date +%Y%m%d).log"
CODE_DIR="/Users/mac/.openclaw/workspace/medical-software/code"

mkdir -p $LOG_DIR
mkdir -p $CODE_DIR

echo "=== 代码同步开始: $(date) ===" >> $SYNC_LOG

# 1. 同步Web代码
echo "[$(date)] 同步Web代码..." >> $SYNC_LOG
rsync -avz -e "ssh -i $SSH_KEY" \
    --progress \
    --delete \
    $CLOUD_USER@$CLOUD_IP:/usr/share/nginx/html/bio/ \
    $CODE_DIR/web/ >> $SYNC_LOG 2>&1

WEB_RESULT=$?
if [ $WEB_RESULT -eq 0 ]; then
    WEB_COUNT=$(find $CODE_DIR/web -type f 2>/dev/null | wc -l)
    echo "[$(date)] ✅ Web代码同步成功: $WEB_COUNT 个文件" >> $SYNC_LOG
else
    echo "[$(date)] ❌ Web代码同步失败" >> $SYNC_LOG
fi

# 2. 同步应用代码
echo "[$(date)] 同步应用代码..." >> $SYNC_LOG
rsync -avz -e "ssh -i $SSH_KEY" \
    --progress \
    $CLOUD_USER@$CLOUD_IP:/root/medgsp/ \
    $CODE_DIR/source/ >> $SYNC_LOG 2>&1

SOURCE_RESULT=$?
if [ $SOURCE_RESULT -eq 0 ]; then
    SOURCE_COUNT=$(find $CODE_DIR/source -type f 2>/dev/null | wc -l)
    echo "[$(date)] ✅ 应用代码同步成功: $SOURCE_COUNT 个文件" >> $SYNC_LOG
else
    echo "[$(date)] ❌ 应用代码同步失败" >> $SYNC_LOG
fi

# 3. 导出数据库结构（不导入）
echo "[$(date)] 导出数据库结构..." >> $SYNC_LOG
DB_STRUCT_FILE="/Users/mac/.openclaw/workspace/medical-software/mysql/backup/db_structure_$(date +%Y%m%d_%H%M%S).sql"
ssh -i $SSH_KEY $CLOUD_USER@$CLOUD_IP "mysqldump -uroot -p123456 medgsp --no-data --routines --triggers --events" > $DB_STRUCT_FILE 2>> $SYNC_LOG

if [ $? -eq 0 ]; then
    STRUCT_SIZE=$(stat -f%z "$DB_STRUCT_FILE" 2>/dev/null || stat -c%s "$DB_STRUCT_FILE")
    echo "[$(date)] ✅ 数据库结构导出成功: $DB_STRUCT_FILE (${STRUCT_SIZE} bytes)" >> $SYNC_LOG
else
    echo "[$(date)] ⚠️ 数据库结构导出失败，继续代码同步" >> $SYNC_LOG
fi

# 4. 导出数据（仅备份，不导入）
echo "[$(date)] 导出数据备份..." >> $SYNC_LOG
DB_DATA_FILE="/Users/mac/.openclaw/workspace/medical-software/mysql/backup/db_data_$(date +%Y%m%d_%H%M%S).sql"
ssh -i $SSH_KEY $CLOUD_USER@$CLOUD_IP "mysqldump -uroot -p123456 medgsp --no-create-info --skip-triggers" > $DB_DATA_FILE 2>> $SYNC_LOG

if [ $? -eq 0 ]; then
    DATA_SIZE=$(stat -f%z "$DB_DATA_FILE" 2>/dev/null || stat -c%s "$DB_DATA_FILE")
    echo "[$(date)] ✅ 数据备份导出成功: $DB_DATA_FILE (${DATA_SIZE} bytes)" >> $SYNC_LOG
else
    echo "[$(date)] ⚠️ 数据备份导出失败" >> $SYNC_LOG
fi

# 总体评估
if [ $WEB_RESULT -eq 0 ] || [ $SOURCE_RESULT -eq 0 ]; then
    echo "[$(date)] ✅ 代码同步部分成功" >> $SYNC_LOG
else
    echo "[$(date)] ❌ 代码同步完全失败" >> $SYNC_LOG
fi

echo "=== 代码同步完成: $(date) ===" >> $SYNC_LOG