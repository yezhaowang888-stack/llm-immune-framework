#!/bin/bash
# Apple Script权限测试脚本

echo "=== Apple Script权限测试 ==="
echo "测试时间: $(date)"
echo ""

# 测试1：基本Apple Script功能
echo "1. 测试Termius基本控制:"
osascript <<EOF
tell application "Termius"
    activate
    delay 1
    set windowNames to name of every window
    if windowNames is not {} then
        return "✅ Termius窗口控制成功: " & (count of windowNames) & "个窗口"
    else
        return "⚠️  Termius无窗口，但应用可控制"
    end if
end tell
EOF

echo ""
echo "2. 测试SSH自动化准备:"
echo "   检查SSH密钥配置..."
if [ -f ~/.ssh/cloud_sync_2h ]; then
    echo "   ✅ SSH私钥存在: ~/.ssh/cloud_sync_2h"
    echo "   密钥权限: $(ls -la ~/.ssh/cloud_sync_2h | awk '{print $1}')"
else
    echo "   ❌ SSH私钥不存在，需要重新生成"
fi

echo ""
echo "3. 测试Apple Script执行SSH命令:"
echo "   准备测试脚本..."
cat > /tmp/test_ssh.applescript <<'TESTSCRIPT'
tell application "Termius"
    activate
    delay 1
    
    -- 尝试获取当前会话
    try
        tell current session
            -- 先测试简单命令
            write text "echo 'Apple Script SSH测试 - 时间: '$(date)"
            delay 2
            return "✅ Apple Script SSH测试准备就绪"
        end tell
    on error errMsg
        return "⚠️  Apple Script错误: " & errMsg
    end try
end tell
TESTSCRIPT

echo "   测试脚本已保存: /tmp/test_ssh.applescript"
echo "   您可以在Termius中手动测试此脚本"

echo ""
echo "=== 测试完成 ==="
echo ""
echo "建议下一步:"
echo "1. 如果基本控制成功 → 测试SSH连接香港服务器"
echo "2. 如果SSH密钥缺失 → 重新生成密钥对"
echo "3. 如果权限有问题 → 重新检查系统权限设置"
echo ""
echo "请将测试结果反馈给我"