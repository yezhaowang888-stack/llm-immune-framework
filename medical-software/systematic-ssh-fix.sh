#!/bin/bash
# SSH密钥系统化修复脚本

echo "=== SSH密钥系统化修复 ==="
echo "开始时间: $(date)"
echo ""

echo "1. 第一阶段：基础验证"
echo "   1.1 检查本地私钥:"
if [ ! -f ~/.ssh/cloud_sync_2h ]; then
    echo "   ❌ 本地私钥不存在"
    exit 1
else
    echo "   ✅ 本地私钥存在"
    echo "      大小: $(wc -c < ~/.ssh/cloud_sync_2h) 字节"
    echo "      权限: $(ls -la ~/.ssh/cloud_sync_2h | awk '{print $1}')"
fi

echo ""
echo "   1.2 测试详细连接（收集信息）:"
echo "       开始测试..."
DEBUG_OUTPUT=$(ssh -vvv -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=10 root@47.242.48.154 "exit" 2>&1)
echo "$DEBUG_OUTPUT" > /tmp/ssh_full_debug.log
echo "       详细日志已保存: /tmp/ssh_full_debug.log"

echo ""
echo "2. 第二阶段：问题分析"
echo "   2.1 分析认证流程:"
echo "$DEBUG_OUTPUT" | grep -E "(debug1:.*auth|Authentications|publickey|failed|success|error|denied)" | head -20

echo ""
echo "   2.2 常见问题检查清单:"
echo "       [ ] 1. 服务器authorized_keys文件权限"
echo "       [ ] 2. 服务器.ssh目录权限"
echo "       [ ] 3. 公钥格式是否正确"
echo "       [ ] 4. SSH服务配置"
echo "       [ ] 5. SELinux/AppArmor限制"
echo "       [ ] 6. 防火墙规则"
echo "       [ ] 7. 密钥类型兼容性"

echo ""
echo "3. 第三阶段：解决方案"
echo "   3.1 如果问题在服务器权限:"
echo "       需要小迈执行:"
echo "       chmod 700 ~/.ssh"
echo "       chmod 600 ~/.ssh/authorized_keys"
echo "       chmod 600 ~/.ssh/cloud_sync_2h"

echo ""
echo "   3.2 如果问题在公钥格式:"
echo "       需要重新生成公钥:"
echo "       ssh-keygen -y -f ~/.ssh/cloud_sync_2h > ~/.ssh/cloud_sync_2h.pub"
echo "       cat ~/.ssh/cloud_sync_2h.pub >> ~/.ssh/authorized_keys"

echo ""
echo "   3.3 如果问题在SSH配置:"
echo "       需要检查:"
echo "       /etc/ssh/sshd_config"
echo "       并重启服务: systemctl restart sshd"

echo ""
echo "   3.4 如果问题在SELinux:"
echo "       需要检查: getenforce, sestatus"
echo "       可能需要: setsebool -P ssh_keysign 1"

echo ""
echo "4. 第四阶段：验证测试"
echo "   验证步骤:"
echo "   1. 小迈修复问题"
echo "   2. 小迈测试本地连接: ssh -i ~/.ssh/cloud_sync_2h localhost"
echo "   3. 小迈测试远程连接: ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154"
echo "   4. 我们从本地测试连接"
echo "   5. 验证自动化脚本"

echo ""
echo "=== 执行计划 ==="
echo ""
echo "立即行动:"
echo "1. 小迈查看SSH日志，找到具体拒绝原因"
echo "2. 根据日志错误信息，执行相应修复"
echo "3. 测试修复结果"
echo "4. 我们从本地验证"
echo ""
echo "目标：今晚必须解决SSH密钥认证问题"