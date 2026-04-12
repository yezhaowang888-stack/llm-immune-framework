#!/bin/bash
# 密码认证SSH自动化脚本

echo "=== 密码认证SSH自动化 ==="
echo "时间: $(date)"
echo ""

# 检查sshpass是否安装
if ! command -v sshpass &> /dev/null; then
    echo "安装sshpass..."
    brew install sshpass 2>/dev/null || {
        echo "无法安装sshpass，使用expect备选方案"
        # 创建expect脚本
        cat > /tmp/ssh-expect.exp << 'EOF'
#!/usr/bin/expect
set timeout 10
set host "47.242.48.154"
set password "YourPassword123!"  # 需要替换为实际密码

spawn ssh root@$host
expect {
    "password:" {
        send "$password\r"
    }
    timeout {
        send_user "连接超时\n"
        exit 1
    }
}
expect {
    "# " {
        send "echo '✅ Expect自动化成功'\r"
        send "hostname\r"
        send "date\r"
        send "exit\r"
    }
}
expect eof
EOF
        chmod +x /tmp/ssh-expect.exp
        echo "Expect脚本已创建: /tmp/ssh-expect.exp"
    }
fi

echo ""
echo "1. 测试密码连接:"
read -s -p "输入服务器root密码: " SERVER_PASSWORD
echo ""

if [ -n "$SERVER_PASSWORD" ]; then
    # 使用sshpass测试
    sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=5 root@47.242.48.154 "echo '✅ 密码连接测试成功'; hostname; date" 2>&1
    
    # 保存密码到临时文件（仅用于自动化测试）
    if [ $? -eq 0 ]; then
        echo "$SERVER_PASSWORD" > /tmp/server_password.txt
        chmod 600 /tmp/server_password.txt
        echo "密码已保存到临时文件（仅测试用）"
    fi
else
    echo "未输入密码，跳过测试"
fi

echo ""
echo "2. 创建自动化脚本:"
cat > /Users/mac/.openclaw/workspace/medical-software/auto-ssh-password.sh << 'EOF'
#!/bin/bash
# 自动化SSH脚本（密码认证）

SERVER="47.242.48.154"
PASSWORD_FILE="/tmp/server_password.txt"

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "错误：密码文件不存在"
    echo "请先运行 password-ssh-automation.sh 设置密码"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")

# 执行命令
sshpass -p "$PASSWORD" ssh root@$SERVER "$@"
EOF

chmod +x /Users/mac/.openclaw/workspace/medical-software/auto-ssh-password.sh

echo "自动化脚本已创建: auto-ssh-password.sh"
echo "使用方法: ./auto-ssh-password.sh '命令'"

echo ""
echo "3. 测试自动化脚本:"
if [ -f "/tmp/server_password.txt" ]; then
    echo "测试简单命令:"
    /Users/mac/.openclaw/workspace/medical-software/auto-ssh-password.sh "echo '自动化测试成功'; pwd; ls -la /opt/med-gsp-system/ 2>/dev/null | head -3"
fi

echo ""
echo "=== 完成 ==="
echo "密码认证自动化已就绪"