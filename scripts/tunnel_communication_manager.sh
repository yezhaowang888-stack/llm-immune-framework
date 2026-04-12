#!/bin/bash
# SSH隧道通信管理器

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"
TUNNEL_PORT="18789"

echo "=== SSH隧道通信管理器 ==="
echo "时间: $(date)"
echo ""

# 1. 隧道状态管理
manage_tunnel() {
    echo "隧道状态管理..."
    ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
        "if ps aux | grep -q '[a]utossh'; then
             echo '✅ 隧道运行中'
         else
             echo '🔄 启动隧道...'
             nohup /root/autossh_tunnel.sh > /tmp/tunnel_$(date +%s).log 2>&1 &
             sleep 3
             echo '隧道启动完成'
         fi"
}

# 2. 消息发送
send_message() {
    local message="$1"
    echo "发送消息: $message"
    
    # 创建消息文件
    MESSAGE_JSON="{\"msg\":\"$message\",\"time\":\"$(date -Iseconds)\",\"from\":\"惠迈高级工程师\"}"
    
    ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
        "echo '$MESSAGE_JSON' > /tmp/tunnel_msg_$(date +%s).json && \
         echo '消息已保存到服务器'"
}

# 3. 检查响应
check_response() {
    echo "检查隧道响应..."
    ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
        "find /tmp -name '*response*' -type f -mmin -5 2>/dev/null | head -5"
}

# 主菜单
case "${1:-status}" in
    status)
        manage_tunnel
        ;;
    send)
        send_message "${2:-测试消息}"
        ;;
    check)
        check_response
        ;;
    *)
        echo "用法: $0 [status|send|check]"
        echo "  status - 检查隧道状态"
        echo "  send <消息> - 发送消息"
        echo "  check - 检查响应"
        ;;
esac