#!/bin/bash
# 添加云服务器公钥到本地配置

SERVER_PUB_KEY="$1"
LOCAL_KEY_FILE="$HOME/.ssh/cloud_sync_server"
LOG_FILE="/Users/mac/.openclaw/workspace/medical-software/logs/key-setup-$(date +%Y%m%d).log"

mkdir -p $(dirname $LOG_FILE)

echo "=== 服务器密钥配置开始: $(date) ===" >> $LOG_FILE

if [ -z "$SERVER_PUB_KEY" ]; then
    echo "❌ 未提供公钥内容" >> $LOG_FILE
    echo "使用方法: ./add-server-key.sh 'ssh-rsa AAA...'"
    exit 1
fi

# 1. 保存公钥到文件
echo "[$(date)] 保存服务器公钥..." >> $LOG_FILE
echo "$SERVER_PUB_KEY" > ${LOCAL_KEY_FILE}.pub
echo "✅ 公钥已保存: ${LOCAL_KEY_FILE}.pub" >> $LOG_FILE

# 2. 创建空的私钥文件（占位，实际使用本地密钥）
echo "[$(date)] 创建本地密钥对..." >> $LOG_FILE
ssh-keygen -t rsa -b 4096 -f $LOCAL_KEY_FILE -N "" -q
echo "✅ 本地密钥对已生成" >> $LOG_FILE

# 3. 配置SSH config
echo "[$(date)] 配置SSH..." >> $LOG_FILE
cat >> ~/.ssh/config << EOF

# 云服务器数据同步连接
Host cloud-medgsp-sync
    HostName 47.242.48.154
    User root
    IdentityFile $LOCAL_KEY_FILE
    StrictHostKeyChecking no
    PasswordAuthentication no
    ConnectTimeout 10
EOF

echo "✅ SSH配置已更新" >> $LOG_FILE

# 4. 测试配置
echo "[$(date)] 测试配置..." >> $LOG_FILE
ssh -G cloud-medgsp-sync >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SSH配置测试通过" >> $LOG_FILE
else
    echo "❌ SSH配置测试失败" >> $LOG_FILE
fi

# 5. 显示使用说明
echo "" >> $LOG_FILE
echo "=== 使用说明 ===" >> $LOG_FILE
echo "1. 连接测试: ssh cloud-medgsp-sync 'echo 测试成功'" >> $LOG_FILE
echo "2. 同步脚本已更新使用新配置" >> $LOG_FILE
echo "3. 密钥文件: $LOCAL_KEY_FILE" >> $LOG_FILE

echo "=== 配置完成: $(date) ===" >> $LOG_FILE

echo "✅ 服务器密钥配置完成"
echo "详情见日志: $LOG_FILE"