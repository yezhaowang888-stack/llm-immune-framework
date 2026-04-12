#!/bin/bash

# 阿里云ECS连接脚本
# 需要填写实际连接信息

# === 需要修改的配置 ===
PUBLIC_IP="请填写公网IP"
USERNAME="root"  # 或 ubuntu、ecs-user 等
PASSWORD="请填写密码"
# 或者使用密钥文件
# KEY_FILE="/path/to/private-key.pem"

echo "尝试连接阿里云ECS: $PUBLIC_IP"

# 方法1: 使用密码连接
if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "请填写密码" ]; then
    echo "使用密码连接..."
    # 安装sshpass（如果未安装）
    if ! command -v sshpass &> /dev/null; then
        echo "需要安装sshpass: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
    
    # 测试连接
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USERNAME@$PUBLIC_IP" "uname -a && echo '连接成功!'"
    
# 方法2: 使用密钥文件连接
elif [ -n "$KEY_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "使用密钥文件连接..."
    chmod 600 "$KEY_FILE"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USERNAME@$PUBLIC_IP" "uname -a && echo '连接成功!'"
    
else
    echo "错误: 未配置有效的连接信息"
    echo ""
    echo "请从阿里云控制台获取:"
    echo "1. 公网IP地址"
    echo "2. 登录用户名 (如: root, ubuntu)"
    echo "3. 密码或密钥文件"
    echo ""
    echo "安全提示: 不要将密码硬编码在脚本中，建议临时使用后删除"
fi