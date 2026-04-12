#!/bin/bash
# 监控隧道响应

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"

echo "=== 隧道响应监控 ==="
echo "时间: $(date)"
echo "隧道端口: 18789"
echo ""

# 1. 检查隧道状态
echo "1. 隧道运行状态:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "ps aux | grep autossh | grep -v grep | head -2"

# 2. 检查隧道消息
echo ""
echo "2. 隧道消息状态:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '发送的消息:' && \
     ls -la /root/tunnel_messages/ 2>/dev/null && \
     echo '' && \
     echo '接收的消息:' && \
     find /root -name '*response*' -o -name '*reply*' -type f -newer /root/tunnel_messages/instruction_*.json 2>/dev/null | head -5"

# 3. 检查任务状态
echo ""
echo "3. 任务执行状态:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "if [ -f /root/huimai-openclaw/tasks/active/TASK-*-004.json ]; then
         echo '任务文件状态变化:'
         stat -c '%y %n' /root/huimai-openclaw/tasks/active/TASK-*-004.json
         echo ''
         echo '任务状态:'
         grep -E 'status|progress|updated' /root/huimai-openclaw/tasks/active/TASK-*-004.json
     fi"

echo ""
echo "=== 监控完成 ==="
echo "注：小迈智能体应通过隧道实时响应"