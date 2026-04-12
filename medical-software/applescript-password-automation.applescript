-- Apple Script密码认证自动化
-- 使用Termius进行SSH密码认证

tell application "Termius"
	activate
	delay 1
	
	display dialog "SSH密码认证自动化" & return & return & "将自动连接生产服务器并执行命令" buttons {"开始", "取消"} default button 1
	
	if button returned of result is "开始" then
		try
			tell current session
				-- 步骤1：连接服务器
				write text "echo '=== SSH密码认证自动化开始 ==='"
				write text "echo '时间: '$(date)"
				write text "ssh root@47.242.48.154"
				delay 3  -- 等待密码提示
				
				-- 注意：这里需要手动输入密码
				-- 密码输入后，继续执行命令
				
				write text "echo '✅ 连接成功'"
				write text "hostname"
				write text "date"
				write text "pwd"
				
				-- 步骤2：检查医疗器械系统
				write text "echo '检查医疗器械系统...'"
				write text "ls -la /opt/med-gsp-system/ 2>/dev/null | head -5 || echo '系统目录不存在'"
				
				-- 步骤3：检查Docker服务器
				write text "echo '检查Docker服务器...'"
				write text "ssh root@8.217.249.184 'docker ps 2>/dev/null | head -3 || echo 无Docker容器'"
				
				-- 步骤4：退出
				write text "exit"
				write text "echo '=== 自动化完成 ==='"
			end tell
			
			display dialog "✅ 自动化命令已发送" & return & return & "请在Termius中输入服务器密码" & return & "然后观察命令执行结果" buttons {"确定"} default button 1
			
		on error errMsg
			display dialog "⚠️ 自动化失败" & return & return & "错误: " & errMsg buttons {"确定"} default button 1
		end try
	end if
end tell

-- 菜单选择
set taskChoice to choose from list {"检查系统状态", "备份数据", "重启服务", "查看日志"} with prompt "选择自动化任务:" default items {"检查系统状态"}

if taskChoice is not false then
	set selectedTask to item 1 of taskChoice
	
	tell application "Termius"
		tell current session
			if selectedTask is "检查系统状态" then
				write text "echo '执行：检查系统状态'"
				write text "ssh root@47.242.48.154 'uptime; free -h; df -h /; docker ps 2>/dev/null | wc -l'"
				
			else if selectedTask is "备份数据" then
				write text "echo '执行：备份数据'"
				write text "ssh root@47.242.48.154 'cd /opt/med-gsp-system && tar -czf /tmp/backup_$(date +%Y%m%d_%H%M).tar.gz . && echo 备份完成'"
				
			else if selectedTask is "重启服务" then
				write text "echo '执行：重启服务'"
				write text "ssh root@47.242.48.154 'systemctl restart nginx 2>/dev/null || echo Nginx未安装; systemctl restart docker 2>/dev/null || echo Docker未安装'"
				
			else if selectedTask is "查看日志" then
				write text "echo '执行：查看日志'"
				write text "ssh root@47.242.48.154 'tail -20 /var/log/nginx/access.log 2>/dev/null || echo 无Nginx日志; docker logs --tail=10 mysql-medgsp 2>/dev/null || echo 无MySQL容器日志'"
			end if
		end tell
		
		display dialog "✅ 任务已发送: " & selectedTask buttons {"确定"} default button 1
	end tell
end if