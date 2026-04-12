#!/bin/bash
# SSH密钥深度诊断脚本

echo "=== SSH密钥深度诊断 ==="
echo "诊断时间: $(date)"
echo ""

echo "1. 本地环境全面检查:"
echo "   1.1 私钥文件:"
ls -la ~/.ssh/cloud_sync_2h
echo "   1.2 私钥指纹:"
ssh-keygen -l -f ~/.ssh/cloud_sync_2h
echo "   1.3 私钥类型:"
ssh-keygen -t -f ~/.ssh/cloud_sync_2h 2>/dev/null || echo "无法确定类型"

echo ""
echo "2. 从私钥生成公钥（验证格式）:"
LOCAL_PUBKEY=$(ssh-keygen -y -f ~/.ssh/cloud_sync_2h)
echo "   生成的公钥:"
echo "$LOCAL_PUBKEY"
echo "   公钥长度: $(echo "$LOCAL_PUBKEY" | wc -c) 字符"

echo ""
echo "3. 详细连接测试:"
echo "   开始详细测试（可能较慢）..."
ssh -vvv -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=10 root@47.242.48.154 "exit" 2>&1 | tee /tmp/ssh_debug.log | grep -E "(debug1:.*auth|Authentications|publickey|failed|success|error)" | head -30

echo ""
echo "4. 分析可能的问题:"
echo "   4.1 检查日志文件: /tmp/ssh_debug.log"
echo "   4.2 常见问题:"
echo "       - 公钥格式不正确"
echo "       - authorized_keys权限问题"
echo "       - SSH服务配置问题"
echo "       - 密钥类型不匹配"
echo "       - SELinux/AppArmor限制"

echo ""
echo "5. 备选测试方案:"
echo "   5.1 测试不同认证方式:"
ssh -o PreferredAuthentications=publickey -i ~/.ssh/cloud_sync_2h root@47.242.48.154 "echo 测试" 2>&1 | grep -i "denied\|failed\|success"
echo "   5.2 测试无密钥连接:"
ssh -o PasswordAuthentication=no root@47.242.48.154 "echo 测试" 2>&1 | grep -i "denied\|failed\|success"

echo ""
echo "=== 诊断建议 ==="
echo ""
echo "根据上述输出，可能需要:"
echo "1. 检查服务器SSH日志: /var/log/secure 或 journalctl -u sshd"
echo "2. 重新生成密钥对: ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud_sync_new"
echo "3. 检查服务器SSH配置: /etc/ssh/sshd_config"
echo "4. 重启SSH服务: systemctl restart sshd"
echo "5. 检查SELinux状态: getenforce, sestatus"