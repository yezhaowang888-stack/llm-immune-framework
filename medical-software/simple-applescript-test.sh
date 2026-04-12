#!/bin/bash
# 简单Apple Script测试

echo "=== 简单Apple Script权限测试 ==="
echo ""

echo "1. 测试应用激活:"
osascript <<'EOF'
tell application "Termius"
    activate
    delay 0.5
    return "✅ Termius激活成功"
end tell
EOF

echo ""
echo "2. 测试获取应用信息:"
osascript <<'EOF'
tell application "Termius"
    get name
end tell
EOF

echo ""
echo "3. 测试简单窗口操作:"
osascript <<'EOF'
tell application "Termius"
    activate
    delay 1
    try
        set frontmost to true
        return "✅ 窗口置顶成功"
    on error
        return "⚠️  窗口置顶失败，但应用可控制"
    end try
end tell
EOF

echo ""
echo "=== 测试说明 ==="
echo "如果看到'Termius激活成功' → 基本权限正常"
echo "如果看到错误信息 → 需要重新检查权限"
echo ""
echo "请将上述测试的输出结果复制给我"