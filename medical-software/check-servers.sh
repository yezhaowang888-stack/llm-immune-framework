#!/bin/bash
# 双服务器验证脚本

echo "=== 服务器架构验证 ==="
echo "检查时间: $(date)"
echo ""

echo "1. 香港服务器 (47.242.48.154):"
echo "   测试连接..."
timeout 5 ssh -o ConnectTimeout=3 root@47.242.48.154 "echo '✅ 香港服务器连接正常'; hostname; ip addr show | grep inet | head -3" 2>/dev/null || echo "   ❌ 香港服务器连接失败"

echo ""
echo "2. 日本服务器 (8.217.249.184):"
echo "   测试连接..."
timeout 5 ssh -o ConnectTimeout=3 root@8.217.249.184 "echo '✅ 日本服务器连接正常'; hostname; ip addr show | grep inet | head -3" 2>/dev/null || echo "   ❌ 日本服务器连接失败"

echo ""
echo "3. 医疗器械系统位置验证:"
echo "   香港服务器检查:"
ssh root@47.242.48.154 "if [ -d /opt/med-gsp-system ]; then echo '   ✅ 香港有系统目录'; ls -la /opt/med-gsp-system/ | head -5; else echo '   ❌ 香港无系统目录'; fi" 2>/dev/null || echo "   无法检查香港服务器"

echo "   日本服务器检查:"
ssh root@8.217.249.184 "if [ -d /opt/med-gsp-system ]; then echo '   ✅ 日本有系统目录'; ls -la /opt/med-gsp-system/ | head -5; else echo '   ❌ 日本无系统目录'; fi" 2>/dev/null || echo "   无法检查日本服务器"

echo ""
echo "4. 数据库服务验证:"
echo "   香港服务器数据库:"
ssh root@47.242.48.154 "docker ps | grep -E '(mysql|mariadb|postgres)' || echo '   未找到数据库容器'" 2>/dev/null || echo "   无法检查数据库"

echo "   日本服务器数据库:"
ssh root@8.217.249.184 "docker ps | grep -E '(mysql|mariadb|postgres)' || echo '   未找到数据库容器'" 2>/dev/null || echo "   无法检查数据库"

echo ""
echo "5. 网络连通性测试:"
echo "   香港→日本:"
ssh root@47.242.48.154 "ping -c 2 8.217.249.184 2>/dev/null && echo '   ✅ 香港可访问日本' || echo '   ❌ 香港无法访问日本'" 2>/dev/null || echo "   无法测试连通性"

echo "   日本→香港:"
ssh root@8.217.249.184 "ping -c 2 47.242.48.154 2>/dev/null && echo '   ✅ 日本可访问香港' || echo '   ❌ 日本无法访问香港'" 2>/dev/null || echo "   无法测试连通性"

echo ""
echo "=== 验证建议 ==="
echo ""
echo "请根据上述结果确认:"
echo "1. 哪个服务器是医疗器械系统的生产环境？"
echo "2. 两个服务器之间是否有数据同步？"
echo "3. 我们的备份和同步策略是否需要调整？"
echo ""
echo "重要：这个验证结果将影响我们所有的自动化架构设计"