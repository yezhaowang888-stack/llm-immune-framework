#!/bin/bash
# SSH密钥问题修复脚本

echo "=== SSH密钥问题诊断 ==="
echo "时间: $(date)"
echo ""

echo "1. 检查本地私钥:"
ls -la ~/.ssh/cloud_sync_2h
ssh-keygen -l -f ~/.ssh/cloud_sync_2h

echo ""
echo "2. 从私钥生成公钥:"
ssh-keygen -y -f ~/.ssh/cloud_sync_2h

echo ""
echo "3. 测试本地连接生产服务器:"
ssh -i ~/.ssh/cloud_sync_2h -v -o ConnectTimeout=5 root@47.242.48.154 "echo 测试" 2>&1 | grep -E "(debug1:|Authentication|failed|success)" | head -10

echo ""
echo "=== 解决方案 ==="
echo ""
echo "如果公钥不匹配，需要："
echo "1. 获取正确的公钥：ssh-keygen -y -f ~/.ssh/cloud_sync_2h"
echo "2. 将公钥添加到服务器的authorized_keys"
echo "3. 测试连接"
echo ""
echo "请将上述输出结果复制，特别是公钥内容"