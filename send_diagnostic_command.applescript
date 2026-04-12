tell application "Termius"
    activate
    delay 1
end tell

tell application "System Events"
    tell process "Termius"
        -- 发送诊断指令
        keystroke "【紧急诊断】香港工程师小迈请立即执行："
        keystroke return
        delay 0.3
        
        keystroke "1. 检查app.js菜单代码位置："
        keystroke return
        delay 0.3
        keystroke "grep -n '客户信息' /usr/share/nginx/html/bio/js/app.ae2715d5.js | head -3"
        keystroke return
        delay 0.3
        
        keystroke "2. 检查文件加载："
        keystroke return
        delay 0.3
        keystroke "curl -I http://localhost/js/app.ae2715d5.js"
        keystroke return
        delay 0.3
        
        keystroke "3. 检查权限控制代码："
        keystroke return
        delay 0.3
        keystroke "grep -n 'permission\\|auth\\|showMenu' /usr/share/nginx/html/bio/js/app.ae2715d5.js | head -5"
        keystroke return
        delay 0.3
        
        keystroke "4. 回复检查结果"
        keystroke return
    end tell
end tell