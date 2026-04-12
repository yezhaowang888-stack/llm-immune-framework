# 医疗器械管理系统 - 本地数据同步环境

## 概述
本地数据同步环境，用于每2小时从云服务器同步医疗器械管理系统的数据和代码到本地服务器。

## 目录结构
```
medical-software/
├── docker-compose.yml          # Docker容器配置
├── mysql/                      # MySQL数据目录
│   ├── data/                  # 数据库数据文件
│   ├── backup/                # 数据库备份文件
│   └── init/                  # 初始化脚本
├── scripts/                   # 同步脚本
│   ├── sync-2h.sh            # 每2小时同步脚本
│   ├── full-sync.sh          # 全量同步脚本
│   ├── monitor-sync.sh       # 监控脚本
│   └── cron-setup.sh         # 定时任务配置
├── logs/                      # 同步日志
├── code-backup/              # 代码备份（按时间戳）
├── code/                     # 最新代码
└── README.md                 # 本文档
```

## 快速开始

### 1. 启动本地MySQL容器
```bash
cd /Users/mac/.openclaw/workspace/medical-software
docker-compose up -d
```

### 2. 配置SSH密钥（需要香港工程师配合）
1. 将公钥 `~/.ssh/cloud_sync_2h.pub` 发送给香港工程师
2. 工程师将公钥添加到云服务器的 `/root/.ssh/authorized_keys`
3. 测试连接：`ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154`

### 3. 执行首次全量同步
```bash
./scripts/full-sync.sh
```

### 4. 配置定时任务
```bash
./scripts/cron-setup.sh
```

## 同步机制

### 同步频率
- **每2小时**：增量数据同步
- **首次**：全量数据同步
- **监控**：每小时检查同步状态

### 同步内容
1. **数据库数据**：MySQL增量数据（基于updated_at/created_at时间戳）
2. **Web代码**：/usr/share/nginx/html/bio/ 目录
3. **应用代码**：/root/medgsp/ 目录

### 数据保留策略
- 数据库备份：保留最近7天
- 代码备份：保留最近7天
- 日志文件：保留最近30天

## 监控和告警

### 监控脚本
```bash
./scripts/monitor-sync.sh
```

### 告警条件
- 超过3小时未同步：❌ 同步异常
- 2-3小时未同步：⚠️ 同步延迟
- 2小时内同步：✅ 同步正常

### 查看日志
```bash
# 查看最新同步日志
tail -f /Users/mac/.openclaw/workspace/medical-software/logs/sync-$(date +%Y%m%d).log

# 查看监控报告
ls -t /Users/mac/.openclaw/workspace/medical-software/logs/monitor-*.md | head -1 | xargs cat
```

## 故障排除

### 常见问题

#### 1. SSH连接失败
```bash
# 测试连接
ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154 "echo test"

# 检查密钥权限
chmod 600 ~/.ssh/cloud_sync_2h
chmod 644 ~/.ssh/cloud_sync_2h.pub
```

#### 2. MySQL连接失败
```bash
# 检查本地MySQL容器
docker ps | grep mysql-medgsp-local

# 检查端口
netstat -an | grep 3307

# 测试连接
mysql -h localhost -P 3307 -uroot -plocal123456 -e "SELECT 1"
```

#### 3. 同步脚本权限问题
```bash
chmod +x /Users/mac/.openclaw/workspace/medical-software/scripts/*.sh
```

#### 4. 磁盘空间不足
```bash
# 检查磁盘使用
df -h /Users/mac/.openclaw/workspace

# 清理旧备份
find /Users/mac/.openclaw/workspace/medical-software -name "*.sql" -mtime +7 -delete
find /Users/mac/.openclaw/workspace/medical-software/code-backup -type d -mtime +7 -exec rm -rf {} \;
```

## 维护命令

### 手动执行同步
```bash
# 增量同步
./scripts/sync-2h.sh

# 全量同步
./scripts/full-sync.sh
```

### 查看定时任务
```bash
crontab -l
```

### 重启服务
```bash
# 重启MySQL容器
cd /Users/mac/.openclaw/workspace/medical-software
docker-compose restart mysql-local
```

### 备份管理
```bash
# 列出数据库备份
ls -lh /Users/mac/.openclaw/workspace/medical-software/mysql/backup/

# 列出代码备份
ls -d /Users/mac/.openclaw/workspace/medical-software/code-backup/*/
```

## 安全注意事项

1. **SSH密钥安全**：私钥文件 `~/.ssh/cloud_sync_2h` 必须保持私密
2. **数据库密码**：本地和云服务器的数据库密码在脚本中硬编码，生产环境应考虑使用环境变量
3. **访问控制**：本地MySQL仅监听localhost，避免外部访问
4. **日志安全**：日志文件可能包含敏感信息，定期清理

## 联系方式

- **负责人**：惠迈高级工程师
- **创建时间**：2026-04-03
- **最后更新**：2026-04-03