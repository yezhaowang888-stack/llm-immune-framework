# Termius自动化使用指南（简化版）

## 快速开始

### 1. 检查基础设施
```bash
cd /Users/mac/.openclaw/workspace
./scripts/test-termius-infrastructure.sh
```

### 2. 运行监控面板
```bash
./scripts/termius-monitor.sh
```

### 3. 测试日志功能
```bash
# 记录测试消息
./scripts/termius-logger.sh send "测试消息"

# 查看统计
./scripts/termius-logger.sh stats

# 查看最近日志
./scripts/termius-logger.sh tail
```

### 4. 查看可用模板
```bash
ls termius-templates/emergency/
cat termius-templates/emergency/ssh-problem-fix.template
```

## 核心功能

### 监控脚本 (`termius-monitor.sh`)
- 检查Termius进程状态
- 验证Apple Script权限
- 显示通讯日志
- 系统健康检查

### 日志脚本 (`termius-logger.sh`)
```bash
# 基本用法
./scripts/termius-logger.sh send "消息内容"      # 记录发送
./scripts/termius-logger.sh receive "回复内容"   # 记录接收
./scripts/termius-logger.sh success "成功信息"   # 记录成功
./scripts/termius-logger.sh error "错误信息"     # 记录错误
./scripts/termius-logger.sh stats               # 查看统计
./scripts/termius-logger.sh tail                # 查看最近日志
./scripts/termius-logger.sh search "关键词"     # 搜索日志
```

### 消息模板
位置：`termius-templates/`
- `emergency/` - 紧急模板
- `routine/` - 日常模板
- `system/` - 系统模板

## 工作流程示例

### 发送紧急SSH修复指令
```bash
# 1. 检查系统状态
./scripts/termius-monitor.sh

# 2. 准备消息（使用模板）
SSH_TEMPLATE="termius-templates/emergency/ssh-problem-fix.template"
MESSAGE=$(cat "$SSH_TEMPLATE" | \
  sed "s/{{PUBLIC_KEY}}/$(cat ~/.ssh/cloud_sync_2h.pub)/g" | \
  sed "s/{{DEADLINE}}/$(date -v+30M '+%H:%M')/g")

# 3. 发送消息（通过Termius）
# 需要手动在Termius中发送或使用Apple Script

# 4. 记录发送日志
./scripts/termius-logger.sh send "发送SSH修复指令给小迈"
```

### 日常检查流程
```bash
# 1. 发送检查请求
./scripts/termius-logger.sh send "发送日常检查请求"

# 2. 等待回复（实际工作中）
# 等待小迈在Termius中回复

# 3. 记录回复
./scripts/termius-logger.sh receive "收到小迈回复：..."

# 4. 更新状态
./scripts/termius-logger.sh success "日常检查完成"
```

## 故障排除

### 常见问题

#### Termius未运行
```bash
# 启动Termius
open -a Termius
```

#### Apple Script权限错误
1. 系统偏好设置 → 安全性与隐私 → 隐私
2. 选择"自动化"
3. 确保Termius被选中
4. 选择"辅助功能"，添加Termius

#### 脚本权限问题
```bash
# 设置执行权限
chmod +x /Users/mac/.openclaw/workspace/scripts/*.sh
```

## 最佳实践

1. **发送前检查**：先运行监控脚本
2. **记录所有操作**：使用日志脚本记录
3. **使用模板**：提高效率和一致性
4. **定期维护**：每天运行一次监控

## 文件位置

- 脚本：`/Users/mac/.openclaw/workspace/scripts/`
- 模板：`/Users/mac/.openclaw/workspace/termius-templates/`
- 日志：`/Users/mac/.openclaw/workspace/logs/`
- 文档：本文件和其他相关文档

## 支持

如有问题，查看：
- 详细方案：`Termius自动化优化方案.md`
- 问题跟踪：`待处理问题清单.md`
- 系统诊断：`系统深度诊断报告.md`

---
**指南版本**：v1.0
**更新时间**：2026-04-05 13:30 GMT+8
**适用对象**：惠迈高级工程师、老王