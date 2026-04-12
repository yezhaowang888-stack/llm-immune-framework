#!/bin/bash
# SSH公钥修复验证脚本

echo "=== SSH公钥修复验证 ==="
echo "验证时间: $(date)"
echo ""

echo "1. 等待小迈修复后，从本地测试："
echo "   测试命令："
echo "   ssh -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=5 root@47.242.48.154 \"echo '✅ SSH公钥认证成功'\""

echo ""
echo "2. 验证成功标准："
echo "   ✅ 不要求输入密码"
echo "   ✅ 直接输出'✅ SSH公钥认证成功'"
echo "   ✅ 返回代码为0"

echo ""
echo "3. 如果成功，创建自动化验证："
cat > /Users/mac/.openclaw/workspace/medical-software/test-ssh-auto.sh << 'EOF'
#!/bin/bash
# SSH自动化测试脚本

echo "=== SSH自动化测试 ==="
echo "测试时间: $(date)"

SERVER="47.242.48.154"
KEY_FILE="$HOME/.ssh/cloud_sync_2h"

echo ""
echo "1. 测试基本连接："
ssh -i "$KEY_FILE" -o ConnectTimeout=5 root@"$SERVER" "echo '✅ 基本连接测试成功'; hostname; date"

echo ""
echo "2. 测试医疗器械系统："
ssh -i "$KEY_FILE" -o ConnectTimeout=5 root@"$SERVER" "echo '检查医疗器械系统...'; ls -la /opt/med-gsp-system/ 2>/dev/null | head -5 || echo '系统目录不存在'"

echo ""
echo "3. 测试Docker服务器："
ssh -o ConnectTimeout=5 root@8.217.249.184 "echo '检查Docker服务器...'; docker ps 2>/dev/null | head -3 || echo '无Docker容器'"

echo ""
echo "=== 测试完成 ==="
EOF

chmod +x /Users/mac/.openclaw/workspace/medical-software/test-ssh-auto.sh
echo "   自动化测试脚本已创建：test-ssh-auto.sh"

echo ""
echo "4. 创建Apple Script自动化："
cat > /Users/mac/.openclaw/workspace/medical-software/auto-ssh-key.applescript << 'EOF'
-- SSH密钥认证自动化脚本
tell application "Termius"
	activate
	delay 1
	
	display dialog "SSH密钥认证自动化" & return & return & "将使用公钥认证自动连接服务器" buttons {"开始", "取消"} default button 1
	
	if button returned of result is "开始" then
		try
			tell current session
				write text "echo '=== SSH密钥自动化开始 ==='"
				write text "echo '时间: '$(date)"
				write text "ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154 'echo \"✅ 自动化连接成功\"; hostname; date; pwd'"
				delay 3
				write text "echo '=== 自动化完成 ==='"
			end tell
			
			display dialog "✅ SSH密钥自动化命令已发送" & return & return & "请查看Termius窗口中的输出" buttons {"确定"} default button 1
			
		on error errMsg
			display dialog "⚠️ 自动化失败" & return & return & "错误: " & errMsg buttons {"确定"} default button 1
		end try
	end if
end tell
EOF
echo "   Apple Script自动化脚本已创建：auto-ssh-key.applescript"

echo ""
echo "5. 验证流程："
echo "   1. 小迈修复authorized_keys格式"
echo "   2. 我们从本地测试连接"
echo "   3. 运行自动化测试脚本"
echo "   4. 测试Apple Script自动化"
echo "   5. 确认SSH密钥认证完全正常"

echo ""
echo "=== 准备就绪 ==="
echo "等待小迈修复后，立即执行验证"