#!/bin/bash
# 简单SSH测试脚本

echo "=== 简单SSH测试 ==="
echo "测试时间: $(date)"
echo ""

echo "1. 测试SSH连接："
echo "   命令：ssh -i ~/.ssh/cloud_sync_2h -o ConnectTimeout=3 root@47.242.48.154 \"echo '测试'\""
echo ""

echo "2. 如果成功，输出："
echo "   测试"
echo "   不要求密码"
echo ""

echo "3. 如果失败，输出："
echo "   Permission denied"
echo "   要求输入密码"
echo ""

echo "4. 当前状态：等待小迈完成修复"
echo "   小迈需要执行："
echo "   1. 重新创建authorized_keys文件"
echo "   2. 验证文件格式"
echo "   3. 设置权限"
echo "   4. 重启SSH服务"
echo "   5. 测试修复结果"
echo ""

echo "=== 准备测试 ==="
echo "等待小迈完成修复后，立即执行测试"