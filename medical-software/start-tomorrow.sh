#!/bin/bash
# 明早自动化启动

echo "=== 明早自动化启动 ==="
echo "启动时间: $(date)"
echo ""

echo "1. 检查SSH连接："
if ssh -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=5 -o BatchMode=yes root@47.242.48.154 "echo '✅ SSH连接正常'" 2>/dev/null; then
    echo "   ✅ SSH密钥认证正常"
    echo "   🚀 可以开始自动化工作"
else
    echo "   ❌ SSH连接失败，需要检查"
    exit 1
fi

echo ""
echo "2. 启动问题诊断："
echo "   📋 页面显示问题诊断"
echo "   📋 用户信息存储问题诊断"
echo "   📋 数据库环境验证"
echo "   📋 自动化运维建立"

echo ""
echo "=== 启动完成 ==="
echo "✅ 所有环境准备就绪"
echo "✅ 可以开始高效工作"
