#!/bin/bash
# 验证数据库备份脚本

BACKUP_FILE="$1"
EXTRACT_DIR="/tmp/medgsp_verify_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/Users/mac/.openclaw/workspace/medical-software/logs/verify-$(date +%Y%m%d).log"

mkdir -p $(dirname $LOG_FILE)

echo "=== 数据库验证开始: $(date) ===" >> $LOG_FILE
echo "备份文件: $BACKUP_FILE" >> $LOG_FILE

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 备份文件不存在: $BACKUP_FILE" >> $LOG_FILE
    exit 1
fi

# 1. 检查文件完整性
echo "[$(date)] 检查文件完整性..." >> $LOG_FILE
tar -tzf "$BACKUP_FILE" > /dev/null 2>> $LOG_FILE

if [ $? -ne 0 ]; then
    echo "❌ 备份文件损坏" >> $LOG_FILE
    exit 1
fi

echo "✅ 备份文件完整" >> $LOG_FILE

# 2. 解压文件
echo "[$(date)] 解压文件..." >> $LOG_FILE
mkdir -p $EXTRACT_DIR
tar -xzf "$BACKUP_FILE" -C $EXTRACT_DIR --strip-components=1 2>> $LOG_FILE

if [ $? -ne 0 ]; then
    echo "❌ 解压失败" >> $LOG_FILE
    exit 1
fi

echo "✅ 解压成功到: $EXTRACT_DIR" >> $LOG_FILE

# 3. 检查目录结构
echo "[$(date)] 检查目录结构..." >> $LOG_FILE
ls -la $EXTRACT_DIR/ >> $LOG_FILE

# 4. 检查数据库文件
DB_FILES=$(find $EXTRACT_DIR -name "*.sql" -type f)
echo "[$(date)] 找到数据库文件: $(echo $DB_FILES | wc -w) 个" >> $LOG_FILE

for DB_FILE in $DB_FILES; do
    FILE_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE")
    echo "[$(date)] 数据库文件: $(basename $DB_FILE) (${FILE_SIZE} bytes)" >> $LOG_FILE
    
    # 检查SQL文件内容
    if [ $FILE_SIZE -gt 1000 ]; then
        echo "✅ 数据库文件大小正常" >> $LOG_FILE
        
        # 检查表结构
        TABLE_COUNT=$(grep -c "CREATE TABLE" "$DB_FILE" 2>/dev/null || echo 0)
        echo "   包含表数量: $TABLE_COUNT" >> $LOG_FILE
        
        # 检查数据行
        INSERT_COUNT=$(grep -c "INSERT INTO" "$DB_FILE" 2>/dev/null || echo 0)
        echo "   插入语句数量: $INSERT_COUNT" >> $LOG_FILE
        
        if [ $TABLE_COUNT -gt 0 ] && [ $INSERT_COUNT -gt 0 ]; then
            echo "✅ 数据库内容完整" >> $LOG_FILE
        else
            echo "⚠️ 数据库内容可能不完整" >> $LOG_FILE
        fi
    else
        echo "⚠️ 数据库文件过小，可能有问题" >> $LOG_FILE
        head -20 "$DB_FILE" >> $LOG_FILE
    fi
done

# 5. 检查代码文件
echo "[$(date)] 检查代码文件..." >> $LOG_FILE
WEB_FILES=$(find $EXTRACT_DIR -path "*/web/*" -type f 2>/dev/null | wc -l)
SOURCE_FILES=$(find $EXTRACT_DIR -path "*/source/*" -type f 2>/dev/null | wc -l)

echo "Web文件数量: $WEB_FILES" >> $LOG_FILE
echo "源代码文件数量: $SOURCE_FILES" >> $LOG_FILE

if [ $WEB_FILES -gt 0 ] && [ $SOURCE_FILES -gt 0 ]; then
    echo "✅ 代码文件完整" >> $LOG_FILE
else
    echo "⚠️ 代码文件可能不完整" >> $LOG_FILE
fi

# 6. 总体评估
echo "[$(date)] 总体评估..." >> $LOG_FILE
if [ $(echo $DB_FILES | wc -w) -gt 0 ] && [ $WEB_FILES -gt 0 ] && [ $SOURCE_FILES -gt 0 ]; then
    echo "✅ 备份完整：包含数据库 + Web代码 + 源代码" >> $LOG_FILE
    echo "今日数据交换目标达成！" >> $LOG_FILE
else
    echo "⚠️ 备份不完整，需要补充" >> $LOG_FILE
fi

echo "=== 验证完成: $(date) ===" >> $LOG_FILE

# 清理临时文件
rm -rf $EXTRACT_DIR

echo "验证完成，详情见日志: $LOG_FILE"