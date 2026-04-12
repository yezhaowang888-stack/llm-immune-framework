#!/bin/bash
# 监控任务提醒系统

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"

echo "=== 任务提醒系统监控 ==="
echo "时间: $(date)"
echo ""

# 1. 检查登录记录
echo "1. 最近登录记录:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "lastlog | grep -v 'Never logged in' | head -5"

# 2. 检查提醒文件
echo ""
echo "2. 提醒文件状态:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '登录提示文件:' && \
     wc -l /etc/motd && \
     echo '' && \
     echo '紧急任务文件:' && \
     ls -la /root/!!!紧急任务!!!.txt && \
     echo '' && \
     echo '任务文件:' && \
     ls -la /root/huimai-openclaw/tasks/active/TASK-*-004.json"

# 3. 检查任务状态
echo ""
echo "3. 任务状态检查:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "if [ -f /root/huimai-openclaw/tasks/active/TASK-*-004.json ]; then
         echo '任务文件内容摘要:'
         cat /root/huimai-openclaw/tasks/active/TASK-*-004.json | \
         grep -E 'status|updated_at|progress' || echo '无状态更新'
     else
         echo '任务文件不存在'
     fi"

# 4. 检查文件访问时间
echo ""
echo "4. 文件访问痕迹:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '任务文件最后访问:' && \
     stat -c '%x %n' /root/huimai-openclaw/tasks/active/TASK-*-004.json 2>/dev/null || echo '无法获取'"

echo ""
echo "=== 监控完成 ==="
echo "注：小迈登录时会自动看到任务提醒"