-- SSH自动化测试脚本
-- 使用方法：在Termius中打开后，运行此脚本

tell application "Termius"
	activate
	delay 1
	
	display dialog "SSH自动化测试开始" & return & return & "请确保：" & return & "1. Termius已打开" & return & "2. 有可用的SSH会话" & return & "3. 网络连接正常" buttons {"取消", "开始测试"} default button 2
	
	if button returned of result is "开始测试" then
		try
			-- 获取当前会话
			tell current session
				-- 测试1：简单命令
				write text "echo '=== Apple Script自动化测试开始 ==='"
				delay 1
				
				-- 测试2：检查香港服务器连接
				write text "ping -c 2 47.242.48.154 || echo '无法ping通香港服务器'"
				delay 2
				
				-- 测试3：尝试SSH连接（需要手动输入密码）
				write text "echo '尝试SSH连接香港服务器...'"
				write text "ssh -v -i ~/.ssh/cloud_sync_2h root@47.242.48.154 'echo 连接测试'"
				delay 3
				
				-- 测试4：本地SSH配置检查
				write text "echo '检查本地SSH配置...'"
				write text "cat ~/.ssh/config-cloud 2>/dev/null || echo '无config-cloud文件'"
				delay 1
				
				write text "echo '=== 测试完成 ==='"
			end tell
			
			display dialog "✅ 自动化测试命令已发送" & return & return & "请查看Termius窗口中的输出结果" buttons {"确定"} default button 1
			
		on error errMsg
			display dialog "⚠️ 自动化测试出错：" & return & errMsg buttons {"确定"} default button 1
		end try
	end if
end tell