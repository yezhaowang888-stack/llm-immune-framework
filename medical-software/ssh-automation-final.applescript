-- 最终SSH自动化脚本
-- 支持密钥认证和密码认证两种方式

tell application "Termius"
	activate
	delay 1
	
	-- 选择认证方式
	set authMethod to button returned of (display dialog "选择SSH认证方式：" & return & return & "1. 密钥认证（推荐）" & return & "2. 密码认证（备用）" buttons {"密钥认证", "密码认证", "取消"} default button 1)
	
	if authMethod is "密钥认证" then
		-- 密钥认证流程
		try
			tell current session
				write text "echo '=== SSH密钥认证测试 ==='"
				write text "echo '测试时间: '$(date)"
				write text "ssh -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=5 root@47.242.48.154 'echo \"✅ 密钥认证成功\"; hostname; date'"
				delay 3
				write text "echo '=== 测试完成 ==='"
			end tell
			
			display dialog "✅ 密钥认证测试命令已发送" & return & return & "请查看Termius窗口中的输出" buttons {"确定"} default button 1
			
		on error errMsg
			display dialog "⚠️ 密钥认证测试失败" & return & return & "错误: " & errMsg & return & return & "建议切换到密码认证" buttons {"切换到密码认证", "取消"} default button 1
			if button returned of result is "切换到密码认证" then
				-- 切换到密码认证
				tell current session
					write text "echo '切换到密码认证...'"
					write text "read -s -p '输入密码: ' password && echo"
					write text "sshpass -p $password ssh root@47.242.48.154 'echo \"✅ 密码认证成功\"'"
				end tell
			end if
		end try
		
	else if authMethod is "密码认证" then
		-- 密码认证流程
		tell current session
			write text "echo '=== SSH密码认证测试 ==='"
			write text "echo '测试时间: '$(date)"
			write text "echo '注意：需要输入密码'"
			write text "ssh root@47.242.48.154 'echo \"✅ 密码认证成功\"; hostname; date'"
		end tell
		
		display dialog "✅ 密码认证测试命令已发送" & return & return & "请在Termius中输入密码" buttons {"确定"} default button 1
	end if
	
end tell

-- 自动化任务示例
set runExample to button returned of (display dialog "是否运行自动化任务示例？" & return & return & "示例：检查系统状态、备份数据等" buttons {"运行示例", "跳过"} default button 1)

if runExample is "运行示例" then
	tell application "Termius"
		tell current session
			-- 示例任务1：检查系统状态
			write text "echo '=== 自动化任务示例 ==='"
			write text "ssh root@47.242.48.154 'echo \"1. 系统负载:\"; uptime; echo \"2. 磁盘使用:\"; df -h /; echo \"3. 内存使用:\"; free -h'"
			delay 2
			
			-- 示例任务2：检查医疗器械系统
			write text "ssh root@47.242.48.154 'echo \"4. 医疗器械系统状态:\"; ls -la /opt/med-gsp-system/ 2>/dev/null | head -5 || echo \"系统目录不存在\"'"
			delay 2
			
			-- 示例任务3：检查Docker服务器
			write text "ssh root@8.217.249.184 'echo \"5. Docker服务器状态:\"; docker ps 2>/dev/null | head -3 || echo \"无Docker容器\"'"
			
			write text "echo '=== 示例任务完成 ==='"
		end tell
		
		display dialog "✅ 自动化任务示例已运行" & return & return & "请查看Termius中的输出结果" buttons {"确定"} default button 1
	end tell
end if