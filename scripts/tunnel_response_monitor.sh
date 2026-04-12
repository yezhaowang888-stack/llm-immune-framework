#!/bin/bash
# SSH隧道响应监控系统

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"
TASK_ID="TASK-20260408-004"

echo "=== SSH隧道响应监控系统 ==="
echo "监控开始: $(date)"
echo "任务ID: $TASK_ID"
echo "隧道端口: 18789"
echo ""

# 1. 隧道健康检查
echo "1. 隧道健康检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '隧道进程:' && \
     ps aux | grep -E '[a]utossh|[s]sh.*18789' | head -2 && \
     echo '' && \
     echo '隧道端口:' && \
     netstat -tln 2>/dev/null | grep 18789 || echo '端口未监听（可能正常）'"

# 2. 指令状态检查
echo ""
echo "2. 指令状态检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '发送的指令:' && \
     ls -la /root/tunnel_comms/inbox/ 2>/dev/null && \
     echo '' && \
     echo '最后指令时间:' && \
     find /root/tunnel_comms/inbox/ -type f -exec stat -c '%y %n' {} \; 2>/dev/null | sort -r | head -3"

# 3. 响应检查
echo ""
echo "3. 响应检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '响应目录:' && \
     ls -la /root/tunnel_comms/outbox/ 2>/dev/null && \
     echo '' && \
     echo '最近响应:' && \
     find /root/tunnel_comms/outbox/ -type f -name '*.json' -exec cat {} \; 2>/dev/null | head -100"

# 4. 任务状态检查
echo ""
echo "4. 任务状态检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "if [ -f /root/huimai-openclaw/tasks/active/$TASK_ID.json ]; then
         echo '任务文件状态:' && \
         stat -c '修改时间: %y' /root/huimai-openclaw/tasks/active/$TASK_ID.json && \
         echo '' && \
         echo '任务内容状态:' && \
         grep -E 'status|progress|updated' /root/huimai-openclaw/tasks/active/$TASK_ID.json
     else
         echo '任务文件不存在'
     fi"

# 5. 系统活动检查
echo ""
echo "5. 系统活动检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '最近登录记录:' && \
     lastlog | tail -5 | grep -v 'Never' && \
     echo '' && \
     echo '最近文件活动:' && \
     find /root/huimai-openclaw/tasks/ -type f -exec stat -c '%x %n' {} \; 2>/dev/null | sort -r | head -5"

echo ""
echo "=== 监控完成 ==="
echo "监控时间: $(date)"
echo "响应等待: 5分钟超时"
echo "下次检查: 2分钟后"