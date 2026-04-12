tell application "Termius"
    activate
    delay 2
    
    tell application "System Events"
        tell process "Termius"
            -- 尝试发送测试消息
            keystroke "【测试】来自惠迈高级工程师的自动消息测试"
            keystroke return
            delay 0.5
            keystroke "时间: $(date '+%H:%M')"
            keystroke return
            delay 0.5
            keystroke "权限测试: 成功"
            keystroke return
        end tell
    end tell
end tell