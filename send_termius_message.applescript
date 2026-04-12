tell application "Termius"
    activate
    delay 1
    
    -- 尝试获取当前窗口或会话
    try
        tell application "System Events"
            tell process "Termius"
                -- 检查是否有打开的主窗口
                if exists window 1 then
                    -- 尝试发送消息（假设在聊天界面）
                    keystroke "【紧急指令 - 统一命名与任务下达】"
                    keystroke return
                    delay 0.5
                    keystroke "致：香港工程师小迈"
                    keystroke return
                    delay 0.5
                    keystroke "我是惠迈高级工程师（协调员），老王已授权我通过Termius直接联系你。"
                    keystroke return
                    delay 0.5
                    keystroke "请立即回复身份确认和任务接收。"
                    keystroke return
                    delay 0.5
                    keystroke "详细指令见工作空间文件。"
                    keystroke return
                    delay 0.5
                    keystroke "回复截止：10:00前"
                    keystroke return
                    
                    return "消息已发送到Termius当前窗口"
                else
                    return "Termius已打开但无活动窗口，需要手动操作"
                end if
            end tell
        end tell
    on error errMsg
        return "发送失败: " & errMsg
    end try
end tell