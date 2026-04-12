# MySQL容器部署方案

## 部署目标
在本地Mac Studio上部署MySQL容器，用于：
1. 导入云服务器数据库备份
2. 提供本地测试环境
3. 支持应用程序连接测试

## 环境要求
- Docker Desktop for Mac (已安装)
- 磁盘空间：至少2GB
- 内存：至少1GB分配给Docker

## 部署方案

### 方案1：使用Docker Compose（推荐）

#### 1.1 创建docker-compose.yml
```yaml
version: '3.8'

services:
  mysql-medgsp:
    image: mysql:8.0
    container_name: mysql-medgsp
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: YourPassword123!
      MYSQL_DATABASE: med_gsp
      MYSQL_USER: medgsp_user
      MYSQL_PASSWORD: MedGsp@2026
    ports:
      - "3306:3306"
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d
      - ./mysql/conf:/etc/mysql/conf.d
    command: 
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --default-authentication-plugin=mysql_native_password
    networks:
      - medgsp-network

networks:
  medgsp-network:
    driver: bridge
```

#### 1.2 创建目录结构
```bash
# 创建必要目录
mkdir -p /Users/mac/.openclaw/workspace/medical-software/mysql/{data,init,conf,backup}

# 设置权限
chmod -R 755 /Users/mac/.openclaw/workspace/medical-software/mysql/
```

#### 1.3 准备初始化脚本
创建 `/Users/mac/.openclaw/workspace/medical-software/mysql/init/01-init.sql`：
```sql
-- 创建医疗系统数据库
CREATE DATABASE IF NOT EXISTS med_gsp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建应用程序用户
CREATE USER IF NOT EXISTS 'medgsp_app'@'%' IDENTIFIED BY 'AppPassword@2026';
GRANT ALL PRIVILEGES ON med_gsp.* TO 'medgsp_app'@'%';
FLUSH PRIVILEGES;

-- 创建测试数据（可选）
USE med_gsp;
CREATE TABLE IF NOT EXISTS system_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50) NOT NULL,
    last_backup TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'maintenance', 'backup') DEFAULT 'active'
);

INSERT INTO system_info (version) VALUES ('med-gsp-v1.0');
```

### 方案2：直接Docker命令（简单版）

#### 2.1 启动MySQL容器
```bash
# 创建数据目录
mkdir -p ~/docker/mysql-medgsp/data

# 启动MySQL容器
docker run -d \
  --name mysql-medgsp \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=YourPassword123! \
  -e MYSQL_DATABASE=med_gsp \
  -v ~/docker/mysql-medgsp/data:/var/lib/mysql \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci
```

#### 2.2 验证容器状态
```bash
# 检查容器运行状态
docker ps | grep mysql-medgsp

# 检查日志
docker logs mysql-medgsp

# 测试数据库连接
docker exec -it mysql-medgsp mysql -uroot -pYourPassword123! -e "SHOW DATABASES;"
```

### 方案3：使用现有医疗软件配置

#### 3.1 检查现有配置
```bash
# 查看现有docker-compose配置
cat /Users/mac/.openclaw/workspace/medical-software/docker-compose.yml

# 查看MySQL相关配置
cat /Users/mac/.openclaw/workspace/medical-software/docker-compose-mysql-only.yml
```

#### 3.2 使用优化配置
基于现有配置进行优化：
```yaml
# medical-software/docker-compose-optimized.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: medgsp-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-YourPassword123!}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-med_gsp}
    ports:
      - "3307:3306"  # 使用3307端口避免冲突
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backup-received:/backup
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

volumes:
  mysql_data:
```

## 数据库导入流程

### 步骤1：准备备份文件
```bash
# 1. 检查备份文件
ls -la /Users/mac/.openclaw/workspace/medical-software/backup-received/

# 2. 解压备份文件（如果需要）
tar -xzf medgsp_final_20260403_1308.tar.gz -C /tmp/

# 3. 查找数据库SQL文件
find /tmp -name "*.sql" -type f | head -5
```

### 步骤2：导入数据库
```bash
# 方法A：使用docker exec直接导入
docker exec -i mysql-medgsp mysql -uroot -pYourPassword123! med_gsp < /path/to/database.sql

# 方法B：复制文件到容器内导入
docker cp /path/to/database.sql mysql-medgsp:/tmp/database.sql
docker exec mysql-medgsp mysql -uroot -pYourPassword123! med_gsp -e "source /tmp/database.sql"

# 方法C：使用初始化目录自动导入
cp /path/to/database.sql /Users/mac/.openclaw/workspace/medical-software/mysql/init/
# 重启容器会自动执行
```

### 步骤3：验证导入结果
```bash
# 1. 连接数据库
docker exec -it mysql-medgsp mysql -uroot -pYourPassword123! med_gsp

# 2. 检查表
SHOW TABLES;

# 3. 检查数据量
SELECT table_name, table_rows 
FROM information_schema.tables 
WHERE table_schema = 'med_gsp';

# 4. 检查关键表数据
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM customers;
```

## 应用程序连接配置

### 前端应用连接配置
```javascript
// 前端应用配置文件
const dbConfig = {
  host: 'localhost',
  port: 3306,  // 或3307如果使用优化配置
  database: 'med_gsp',
  user: 'medgsp_app',
  password: 'AppPassword@2026',
  charset: 'utf8mb4',
  connectionLimit: 10
};
```

