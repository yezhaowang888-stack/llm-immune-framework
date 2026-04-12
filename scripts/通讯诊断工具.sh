#!/bin/bash
# 智能体通讯诊断工具

echo "=== 智能体通讯诊断工具 ==="
echo "诊断时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查本地OpenClaw状态
echo "1. 本地OpenClaw状态检查"
echo "----------------------"
openclaw status 2>&1 | grep -E "(Gateway|配对|pairing|error)" || echo "状态检查失败"

echo ""

# 2. 检查网关配置
echo "2. 网关配置检查"
echo "----------------"
CONFIG_FILE="/Users/mac/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "配置文件: $CONFIG_FILE"
    grep -E "(gateway|pairing|bind|port)" "$CONFIG_FILE" | head -10
else
    echo "❌ 配置文件不存在"
fi

echo ""

# 3. 检查会话状态
echo "3. 会话状态检查"
echo "----------------"
sessions_list 2>&1 | grep -E "(count|session|agent)" || echo "会话检查失败"

echo ""

# 4. 检查工作区文件同步
echo "4. 工作区文件检查"
echo "------------------"
WORKSPACE="/Users/mac/.openclaw/workspace"
echo "工作区路径: $WORKSPACE"
ls -la "$WORKSPACE/" | grep -E "(TO小迈|TASK|紧急)" | head -5

echo ""

# 5. 检查通讯测试文件
echo "5. 通讯测试文件状态"
echo "-------------------"
TEST_FILE="$WORKSPACE/TO小迈-云-紧急任务.md"
if [ -f "$TEST_FILE" ]; then
    echo "✅ 测试文件存在: $TEST_FILE"
    echo "文件大小: $(wc -l < "$TEST_FILE") 行"
    echo "最后修改: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$TEST_FILE")"
    echo ""
    echo "最后5行内容:"
    tail -5 "$TEST_FILE"
else
    echo "❌ 测试文件不存在"
fi

echo ""

# 6. 建议修复步骤
echo "6. 建议修复步骤"
echo "----------------"
cat << EOF
建议执行顺序:
1. 检查阿里云服务器OpenClaw状态 (SSH)
2. 比较两地openclaw.json配置
3. 检查网关端口和绑定设置
4. 尝试重新启动网关服务
5. 测试简单消息发送
6. 建立备用通讯渠道

关键配置检查:
- gateway.bind 设置 (应为可访问地址)
- gateway.port 一致性
- 认证token配置
- 网络防火墙设置
EOF

echo ""
echo "=== 诊断完成 ==="
echo "下一步: 请执行阿里云端的相同诊断"