# 出入库智能体使用说明

## 快速开始

### 方法1: 使用启动脚本（推荐）
```bash
cd /Users/mac/.openclaw/workspace/inventory-agent
./start.sh
```

### 方法2: 手动启动
```bash
cd /Users/mac/.openclaw/workspace/inventory-agent
npm start
# 或开发模式
npm run dev
```

## 访问地址

启动后访问以下地址：

1. **主界面**: http://localhost:3000
   - 显示API文档和使用说明

2. **查询界面**: http://localhost:3000/query.html
   - 图形化查询界面
   - 支持产品编号/名称搜索
   - 显示库存统计

3. **健康检查**: http://localhost:3000/health
   - 检查服务状态

4. **API接口**: http://localhost:3000/api/inventory
   - RESTful API接口

## 数据库配置

### 获取MySQL密码
要连接真实数据库，需要获取MySQL密码：

1. **查看现有配置**:
   ```bash
   # 查看MySQL容器配置
   docker exec mysql-medgsp env | grep MYSQL_ROOT_PASSWORD
   ```

2. **检查历史记录**:
   - 查看之前的部署记录
   - 检查MySQL容器创建命令

3. **重置密码**（如果需要）:
   ```bash
   # 进入MySQL容器
   docker exec -it mysql-medgsp mysql -u root -p
   # 然后修改密码
   ```

### 配置环境变量
编辑 `.env` 文件：
```env
DB_PASSWORD=your_actual_password_here
```

## 使用示例

### 1. 查询所有产品
```
GET http://localhost:3000/api/inventory/products
```

### 2. 按产品编号查询
```
GET http://localhost:3000/api/inventory/product/PM001
```

### 3. 按产品名称搜索
```
GET http://localhost:3000/api/inventory/search?name=口罩
```

### 4. 获取库存统计
```
GET http://localhost:3000/api/inventory/stats
```

## 功能说明

### 智能表结构探索
智能体会自动：
- 探索数据库中的所有表
- 识别产品相关表
- 分析表字段结构
- 动态生成查询语句

### 容错模式
当数据库连接失败时：
- 返回示例数据供测试
- 显示友好的错误信息
- 提供故障排除建议

### 示例数据
当无法连接数据库时，返回示例数据：
```json
[
  { "code": "PM001", "name": "一次性使用注射器", "stock": 100 },
  { "code": "PM002", "name": "医用外科口罩", "stock": 500 },
  { "code": "PM003", "name": "医用防护服", "stock": 50 }
]
```

## 故障排除

### 常见问题

1. **数据库连接失败**
   ```
   错误: connect ECONNREFUSED 47.242.48.154:3306
   ```
   **解决方案**:
   - 检查MySQL容器是否运行: `docker ps | grep mysql-medgsp`
   - 检查防火墙设置
   - 验证数据库密码

2. **依赖安装失败**
   ```
   npm error code EACCES
   ```
   **解决方案**:
   - 使用启动脚本: `./start.sh`
   - 或指定缓存目录: `npm install --cache /tmp/npm-cache`

3. **端口被占用**
   ```
   Error: listen EADDRINUSE: address already in use :::3000
   ```
   **解决方案**:
   - 修改 `.env` 文件中的 `PORT` 设置
   - 或停止占用端口的进程

### 日志查看
```bash
# 查看服务器日志
cd /Users/mac/.openclaw/workspace/inventory-agent
node server.js 2>&1 | tee server.log
```

## 下一步开发

### 待实现功能
- [ ] 用户认证系统
- [ ] 出入库记录查询
- [ ] 库存预警功能
- [ ] 数据导出（Excel/PDF）
- [ ] 图表可视化
- [ ] 移动端适配

### 数据库优化
- [ ] 连接池优化
- [ ] 查询缓存
- [ ] 数据库迁移脚本
- [ ] 备份恢复功能

## 联系信息
- **项目**: 惠迈医疗器械管理系统
- **组件**: 出入库智能体
- **版本**: 1.0.0
- **开发**: 惠迈高级工程师
- **时间**: 2026-04-01 13:45 GMT+8