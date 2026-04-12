# 出入库智能体

## 项目概述
惠迈医疗器械管理系统的出入库智能体，用于查询产品库存信息。

## 功能特性
- ✅ 产品库存查询
- ✅ 按产品编号/名称搜索
- ✅ 库存统计与分析
- ✅ 实时数据库连接
- ✅ 友好的Web界面
- ✅ RESTful API接口

## 快速开始

### 1. 安装依赖
```bash
cd inventory-agent
npm install
```

### 2. 配置环境变量
复制 `.env.example` 为 `.env` 并修改数据库配置：
```bash
cp .env.example .env
```

编辑 `.env` 文件：
```env
# 数据库配置
DB_HOST=47.242.48.154
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password_here
DB_DATABASE=medgsp

# 服务器配置
PORT=3000
NODE_ENV=development
```

### 3. 启动服务器
```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm start
```

### 4. 访问应用
- 主界面: http://localhost:3000
- 查询界面: http://localhost:3000/query.html
- 健康检查: http://localhost:3000/health
- API文档: http://localhost:3000

## API接口

### 健康检查
```
GET /health
```

### 测试数据库连接
```
GET /api/inventory/test-connection
```

### 获取所有产品
```
GET /api/inventory/products
```

### 根据产品编号查询
```
GET /api/inventory/product/:code
```

### 根据产品名称搜索
```
GET /api/inventory/search?name=关键词
```

### 获取库存统计
```
GET /api/inventory/stats
```

## 项目结构
```
inventory-agent/
├── package.json          # 项目配置
├── server.js            # 主服务器文件
├── .env                 # 环境变量（需要创建）
├── config/
│   └── database.js      # 数据库配置
├── routes/
│   └── inventory.js     # 库存相关路由
├── controllers/
│   └── inventoryController.js # 控制器
├── models/
│   └── product.js       # 产品模型（待完善）
└── public/
    └── query.html       # 查询界面
```

## 数据库配置

### MySQL连接信息
- **主机**: 47.242.48.154 (阿里云服务器)
- **端口**: 3306
- **容器**: mysql-medgsp (Docker)
- **用户名**: root
- **密码**: 需要从系统配置获取
- **数据库**: medgsp

### 已知表结构
根据系统记录，已知表：
- `product_catalog` - 产品目录表
- `business_partner` - 客户/供应商表

智能体会自动探索数据库表结构并适配查询。

## 开发说明

### 自动表结构探索
智能体会自动：
1. 连接数据库并列出所有表
2. 识别产品相关表（包含"product"关键词）
3. 分析表结构，识别代码、名称、库存等字段
4. 动态生成查询语句

### 容错处理
- 数据库连接失败时返回示例数据
- 自动适配不同的表结构
- 提供友好的错误信息

## 部署说明

### 本地开发
```bash
npm run dev
```

### 生产部署
```bash
npm start
```

### Docker部署（待实现）
```bash
docker build -t inventory-agent .
docker run -p 3000:3000 --env-file .env inventory-agent
```

## 故障排除

### 数据库连接失败
1. 检查MySQL容器是否运行：`docker ps | grep mysql-medgsp`
2. 检查防火墙设置：端口3306是否开放
3. 验证数据库密码是否正确
4. 检查网络连接：`ping 47.242.48.154`

### 应用启动失败
1. 检查Node.js版本：`node --version` (需要 >= 14.0.0)
2. 检查依赖安装：`npm list`
3. 检查端口占用：`lsof -i :3000`

## 下一步计划
- [ ] 添加用户认证
- [ ] 实现出入库记录查询
- [ ] 添加库存预警功能
- [ ] 实现数据导出功能
- [ ] 添加图表展示
- [ ] 支持多数据库类型

## 联系信息
- **项目**: 惠迈医疗器械管理系统
- **开发**: 惠迈高级工程师
- **时间**: 2026-04-01
- **版本**: 1.0.0