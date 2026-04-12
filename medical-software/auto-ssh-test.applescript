-- 自动化SSH测试脚本
-- 等待SSH密钥问题解决后测试

tell application "Termius"
	activate
	delay 1
	
	display dialog "自动化SSH测试准备" & return & return & "测试步骤：" & return & "1. 激活Termius" & return & "2. 建立SSH连接" & return & "3. 发送测试命令" buttons {"取消", "开始测试"} default button 2
	
	if button returned of result is "开始测试" then
		-- 记录开始时间
		set startTime to current date
		
		try
			tell current session
				-- 步骤1：测试本地连接
				write text "echo '=== 自动化测试开始 ==='"
				write text "echo '时间: '$(date)"
				delay 1
				
				-- 步骤2：测试SSH密钥连接
				write text "echo '测试SSH密钥连接...'"
				write text "ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154 'echo 生产服务器连接测试'"
				delay 3
				
				-- 步骤3：测试简单命令
				write text "echo '测试Docker服务器连接...'"
				write text "ssh root@8.217.249.184 'docker ps 2>/dev/null || echo 无Docker容器'"
				delay 2
				
				-- 步骤4：测试医疗器械系统状态
				write text "echo '检查生产系统状态...'"
				write text "ssh root@47.242.48.154 'ls -la /opt/med-gsp-system/ | head -5'"
				delay 2
				
				write text "echo '=== 自动化测试完成 ==='"
			end tell
			
			-- 计算耗时
			set endTime to current date
			set timeDiff to endTime - startTime
			
			display dialog "✅ 自动化测试完成" & return & return & "测试命令已发送" & return & "耗时: " & (round (timeDiff)) & "秒" & return & return & "请查看Termius窗口中的输出" buttons {"确定"} default button 1
			
		on error errMsg
			display dialog "⚠️ 自动化测试失败" & return & return & "错误信息：" & return & errMsg buttons {"确定"} default button 1
		end try
	end if
end tell