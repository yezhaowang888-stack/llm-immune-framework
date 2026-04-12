#!/bin/bash
# 小迈任务进展监控脚本

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"

echo "=== 小迈任务进展监控 ==="
echo "监控时间: $(date)"
echo ""

# 检查直接指令文件
echo "1. 检查直接指令状态:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "if [ -f /root/紧急任务_小迈请查收.txt ]; then
         ls -la /root/紧急任务_小迈请查收.txt
         echo '文件存在，创建时间:'
         stat -c %y /root/紧急任务_小迈请查收.txt
     else
         echo '直接指令文件不存在，可能名称不同'
         ls -la /root/*任务*.txt 2>/dev/null || echo '未找到任务文件'
     fi"

# 检查小迈是否已查看
echo ""
echo "2. 检查小迈活动痕迹:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '最近文件访问:' && \
     find /root/tasks/ -type f -exec stat -c '%y %n' {} \; 2>/dev/null | \
     sort -r | head -5"

# 检查状态更新
echo ""
echo "3. 检查任务状态更新:"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "if [ -f /root/tasks/current/status.txt ]; then
         echo '状态文件最后更新:'
         tail -10 /root/tasks/current/status.txt
     else
         echo '状态文件尚未创建'
     fi"

echo ""
echo "=== 监控完成 ==="
echo "注：需要小迈登录服务器并开始工作"