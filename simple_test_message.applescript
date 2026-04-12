tell application "Termius"
    activate
    delay 1
    -- 尝试直接发送到当前会话
    keystroke "TEST: Can you see this message?"
    keystroke return
end tell