const express = require('express');
const cors = require('cors');
require('dotenv').config();

// 导入路由
const inventoryRoutes = require('./routes/inventory');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件服务
app.use(express.static('public'));

// 路由
app.use('/api/inventory', inventoryRoutes);

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'inventory-agent',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// 首页
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>出入库智能体</title>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        .card { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .endpoint { background: #e8f4fd; padding: 10px; border-left: 4px solid #1890ff; margin: 10px 0; }
        code { background: #eee; padding: 2px 4px; border-radius: 3px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚚 惠迈医疗器械管理系统 - 出入库智能体</h1>
        <p>版本: 1.0.0 | 状态: <span style="color: green;">运行中</span></p>
        
        <div class="card">
          <h2>📊 功能说明</h2>
          <p>此智能体用于查询医疗器械管理系统的产品库存信息。</p>
          <ul>
            <li>查询产品当前库存</li>
            <li>查看产品详细信息</li>
            <li>统计库存情况</li>
            <li>监控库存变化</li>
          </ul>
        </div>
        
        <div class="card">
          <h2>🔗 API接口</h2>
          
          <div class="endpoint">
            <strong>GET /api/inventory/products</strong>
            <p>获取所有产品列表</p>
            <code>curl http://localhost:${PORT}/api/inventory/products</code>
          </div>
          
          <div class="endpoint">
            <strong>GET /api/inventory/product/:code</strong>
            <p>根据产品编号查询库存</p>
            <code>curl http://localhost:${PORT}/api/inventory/product/PM001</code>
          </div>
          
          <div class="endpoint">
            <strong>GET /api/inventory/search?name=口罩</strong>
            <p>根据产品名称搜索</p>
            <code>curl "http://localhost:${PORT}/api/inventory/search?name=口罩"</code>
          </div>
          
          <div class="endpoint">
            <strong>GET /health</strong>
            <p>健康检查</p>
            <code>curl http://localhost:${PORT}/health</code>
          </div>
        </div>
        
        <div class="card">
          <h2>📱 使用方式</h2>
          <p>1. 访问 <a href="/query.html">查询界面</a> 进行可视化查询</p>
          <p>2. 使用API接口进行程序化查询</p>
          <p>3. 集成到其他系统中使用</p>
        </div>
        
        <div class="card">
          <h2>🔧 技术信息</h2>
          <p><strong>数据库:</strong> MySQL (容器: mysql-medgsp)</p>
          <p><strong>服务器:</strong> Node.js + Express</p>
          <p><strong>开发:</strong> 惠迈高级工程师</p>
          <p><strong>时间:</strong> 2026-04-01</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: '接口不存在'
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 出入库智能体已启动`);
  console.log(`📡 访问地址: http://localhost:${PORT}`);
  console.log(`🔍 健康检查: http://localhost:${PORT}/health`);
  console.log(`📊 查询界面: http://localhost:${PORT}/query.html`);
  console.log(`⏰ 启动时间: ${new Date().toLocaleString('zh-CN')}`);
});