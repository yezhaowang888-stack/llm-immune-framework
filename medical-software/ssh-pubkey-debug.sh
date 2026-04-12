#!/bin/bash
# SSH公钥认证针对性诊断

echo "=== SSH公钥认证针对性诊断 ==="
echo "时间: $(date)"
echo ""

echo "1. 分析关键问题："
echo "   SSH日志中没有公钥认证失败记录"
echo "   这意味着："
echo "   - 客户端没有发送公钥认证请求"
echo "   - 或者公钥在更早阶段被拒绝"
echo "   - 或者authorized_keys文件格式问题"

echo ""
echo "2. 常见authorized_keys格式问题："
echo "   2.1 换行符问题：公钥被截断"
echo "   2.2 空格问题：行首或行尾有空格"
echo "   2.3 注释问题：#号注释了公钥"
echo "   2.4 格式问题：不是有效的OpenSSH公钥格式"

echo ""
echo "3. 验证authorized_keys格式："
echo "   理想格式："
echo "   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ...== comment"
echo "   一行，无换行，无多余空格"

echo ""
echo "4. 测试从本地连接（收集更多信息）："
echo "   开始详细测试..."
ssh -vvv -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=10 root@47.242.48.154 "exit" 2>&1 | tee /tmp/ssh_pubkey_debug.log | grep -B5 -A5 "publickey\|authenticat"

echo ""
echo "5. 分析可能的原因和解决方案："
echo "   5.1 如果客户端没有发送公钥："
echo "       - 检查SSH配置：~/.ssh/config"
echo "       - 检查客户端版本：ssh -V"
echo "       - 强制使用公钥：ssh -o PreferredAuthentications=publickey"

echo "   5.2 如果公钥格式问题："
echo "       - 重新生成公钥：ssh-keygen -y -f ~/.ssh/cloud_sync_2h"
echo "       - 重新创建authorized_keys文件"
echo "       - 确保一行一个公钥，无换行"

echo "   5.3 如果权限问题："
echo "       - .ssh目录必须700"
echo "       - authorized_keys必须600"
echo "       - 用户home目录不能有写权限给其他组"

echo ""
echo "6. 立即行动建议："
echo "   1. 小迈检查authorized_keys文件内容和格式"
echo "   2. 小迈测试从服务器到自身的公钥认证"
echo "   3. 根据结果采取相应修复措施"
echo "   4. 我们从本地验证修复结果"

echo ""
echo "=== 关键检查点 ==="
echo "✅ authorized_keys文件格式"
echo "✅ .ssh目录权限"
echo "✅ SSH客户端配置"
echo "✅ 公钥认证流程"