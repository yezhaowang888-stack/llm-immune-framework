#!/bin/bash
# SSH连接问题诊断脚本

echo "=== SSH连接问题全面诊断 ==="
echo "诊断时间: $(date)"
echo ""

echo "1. 本地环境检查:"
echo "   私钥文件:"
ls -la ~/.ssh/cloud_sync_2h
echo "   私钥指纹:"
ssh-keygen -l -f ~/.ssh/cloud_sync_2h

echo ""
echo "2. 连接测试（详细模式）:"
echo "   开始详细测试..."
ssh -v -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=10 root@47.242.48.154 "echo '连接测试'" 2>&1 | grep -E "(debug1:.*auth|Authentication|failed|success|password)" | head -20

echo ""
echo "3. 备选方案测试:"
echo "   测试密码连接（如果需要密码）:"
read -s -p "输入服务器密码: " server_password
echo ""
if [ -n "$server_password" ]; then
    sshpass -p "$server_password" ssh -o ConnectTimeout=5 root@47.242.48.154 "echo '✅ 密码连接测试成功'" 2>&1
else
    echo "   跳过密码测试"
fi

echo ""
echo "4. 网络连通性测试:"
ping -c 2 47.242.48.154 2>/dev/null && echo "   ✅ 网络连通正常" || echo "   ❌ 网络连通失败"

echo ""
echo "=== 诊断建议 ==="
echo ""
echo "如果SSH密钥认证失败，建议:"
echo "1. 检查服务器SSH服务配置和权限"
echo "2. 重启SSH服务"
echo "3. 使用密码认证作为临时方案"
echo "4. 重新生成密钥对"
echo ""
echo "今晚最低目标: 建立可用的SSH自动化连接（密钥或密码）"