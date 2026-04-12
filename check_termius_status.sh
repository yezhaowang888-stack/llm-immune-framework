#!/bin/bash

# 检查Termius消息发送状态
echo "=== Termius消息发送状态检查 ==="
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 检查Termius进程
echo "1. Termius进程状态:"
if pgrep -x "Termius" > /dev/null; then
    echo "   ✅ Termius正在运行"
    TERMIUS_COUNT=$(pgrep -x "Termius" | wc -l)
    echo "   进程数量: $TERMIUS_COUNT"
else
    echo "   ❌ Termius未运行"
fi

# 检查Apple Script权限
echo ""
echo "2. Apple Script权限状态:"
if [ -f "/Users/mac/.openclaw/workspace/activate_and_send_termius.applescript" ]; then
    echo "   ✅ Apple Script文件存在"
    # 测试简单Apple Script
    osascript -e 'tell application "System Events" to get name of processes' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Apple Script权限正常"
    else
        echo "   ⚠️ Apple Script权限可能有问题"
    fi
else
    echo "   ❌ Apple Script文件不存在"
fi

# 检查消息文件
echo ""
echo "3. 消息文件状态:"
MESSAGE_FILE="/Users/mac/.openclaw/workspace/TO小迈-询问昨天工作情况.md"
if [ -f "$MESSAGE_FILE" ]; then
    echo "   ✅ 消息文件存在: $(basename "$MESSAGE_FILE")"
    echo "   文件大小: $(wc -c < "$MESSAGE_FILE") 字节"
    echo "   创建时间: $(stat -f "%Sm" "$MESSAGE_FILE")"
else
    echo "   ❌ 消息文件不存在"
fi

# 检查SSH连接状态
echo ""
echo "4. SSH连接状态检查:"
SSH_KEY="$HOME/.ssh/cloud_sync_2h"
if [ -f "$SSH_KEY" ]; then
    echo "   ✅ SSH密钥文件存在"
    echo "   密钥权限: $(stat -f "%A" "$SSH_KEY")"
    
    # 测试SSH连接（快速测试）
    echo "   测试SSH连接..."
    timeout 5 ssh -T -o ConnectTimeout=3 -i "$SSH_KEY" root@47.242.48.154 echo "连接成功" 2>&1
    SSH_RESULT=$?
    if [ $SSH_RESULT -eq 0 ]; then
        echo "   ✅ SSH连接成功"
    elif [ $SSH_RESULT -eq 124 ]; then
        echo "   ⏳ SSH连接超时"
    else
        echo "   ❌ SSH连接失败 (错误码: $SSH_RESULT)"
    fi
else
    echo "   ❌ SSH密钥文件不存在"
fi

# 检查MySQL容器
echo ""
echo "5. MySQL容器状态:"
if command -v docker &> /dev/null; then
    echo "   ✅ Docker已安装"
    DOCKER_PS=$(docker ps --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null)
    if [ -n "$DOCKER_PS" ]; then
        echo "   ✅ MySQL容器运行中:"
        echo "$DOCKER_PS" | sed 's/^/   /'
    else
        echo "   ⚠️ 未找到运行的MySQL容器"
    fi
else
    echo "   ❌ Docker未安装"
fi

echo ""
echo "=== 检查完成 ==="
echo "建议："
echo "1. 查看Termius窗口确认消息是否成功发送"
echo "2. 等待小迈回复（截止时间：13:30）"
echo "3. 如有问题，手动在Termius中发送消息"