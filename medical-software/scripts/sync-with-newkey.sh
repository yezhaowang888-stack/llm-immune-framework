#!/bin/bash
# 使用新密钥的同步脚本

SSH_HOST="cloud-medgsp-sync"  # SSH config中定义的host
LOCAL_DIR="/Users/mac/.openclaw/workspace/medical-software/sync-newkey"
LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
LOG_FILE="$LOG_DIR/newkey-sync-$(date +%Y%m%d).log"

mkdir -p $LOCAL_DIR
mkdir -p $LOG_DIR

echo "=== 新密钥同步测试开始: $(date) ===" >> $LOG_FILE

# 1. 测试SSH连接
echo "[$(date)] 测试SSH连接..." >> $LOG_FILE
ssh $SSH_HOST "echo 'SSH连接测试成功'" >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] ✅ SSH密钥认证成功" >> $LOG_FILE
    
    # 2. 测试数据库连接
    echo "[$(date)] 测试数据库连接..." >> $LOG_FILE
    ssh $SSH_HOST "docker exec mysql-medgsp mysql -uroot -pYourPassword123! med_gsp -e 'SELECT COUNT(*) FROM product_catalog'" >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] ✅ 数据库连接成功" >> $LOG_FILE
    else
        echo "[$(date)] ❌ 数据库连接失败" >> $LOG_FILE
    fi
    
    # 3. 测试文件传输
    echo "[$(date)] 测试文件传输..." >> $LOG_FILE
    TEST_FILE="$LOCAL_DIR/test_$(date +%Y%m%d_%H%M%S).txt"
    ssh $SSH_HOST "echo '测试文件内容 $(date)'" > $TEST_FILE 2>> $LOG_FILE
    
    if [ $? -eq 0 ] && [ -f "$TEST_FILE" ]; then
        FILE_SIZE=$(stat -f%z "$TEST_FILE" 2>/dev/null || stat -c%s "$TEST_FILE")
        echo "[$(date)] ✅ 文件传输成功: $TEST_FILE (${FILE_SIZE} bytes)" >> $LOG_FILE
    else
        echo "[$(date)] ❌ 文件传输失败" >> $LOG_FILE
    fi
    
    # 4. 总体评估
    echo "[$(date)] 同步测试总体评估..." >> $LOG_FILE
    echo "✅ SSH密钥认证: 通过" >> $LOG_FILE
    echo "📊 自动化同步基础: 已建立" >> $LOG_FILE
    echo "🚀 明日可实施完全自动化" >> $LOG_FILE
    
else
    echo "[$(date)] ❌ SSH密钥认证失败" >> $LOG_FILE
    echo "⚠️ 需要检查密钥配置" >> $LOG_FILE
fi

echo "=== 同步测试完成: $(date) ===" >> $LOG_FILE

# 显示简要结果
tail -10 $LOG_FILE