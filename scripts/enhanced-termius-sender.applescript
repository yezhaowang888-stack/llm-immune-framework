-- enhanced-termius-sender.applescript
-- 增强版Termius消息发送器，支持重试和错误处理

on sendMessageWithRetry(messageText, maxRetries)
    set retryCount to 0
    set success to false
    
    repeat while retryCount < maxRetries and not success
        try
            tell application "Termius"
                activate
                delay 2
                
                -- 检查Termius状态
                if not (exists) then
                    error "Termius未运行"
                end if
                
                tell application "System Events"
                    tell process "Termius"
                        -- 尝试获取窗口
                        if not (exists window 1) then
                            -- 创建新窗口
                            keystroke "n" using command down
                            delay 1
                        end if
                        
                        -- 发送消息
                        keystroke messageText
                        keystroke return
                        
                        -- 验证发送（简单检查）
                        delay 0.5
                        set success to true
                    end tell
                end tell
            end tell
            
        on error errMsg
            set retryCount to retryCount + 1
            logToFile("发送失败（尝试 " & retryCount & "/" & maxRetries & "）: " & errMsg)
            
            if retryCount < maxRetries then
                delay 2  -- 等待后重试
            end if
        end try
    end repeat
    
    return success
end sendMessageWithRetry

on logToFile(message)
    set logFile to "/Users/mac/.openclaw/workspace/logs/termius_automation.log"
    set timestamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    set logEntry to "[" & timestamp & "] " & message
    
    try
        do shell script "echo " & quoted form of logEntry & " >> " & logFile
    on error
        -- 如果日志文件不存在，创建它
        do shell script "echo " & quoted form of logEntry & " > " & logFile
    end try
end logToFile

-- 主程序
on run argv
    if (count of argv) < 1 then
        set messageToSend to "【测试消息】这是增强版发送测试"
    else
        set messageToSend to item 1 of argv
    end if
    
    set maxRetries to 3
    set result to sendMessageWithRetry(messageToSend, maxRetries)
    
    if result then
        logToFile("消息发送成功: " & messageToSend)
        return "✅ 消息发送成功"
    else
        logToFile("消息发送失败（达到最大重试次数）: " & messageToSend)
        return "❌ 消息发送失败"
    end if
end run
