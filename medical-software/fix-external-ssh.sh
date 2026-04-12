#!/bin/bash
# SSH外部连接修复验证

echo "=== SSH外部连接修复验证 ==="
echo "验证时间: $(date)"
echo ""

echo "1. 问题分析："
echo "   ✅ 服务器本地公钥认证成功"
echo "   ❌ 外部连接公钥认证失败"
echo "   可能原因："
echo "   - SSH配置限制（AllowUsers/DenyUsers）"
echo "   - 连接数限制"
echo "   - 防火墙/安全组限制"
echo "   - 监听地址限制"

echo ""
echo "2. 修复后验证步骤："
echo "   2.1 小迈修复SSH配置"
echo "   2.2 小迈重启SSH服务"
echo "   2.3 小迈测试从服务器到外部IP"
echo "   2.4 我们从本地测试连接"

echo ""
echo "3. 验证命令："
echo "   从本地测试："
echo "   ssh -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=5 root@47.242.48.154 \"echo '✅ 外部连接成功'\""

echo ""
echo "4. 成功标准："
echo "   ✅ 不要求输入密码"
echo "   ✅ 直接输出'✅ 外部连接成功'"
echo "   ✅ 返回代码为0"

echo ""
echo "5. 如果成功，创建最终自动化："
cat > /Users/mac/.openclaw/workspace/medical-software/final-ssh-auto.sh << 'EOF'
#!/bin/bash
# SSH最终自动化脚本

echo "=== SSH最终自动化测试 ==="
echo "测试时间: $(date)"

SERVER="47.242.48.154"
KEY_FILE="$HOME/.ssh/cloud_sync_2h"

echo ""
echo "1. 测试基本自动化："
if ssh -i "$KEY_FILE" -o ConnectTimeout=5 -o BatchMode=yes root@"$SERVER" "echo '✅ SSH自动化基础测试成功'" 2>/dev/null; then
    echo "   ✅ SSH自动化基础测试通过"
else
    echo "   ❌ SSH自动化基础测试失败"
    exit 1
fi

echo ""
echo "2. 测试医疗器械系统访问："
ssh -i "$KEY_FILE" -o ConnectTimeout=5 root@"$SERVER" << 'REMOTE_CMD'
echo "=== 医疗器械系统状态 ==="
echo "1. 系统目录:"
ls -la /opt/med-gsp-system/ 2>/dev/null | head -5 || echo "   系统目录不存在"
echo ""
echo "2. 服务状态:"
systemctl status nginx 2>/dev/null | head -3 || echo "   Nginx未安装"
echo ""
echo "3. 数据库状态:"
docker ps | grep -E "(mysql|mariadb)" || echo "   无数据库容器"
REMOTE_CMD

echo ""
echo "3. 测试Docker服务器："
ssh -o ConnectTimeout=5 root@8.217.249.184 "echo 'Docker服务器状态:'; docker ps 2>/dev/null | head -3 || echo '无Docker容器'"

echo ""
echo "=== 自动化测试完成 ==="
EOF

chmod +x /Users/mac/.openclaw/workspace/medical-software/final-ssh-auto.sh
echo "   最终自动化脚本已创建：final-ssh-auto.sh"

echo ""
echo "6. 创建Apple Script最终自动化："
cat > /Users/mac/.openclaw/workspace/medical-software/final-auto-ssh.applescript << 'EOF'
-- SSH最终自动化脚本
tell application "Termius"
	activate
	delay 1
	
	set successMsg to "✅ SSH密钥认证自动化准备就绪"
	set failMsg to "⚠️ SSH自动化需要进一步配置"
	
	try
		tell current session
			write text "echo '=== SSH最终自动化测试 ==='"
			write text "echo '时间: '$(date)"
			write text "ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154 'echo \"🎉 SSH自动化成功\"; echo \"主机: \"$(hostname); echo \"时间: \"$(date)'"
			delay 3
			write text "echo '=== 测试完成 ==='"
		end tell
		
		display dialog successMsg & return & return & "SSH密钥认证自动化已配置完成" buttons {"运行完整测试", "完成"} default button 1
		
		if button returned of result is "运行完整测试" then
			tell current session
				write text "echo '=== 完整自动化测试 ==='"
				write text "cd /Users/mac/.openclaw/workspace/medical-software && ./final-ssh-auto.sh"
			end tell
			
			display dialog "✅ 完整自动化测试已启动" & return & return & "请查看Termius窗口中的输出" buttons {"确定"} default button 1
		end if
		
	on error errMsg
		display dialog failMsg & return & return & "错误: " & errMsg buttons {"确定"} default button 1
	end try
end tell
EOF
echo "   Apple Script最终自动化已创建：final-auto-ssh.applescript"

echo ""
echo "=== 准备验证 ==="
echo "等待小迈修复后，立即执行验证"