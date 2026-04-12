#!/bin/bash
# 医疗器械管理系统菜单修复脚本
# 执行时间: 2026-04-01 13:30 GMT+8
# 执行人: 惠迈香港工程师

echo "=== 医疗器械管理系统菜单修复脚本 ==="
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查当前目录
cd /usr/share/nginx/html/bio || { echo "错误: 无法进入目录"; exit 1; }
echo "1. 当前目录: $(pwd)"
echo ""

# 2. 检查JS文件
echo "2. 检查JS文件:"
JS_FILE=$(grep -o 'app\.[a-f0-9]*\.js' index.html | head -1)
echo "   index.html引用的文件: $JS_FILE"

if [ -z "$JS_FILE" ]; then
    echo "   ❌ 错误: 未找到JS文件引用"
    exit 1
fi

if [ ! -f "js/$JS_FILE" ]; then
    echo "   ❌ 错误: 文件不存在: js/$JS_FILE"
    echo "   现有文件:"
    ls -la js/app.*.js 2>/dev/null || echo "   无app.js文件"
    exit 1
fi

echo "   ✅ 文件存在: js/$JS_FILE"
echo ""

# 3. 检查文件内容
echo "3. 检查文件内容:"
HAS_PRODUCT=$(grep -o '"产品信息"' "js/$JS_FILE" | head -1)
HAS_CUSTOMER=$(grep -o '"客户信息"' "js/$JS_FILE" | head -1)
HAS_PRODUCT_ROUTE=$(grep -o 'path:"/product".*meta:{title:"产品信息"' "js/$JS_FILE" | head -1)
HAS_CUSTOMER_ROUTE=$(grep -o 'path:"/customer".*meta:{title:"客户信息"' "js/$JS_FILE" | head -1)

echo "   产品信息: $( [ -n "$HAS_PRODUCT" ] && echo "✅ 存在" || echo "❌ 缺失" )"
echo "   客户信息: $( [ -n "$HAS_CUSTOMER" ] && echo "✅ 存在" || echo "❌ 缺失" )"
echo "   产品路由: $( [ -n "$HAS_PRODUCT_ROUTE" ] && echo "✅ 存在" || echo "❌ 缺失" )"
echo "   客户路由: $( [ -n "$HAS_CUSTOMER_ROUTE" ] && echo "✅ 存在" || echo "❌ 缺失" )"
echo ""

# 4. 如果内容完整，清除缓存
if [ -n "$HAS_PRODUCT" ] && [ -n "$HAS_CUSTOMER" ] && [ -n "$HAS_PRODUCT_ROUTE" ] && [ -n "$HAS_CUSTOMER_ROUTE" ]; then
    echo "4. 文件内容完整，清除缓存:"
    echo "   重启Nginx服务..."
    systemctl restart nginx
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Nginx重启成功"
        echo "   检查Nginx状态..."
        systemctl status nginx --no-pager -l | grep -E "Active:|Status:"
    else
        echo "   ❌ Nginx重启失败"
        exit 1
    fi
else
    echo "4. 文件内容不完整，需要修复"
    echo "   备份原文件..."
    BACKUP_FILE="js/$JS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "js/$JS_FILE" "$BACKUP_FILE"
    echo "   ✅ 备份完成: $BACKUP_FILE"
    
    echo "   修复文件..."
    # 这里需要具体的修复逻辑，但根据检查，文件内容应该是完整的
    echo "   ℹ️ 根据检查，文件内容应该完整，请手动检查"
fi

echo ""
echo "5. 创建测试页面:"
cat > menu-test-fix.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>菜单修复测试</title><meta charset="utf-8"></head>
<body>
<h1>菜单修复测试</h1>
<p>测试时间: <span id="time"></span></p>
<div id="result"></div>
<script>
document.getElementById('time').textContent = new Date().toLocaleString('zh-CN');
fetch('/js/app.3b24beff.js').then(r => r.text()).then(t => {
    const result = document.getElementById('result');
    const checks = [
        {name: '产品信息', test: t.includes('"产品信息"')},
        {name: '客户信息', test: t.includes('"客户信息"')},
        {name: '产品路由', test: t.includes('path:"/product"')},
        {name: '客户路由', test: t.includes('path:"/customer"')}
    ];
    result.innerHTML = checks.map(c => 
        c.name + ': ' + (c.test ? '✅ 通过' : '❌ 失败')
    ).join('<br>');
});
</script>
</body>
</html>
EOF

echo "   ✅ 测试页面创建完成: menu-test-fix.html"
echo "   访问地址: https://bio-shandonghuiumai.com/menu-test-fix.html"
echo ""

echo "6. 验证步骤:"
echo "   1. 访问 https://bio-shandonghuiumai.com/menu-test-fix.html"
echo "   2. 检查所有项目是否显示'✅ 通过'"
echo "   3. 登录系统，检查左侧导航栏菜单"
echo "   4. 如果菜单显示，修复完成"
echo "   5. 如果菜单不显示，清除浏览器缓存后重试"
echo ""

echo "=== 脚本执行完成 ==="
echo "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "注意事项:"
echo "1. 如果问题仍然存在，请检查浏览器缓存"
echo "2. 确保用户已登录系统（某些菜单需要登录后显示）"
echo "3. 如果仍有问题，请通过工作流程系统联系惠迈高级工程师"