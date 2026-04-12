#!/bin/bash
# 出入库智能体启动脚本

echo "=== 出入库智能体启动 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 检查Node.js版本
echo "1. 检查Node.js版本..."
node --version || { echo "❌ Node.js未安装"; exit 1; }
echo "✅ Node.js版本: $(node --version)"
echo ""

# 检查依赖
echo "2. 检查依赖..."
if [ ! -d "node_modules" ]; then
    echo "⚠️ node_modules目录不存在，正在安装依赖..."
    npm install --cache /tmp/npm-cache
else
    echo "✅ 依赖已安装"
fi
echo ""

# 检查环境变量
echo "3. 检查环境变量..."
if [ ! -f ".env" ]; then
    echo "⚠️ .env文件不存在，正在创建示例配置..."
    cp .env.example .env
    echo "📝 请编辑 .env 文件，设置数据库密码"
    echo "   数据库密码需要从MySQL容器配置获取"
    echo "   当前配置使用示例数据模式"
fi
echo ""

# 启动服务器
echo "4. 启动服务器..."
echo "🚀 出入库智能体正在启动..."
echo "📡 访问地址: http://localhost:3000"
echo "🔍 健康检查: http://localhost:3000/health"
echo "📊 查询界面: http://localhost:3000/query.html"
echo ""

# 设置环境变量（如果没有密码，使用示例模式）
if [ -z "$DB_PASSWORD" ] && [ ! -f ".env" ]; then
    export NODE_ENV=development
    echo "⚠️ 使用示例数据模式（无数据库连接）"
    echo "   要连接真实数据库，请设置DB_PASSWORD环境变量"
fi

# 启动服务器
node server.js