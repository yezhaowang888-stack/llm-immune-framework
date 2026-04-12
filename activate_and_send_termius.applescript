tell application "Termius"
    activate
    delay 2
    
    -- 尝试创建新窗口或会话
    try
        -- 发送Command+N创建新窗口
        tell application "System Events"
            keystroke "n" using command down
            delay 1
            
            -- 输入消息内容
            keystroke "【紧急询问 - 昨天工作情况】"
            keystroke return
            delay 0.5
            keystroke "致：香港工程师小迈"
            keystroke return
            delay 0.5
            keystroke "我是惠迈高级工程师，需要立即了解昨天（2026-04-04）的工作情况。"
            keystroke return
            delay 0.5
            keystroke "请回复以下问题："
            keystroke return
            delay 0.5
            keystroke "1. SSH公钥问题是否已解决？"
            keystroke return
            delay 0.5
            keystroke "2. MySQL容器是否已部署？"
            keystroke return
            delay 0.5
            keystroke "3. 页面问题是否已修复？"
            keystroke return
            delay 0.5
            keystroke "4. 自动化通道是否建立？"
            keystroke return
            delay 0.5
            keystroke "请13:30前回复详细情况。"
            keystroke return
            delay 0.5
            keystroke "详细询问内容见工作空间文件。"
            keystroke return
        end tell
        
        return "消息已发送到Termius新窗口"
    on error errMsg
        return "发送失败: " & errMsg
    end try
end tell