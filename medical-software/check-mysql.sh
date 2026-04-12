#!/bin/bash
# MySQL容器检查脚本 - 老王晚上使用

echo "=== MySQL容器状态检查 ==="
echo "检查时间: $(date)"

echo ""
echo "1. Docker服务状态:"
docker --version

echo ""
echo "2. 所有容器状态:"
docker ps -a

echo ""
echo "3. MySQL容器日志（最后20行）:"
docker logs medical-software-mysql-1 --tail 20 2>/dev/null || echo "MySQL容器尚未启动或名称不同"

echo ""
echo "4. 网络检查:"
docker network ls

echo ""
echo "5. 端口检查（3306）:"
lsof -i :3306 2>/dev/null || echo "端口3306未被占用或无法检查"

echo ""
echo "=== 检查完成 ==="
echo "如果MySQL容器运行正常，您应该看到："
echo "✅ medical-software-mysql-1 状态为 Up"
echo "✅ 端口3306监听中"
echo ""
echo "如果有问题，请截图或描述错误信息"
echo "我将根据问题提供解决方案"