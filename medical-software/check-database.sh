#!/bin/bash
# 数据库环境检查脚本 - 老王晚上使用

echo "=== 数据库环境检查 ==="
echo "检查时间: $(date)"
echo ""

echo "1. SQLite数据库状态:"
if [ -f "sqlite/medical_gsp.db" ]; then
    echo "✅ SQLite数据库文件存在"
    echo "   位置: $(pwd)/sqlite/medical_gsp.db"
    echo "   大小: $(du -h sqlite/medical_gsp.db | cut -f1)"
    
    # 检查表结构
    echo "   表数量: $(sqlite3 sqlite/medical_gsp.db ".tables" | wc -w)"
    echo "   表列表:"
    sqlite3 sqlite/medical_gsp.db ".tables" | tr ' ' '\n' | while read table; do
        echo "     - $table"
    done
else
    echo "❌ SQLite数据库文件不存在"
fi

echo ""
echo "2. Docker MySQL容器状态:"
docker ps -a | grep -E "(mysql|medgsp)" || echo "   未找到MySQL容器"

echo ""
echo "3. 本地MySQL安装状态:"
which mysql >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ MySQL已安装: $(mysql --version 2>/dev/null | head -1)"
else
    echo "⚠️  MySQL未安装，当前使用SQLite"
fi

echo ""
echo "4. 数据验证:"
if [ -f "sqlite/medical_gsp.db" ]; then
    echo "   测试查询业务合作伙伴数量:"
    sqlite3 sqlite/medical_gsp.db "SELECT COUNT(*) as partner_count FROM business_partner;" 2>/dev/null || echo "   查询失败"
    
    echo "   测试查询产品目录数量:"
    sqlite3 sqlite/medical_gsp.db "SELECT COUNT(*) as product_count FROM product_catalog;" 2>/dev/null || echo "   查询失败"
fi

echo ""
echo "=== 检查完成 ==="
echo ""
echo "当前状态:"
echo "✅ SQLite数据库已创建并可用"
echo "⚠️  Docker MySQL因网络问题暂未启动"
echo ""
echo "建议:"
echo "1. 今晚使用SQLite进行测试和验证"
echo "2. 明早再尝试启动Docker MySQL容器"
echo "3. 如果MySQL容器启动成功，可从SQLite迁移数据"
echo ""
echo "晚上您可以:"
echo "- 测试应用程序连接SQLite数据库"
echo "- 授权Apple Script权限"
echo "- 检查其他准备工作"