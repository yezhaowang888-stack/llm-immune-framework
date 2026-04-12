#!/bin/bash

# 阿里云云服务器状态检查脚本
# 需要在阿里云控制台登录后执行

echo "=== 阿里云云服务器状态检查 ==="
echo "检查时间: $(date)"
echo ""

# 假设的服务器信息（需要根据实际情况修改）
SERVER_IP="www.bio-shandonghuiumai.com"
ALIYUN_REGION="cn-shanghai"  # 假设是华东2（上海）

echo "1. 服务器基本信息:"
echo "   - 域名: $SERVER_IP"
echo "   - 预计地区: $ALIYUN_REGION"
echo ""

echo "2. 需要手动检查的项目:"
echo "   a) ECS实例状态 (运行中/已停止)"
echo "   b) 公网IP地址"
echo "   c) 安全组规则 (确保OpenClaw端口开放)"
echo "   d) 系统负载和资源使用情况"
echo ""

echo "3. OpenClaw相关检查:"
echo "   - OpenClaw服务是否运行"
echo "   - 网关状态"
echo "   - 小迈-云会话状态"
echo "   - 任务执行日志"
echo ""

echo "4. 昨天任务进展检查:"
echo "   - 查看小迈-云的工作目录"
echo "   - 检查任务输出文件"
echo "   - 查看OpenClaw日志"
echo ""

echo "=== 操作步骤 ==="
echo "1. 登录阿里云控制台: https://account.aliyun.com"
echo "2. 进入ECS控制台"
echo "3. 找到对应的ECS实例"
echo "4. 查看实例状态和监控信息"
echo "5. 通过Web SSH或远程连接进入服务器"
echo "6. 运行: openclaw status"
echo "7. 检查相关日志文件"