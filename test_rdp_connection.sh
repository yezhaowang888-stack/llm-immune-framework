#!/bin/bash

# Surface连接测试脚本
SURFACE_IP="192.168.3.96"

echo "=== Surface RDP连接测试 ==="
echo "Surface IP: $SURFACE_IP"
echo ""

# 检查RDP端口是否开放
echo "1. 检查RDP端口(3389)..."
if nc -z -v -G 3 $SURFACE_IP 3389 2>/dev/null; then
    echo "✅ RDP端口开放"
else
    echo "❌ RDP端口未响应"
    exit 1
fi

echo ""
echo "=== 用户名格式说明 ==="
echo "请尝试以下格式之一："
echo "1. 本地用户名: 王业朝"
echo "2. Microsoft账户: yezhaowang@163.com"
echo "3. 计算机名\\用户名: 2B\\王业朝"
echo "4. .\\用户名: .\\王业朝 (本地账户)"
echo ""

echo "=== 连接命令示例 ==="
echo "使用FreeRDP连接："
echo "  xfreerdp /v:$SURFACE_IP /u:王业朝 /p:你的密码"
echo "  xfreerdp /v:$SURFACE_IP /u:yezhaowang@163.com /p:你的密码"
echo "  xfreerdp /v:$SURFACE_IP /u:2B\\\\王业朝 /p:你的密码"
echo ""
echo "使用Microsoft Remote Desktop："
echo "  1. 打开应用"
echo "  2. 添加PC: $SURFACE_IP"
echo "  3. 设置用户名和密码"
echo "  4. 连接"