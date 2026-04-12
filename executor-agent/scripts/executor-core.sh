#!/bin/bash
# 执行者智能体核心脚本

EXECUTOR_HOME="/Users/mac/.openclaw/workspace/executor-agent"
LOG_FILE="$EXECUTOR_HOME/logs/execution_$(date +%Y%m%d_%H%M%S).log"
SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="cloud-medgsp-sync"

echo "=== 执行者智能体启动 ===" | tee -a "$LOG_FILE"
echo "时间: $(date)" | tee -a "$LOG_FILE"
echo "执行者: 本地执行智能体" | tee -a "$LOG_FILE"
echo "目标服务器: $SERVER" | tee -a "$LOG_FILE"
echo "任务ID: $1" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 1. 验证SSH连接
echo "1. 验证SSH连接..." | tee -a "$LOG_FILE"
if ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" "echo '✅ SSH连接测试成功 - \$(date)'"; then
    echo "✅ SSH连接正常" | tee -a "$LOG_FILE"
else
    echo "❌ SSH连接失败" | tee -a "$LOG_FILE"
    exit 1
fi

# 2. 执行任务
TASK_FILE="$EXECUTOR_HOME/tasks/$1.json"
if [ -f "$TASK_FILE" ]; then
    echo "2. 执行任务: $1" | tee -a "$LOG_FILE"
    
    # 读取任务内容
    TASK_CONTENT=$(cat "$TASK_FILE")
    echo "任务内容:" | tee -a "$LOG_FILE"
    echo "$TASK_CONTENT" | tee -a "$LOG_FILE"
    
    # 执行任务命令
    COMMAND=$(echo "$TASK_CONTENT" | jq -r '.command' 2>/dev/null)
    if [ -n "$COMMAND" ] && [ "$COMMAND" != "null" ]; then
        echo "执行命令: $COMMAND" | tee -a "$LOG_FILE"
        ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" "$COMMAND" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "⚠️ 任务文件中未找到命令" | tee -a "$LOG_FILE"
    fi
else
    echo "2. 直接执行命令: $*" | tee -a "$LOG_FILE"
    # 如果没有任务文件，直接执行参数
    ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" "$*" 2>&1 | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== 执行完成 ===" | tee -a "$LOG_FILE"
echo "完成时间: $(date)" | tee -a "$LOG_FILE"
echo "日志文件: $LOG_FILE" | tee -a "$LOG_FILE"