### 连接测试脚本
```bash
#!/bin/bash
# test-mysql-connection.sh

echo "=== MySQL连接测试 ==="

# 测试1：容器内部连接
echo -e "\n[测试1] 容器内部连接"
docker exec mysql-medgsp mysql -uroot -pYourPassword123! -e "SELECT '内部连接成功' AS status;"

# 测试2：外部连接
echo -e "\n[测试2] 外部连接"
mysql -h 127.0.0.1 -P 3306 -u root -pYourPassword123! -e "SELECT '外部连接成功' AS status;" 2>/dev/null || echo "外部连接失败"

# 测试3：应用程序用户连接
echo -e "\n[测试3] 应用程序用户连接"
mysql -h 127.0.0.1 -P 3306 -u medgsp_app -pAppPassword@2026 -e "SELECT '应用连接成功' AS status;" med_gsp 2>/dev/null || echo "应用连接失败"

echo -e "\n=== 测试完成 ==="
```

## 监控和维护

### 监控脚本
```bash
#!/bin/bash
# monitor-mysql.sh

echo "=== MySQL容器监控 ==="
echo "监控时间: $(date)"

# 1. 容器状态
echo -e "\n[1] 容器状态:"
docker ps --filter "name=mysql-medgsp" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. 资源使用
echo -e "\n[2] 资源使用:"
docker stats mysql-medgsp --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# 3. 数据库状态
echo -e "\n[3] 数据库状态:"
docker exec mysql-medgsp mysql -uroot -pYourPassword123! -e "
SHOW GLOBAL STATUS LIKE 'Threads_connected';
SHOW GLOBAL STATUS LIKE 'Queries';
SHOW PROCESSLIST;
" 2>/dev/null | head -20

# 4. 磁盘空间
echo -e "\n[4] 磁盘空间:"
docker exec mysql-medgsp df -h /var/lib/mysql

echo -e "\n=== 监控完成 ==="
```

### 备份脚本
```bash
#!/bin/bash
# backup-mysql.sh

BACKUP_DIR="/Users/mac/.openclaw/workspace/medical-software/mysql/backup"
BACKUP_FILE="medgsp_backup_$(date +%Y%m%d_%H%M%S).sql"

echo "开始备份MySQL数据库..."

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 执行备份
docker exec mysql-medgsp mysqldump -uroot -pYourPassword123! \
  --databases med_gsp \
  --routines \
  --triggers \
  --single-transaction \
  --quick \
  > "$BACKUP_DIR/$BACKUP_FILE"

# 压缩备份
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "备份完成: $BACKUP_DIR/${BACKUP_FILE}.gz"
echo "文件大小: $(du -h "$BACKUP_DIR/${BACKUP_FILE}.gz" | cut -f1)"
```

## 故障排除

### 常见问题及解决方案

#### 问题1：端口冲突
```bash
# 检查端口占用
lsof -i :3306

# 解决方案：修改端口
# 在docker-compose.yml中修改 ports: "3307:3306"
```

#### 问题2：权限问题
```bash
# 检查数据目录权限
ls -la /Users/mac/.openclaw/workspace/medical-software/mysql/data/

# 解决方案：设置正确权限
sudo chown -R 999:999 /Users/mac/.openclaw/workspace/medical-software/mysql/data/
```

#### 问题3：内存不足
```bash
# 检查Docker内存设置
# Docker Desktop → Preferences → Resources → Memory

# 解决方案：增加内存或添加swap
docker update --memory 2g --memory-swap 3g mysql-medgsp
```

#### 问题4：连接失败
```bash
# 检查防火墙
sudo pfctl -s rules | grep 3306

# 检查MySQL用户权限
docker exec mysql-medgsp mysql -uroot -pYourPassword123! -e "
SELECT host, user FROM mysql.user;
SHOW GRANTS FOR 'medgsp_app'@'%';
"
```

## 部署检查清单

### 部署前检查
- [ ] Docker Desktop已安装并运行
- [ ] 磁盘空间充足（>2GB）
- [ ] 端口3306/3307可用
- [ ] 备份文件已准备

### 部署中检查
- [ ] 容器成功启动
- [ ] 数据库服务正常运行
- [ ] 端口映射正确
- [ ] 数据目录挂载正常

### 部署后检查
- [ ] 数据库连接测试通过
- [ ] 备份数据成功导入
- [ ] 应用程序连接测试通过
- [ ] 监控脚本正常运行

## 执行计划

### 阶段1：环境准备（今天）
1. ✅ 检查Docker环境
2. 🔄 准备部署脚本和配置
3. 🔄 创建目录结构

### 阶段2：容器部署（等待用户）
1. ⏸️ 执行docker-compose up
2. ⏸️ 验证容器状态
3. ⏸️ 测试基本连接

### 阶段3：数据导入（等待SSH解决）
1. ⏸️ 获取完整数据库备份
2. ⏸️ 导入备份数据
3. ⏸️ 验证数据完整性

### 阶段4：应用集成（后续）
1. ⏸️ 配置应用程序连接
2. ⏸️ 测试完整功能
3. ⏸️ 建立监控和维护流程

---
**文档版本**：v1.0
**创建时间**：2026-04-05 13:35 GMT+8
**更新人**：惠迈高级工程师
**状态**：等待执行环境准备