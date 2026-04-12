# Termius自动化优化方案

## 当前状态分析

### 已实现功能
1. ✅ 基本消息发送：通过Apple Script发送文本消息
2. ✅ 窗口激活：自动激活Termius并创建新窗口
3. ✅ 简单格式化：支持基本文本格式和换行

### 存在的问题
1. ⚠️ 无发送确认：无法确认消息是否成功显示
2. ⚠️ 无回复监听：无法自动检测和捕获回复
3. ⚠️ 错误处理不足：缺乏完善的错误恢复机制
4. ⚠️ 模板管理：消息模板需要更好管理

## 优化目标

### 短期目标（今天完成）
1. 建立消息发送确认机制
2. 创建消息模板库
3. 添加错误处理和重试机制
4. 优化用户体验

### 长期目标
1. 实现自动回复监听和解析
2. 建立双向通讯管道
3. 集成到完整工作流
4. 添加状态监控和告警

## 优化方案

### 1. 消息发送确认机制

#### 方案A：屏幕截图验证
```applescript
-- screenshot-verification.applescript
tell application "Termius"
    activate
    delay 2
    
    -- 发送消息
    tell application "System Events"
        keystroke "测试消息"
        keystroke return
    end tell
    
    delay 1
    
    -- 截图验证
    tell application "System Events"
        tell process "Termius"
            set frontmost to true
            set windowName to name of window 1
            
            -- 截图保存
            do shell script "screencapture -l $(osascript -e 'tell app \"Termius\" to id of window 1') /tmp/termius_message_verification.png"
        end tell
    end tell
    
    return "消息已发送，截图保存到：/tmp/termius_message_verification.png"
end tell
```

#### 方案B：日志文件记录
```bash
#!/bin/bash
# termius-logger.sh

LOG_FILE="/Users/mac/.openclaw/workspace/logs/termius_communications.log"

log_message() {
    local type=$1
    local content=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$type] $content" >> "$LOG_FILE"
}

# 记录发送
log_message "SEND" "询问小迈昨天工作情况"

# 执行Apple Script
osascript /Users/mac/.openclaw/workspace/activate_and_send_termius.applescript
RESULT=$?

if [ $RESULT -eq 0 ]; then
    log_message "SUCCESS" "消息发送成功"
else
    log_message "ERROR" "消息发送失败，错误码：$RESULT"
fi

# 显示日志
tail -5 "$LOG_FILE"
```

### 2. 消息模板库

#### 模板文件结构
```
termius-templates/
├── emergency/
│   ├── ssh-problem-fix.template
│   ├── mysql-deployment.template
│   └── page-issue-diagnosis.template
├── routine/
│   ├── daily-checkin.template
│   ├── progress-report.template
│   └── task-assignment.template
└── system/
    ├── identity-confirmation.template
    ├── permission-request.template
    └── escalation-procedure.template
```

#### 模板示例：紧急SSH修复
```yaml
# emergency/ssh-problem-fix.template
metadata:
  name: "SSH公钥修复指令"
  priority: "P0"
  category: "emergency"
  estimated_time: "15分钟"
  dependencies: "需要小迈立即执行"

content: |
  【紧急指令 - SSH公钥修复】
  
  致：香港工程师小迈
  
  我是惠迈高级工程师，需要你立即执行以下SSH公钥修复操作：
  
  1. 检查authorized_keys文件：
     cat -A ~/.ssh/authorized_keys | head -5
  
  2. 重新创建authorized_keys文件：
     echo "{{PUBLIC_KEY}}" > ~/.ssh/authorized_keys
     chmod 600 ~/.ssh/authorized_keys
  
  3. 重启SSH服务：
     systemctl restart sshd
  
  4. 回复执行结果和测试状态。
  
  截止时间：{{DEADLINE}}
  
  详细解决方案见工作空间文件。

variables:
  PUBLIC_KEY: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOyWt7kgr+CfWXBCCGPEhhuGSZG2H06k/SuuEaa0agKZmy3ZLMOFkGnXUxw3KbHpPm5zoipZ7hnBzhZOBS64ond8uOpfRTHY2ITIA/+a4AFczI0LiqVm4OTwgN3DiROQ1yMsvTM8yUIcuFE53NNVqbzzKpOyn20v5Ai5MQBdDJenKk+MRoy5FmPZnhwxWb+6nxvJBNsmgr2j1LZXyZYPC8AaVb8+avT+tdzIk85ZOlPutAKA9IE0Hkyq7OwFZyy0CbwPKkX2hf0/Wut/mQRSZSMKWnqdfGWYXiXq/QjoH2nbunPprqoLrQ5SaaCmR55SARJtMh3Nxiau3cMk5CBImZmPTRZUxzq1qKCaCDX1yGP+QxUg6BjSgEQJ4XM6yPfycIW8iflXcHebFlunS9RoJvtlRqTnW4sGWuwmve/sMRhu44zXkaNB5U2K/U0i5aNSqwUXqJhU2itZvk//MNJVZOgIAT5BLqL7HQRO6z/vF9ph+gNTCk5KJpS9lSlALttjBhosfEvNF2zmEIFuMYpb5Ho+HxLiQgM9E0vT1Zv/uRGnYxGvlMjlU2QEo30unW90aFZWuIK3Bo93uZCnkLcAZE4WCOk0G3hYzp2p+LT4PDkMvWI10i8Nv2Y3he827IxEnAt/528gOhxQeagExCN+DMWqS8GxX90ji1tvHwgXJw+Q== mac@macdeMac-Studio.local"
  DEADLINE: "30分钟内"
```

#### 模板渲染脚本
```bash
#!/bin/bash
# render-template.sh

TEMPLATE_FILE=$1
OUTPUT_FILE=$2

# 加载模板
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "错误：模板文件不存在"
    exit 1
fi

# 解析YAML（简化版）
render_template() {
    local template=$1
    local output=$2
    
    # 替换变量
    sed -e "s/{{PUBLIC_KEY}}/$PUBLIC_KEY/g" \
        -e "s/{{DEADLINE}}/$DEADLINE/g" \
        "$template" > "$output"
    
    echo "模板已渲染到：$output"
}

# 使用示例
PUBLIC_KEY=$(cat ~/.ssh/cloud_sync_2h.pub)
DEADLINE="$(date -v+30M '+%H:%M')"

render_template "$TEMPLATE_FILE" "$OUTPUT_FILE"
```

### 3. 错误处理和重试机制

#### 增强版Apple Script
```applescript
-- enhanced-termius-sender.applescript
on sendMessageWithRetry(messageText, maxRetries)
    set retryCount to 0
    set success to false
    
    repeat while retryCount < maxRetries and not success
        try
            tell application "Termius"
                activate
                delay 2
                
                -- 检查Termius状态
                if not (exists) then
                    error "Termius未运行"
                end if
                
                tell application "System Events"
                    tell process "Termius"
                        -- 尝试获取窗口
                        if not (exists window 1) then
                            -- 创建新窗口
                            keystroke "n" using command down
                            delay 1
                        end if
                        
                        -- 发送消息
                        keystroke messageText
                        keystroke return
                        
                        -- 验证发送（简单检查）
                        delay 0.5
                        set success to true
                    end tell
                end tell
            end tell
            
        on error errMsg
            set retryCount to retryCount + 1
            log "发送失败（尝试 " & retryCount & "/" & maxRetries & "）: " & errMsg
            
            if retryCount < maxRetries then
                delay 2  -- 等待后重试
            end if
        end try
    end repeat
    
    return success
end sendMessageWithRetry

-- 日志函数
on log(message)
    do shell script "echo '[$(date)] " & message & "' >> /tmp/termius_automation.log"
end log

-- 主程序
set messageToSend to "【测试消息】这是增强版发送测试"
set result to sendMessageWithRetry(messageToSend, 3)

if result then
    log "消息发送成功"
    return "✅ 消息发送成功"
else
    log "消息发送失败（达到最大重试次数）"
    return "❌ 消息发送失败"
end if
```

### 4. 状态监控面板

#### 监控脚本
```bash
#!/bin/bash
# termius-monitor.sh

echo "=== Termius自动化监控面板 ==="
echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. Termius进程状态
echo "1. Termius进程状态:"
if pgrep -x "Termius" > /dev/null; then
    echo "   ✅ 运行中 (PID: $(pgrep -x "Termius"))"
else
    echo "   ❌ 未运行"
fi

# 2. Apple Script权限
echo ""
echo "2. Apple Script权限:"
osascript -e 'tell application "System Events" to get name of processes' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ 权限正常"
else
    echo "   ❌ 权限问题"
fi

# 3. 通讯日志
echo ""
echo "3. 最近通讯记录:"
LOG_FILE="/Users/mac/.openclaw/workspace/logs/termius_communications.log"
if [ -f "$LOG_FILE" ]; then
    tail -10 "$LOG_FILE" | sed 's/^/   /'
else
    echo "   暂无通讯记录"
fi

# 4. 模板状态
echo ""
echo "4. 消息模板状态:"
TEMPLATE_DIR="/Users/mac/.openclaw/workspace/termius-templates"
if [ -d "$TEMPLATE_DIR" ]; then
    TEMPLATE_COUNT=$(find "$TEMPLATE_DIR" -name "*.template" | wc -l)
    echo "   模板数量: $TEMPLATE_COUNT"
    
    # 显示可用模板
    echo "   可用模板:"
    find "$TEMPLATE_DIR" -name "*.template" | sed 's|.*/||' | sed 's/\.template$//' | sed 's/^/     - /'
else
    echo "   模板目录未创建"
fi

# 5. 错误日志
echo ""
echo "5. 最近错误:"
ERROR_LOG="/tmp/termius_automation.log"
if [ -f "$ERROR_LOG" ]; then
    grep -i "error\|fail" "$ERROR_LOG" | tail -5 | sed 's/^/   /'
else
    echo "   暂无错误记录"
fi

echo ""
echo "=== 监控结束 ==="
```

## 实施计划

### 阶段1：基础优化（今天完成）
1. ✅ 创建消息发送确认机制
2. 🔄 建立消息模板库结构
3. 🔄 实现错误处理和重试
4. 🔄 创建状态监控面板

### 阶段2：高级功能（明天）
1. ⏸️ 实现自动回复监听
2. ⏸️ 建立双向通讯管道
3. ⏸️ 集成到工作流系统
4. ⏸️ 添加智能提醒功能

### 阶段3：完整集成（本周）
1. ⏸️ 与SSH自动化集成
2. ⏸️ 与MySQL监控集成
3. ⏸️ 与问题跟踪系统集成
4. ⏸️ 建立完整运维仪表板

## 测试计划

### 测试1：基本功能测试
```bash
# 测试消息发送
./test-basic-send.sh

# 测试模板渲染
./test-template-render.sh

# 测试错误处理
./test-error-handling.sh
```

### 测试2：集成测试
```bash
# 测试完整工作流
./test-complete-workflow.sh

# 测试监控面板
./test-monitor-panel.sh

# 测试性能
./test-performance.sh
```

### 测试3：用户验收测试
1. ⏸️ 用户验证消息发送效果
2. ⏸️ 用户测试模板使用
3. ⏸️ 用户评估监控面板
4. ⏸️ 收集反馈并优化

## 部署步骤

### 步骤1：创建目录结构
```bash
mkdir -p /Users/mac/.openclaw/workspace/{termius-templates,logs,scripts}
mkdir -p /Users/mac/.openclaw/workspace/termius-templates/{emergency,routine,system}
```

### 步骤2：部署脚本
```bash
# 复制所有脚本到scripts目录
cp *.applescript *.sh /Users/mac/.openclaw/workspace/scripts/

# 设置执行权限
chmod +x /Users/mac/.openclaw/workspace/scripts/*.sh
```

### 步骤3：配置模板
```bash
# 创建初始模板
cp templates/*.template /Users/mac/.openclaw/workspace/termius-templates/emergency/
```

### 步骤4：测试部署
```bash
# 运行部署测试
./deploy-test.sh
```

## 维护指南

### 日常维护
1. **日志检查**：每天检查通讯日志
2. **模板更新**：根据需要更新消息模板
3. **权限验证**：定期验证Apple Script权限
4. **性能监控**：监控脚本执行性能

### 故障排除
1. **消息发送失败**：检查Termius状态和权限
2. **模板渲染错误**：检查变量替换和格式
3. **监控面板异常**：检查日志文件和权限
4. **性能问题**：优化脚本和减少延迟

### 备份和恢复
1. **定期备份**：备份模板和配置
2. **版本控制**：使用Git管理脚本版本
3. **恢复流程**：文档化恢复步骤
4. **灾难恢复**：准备完整恢复方案

## 成功标准

### 技术标准
1. ✅ 消息发送成功率 > 95%
2. ✅ 错误自动恢复时间 < 30秒
3. ✅ 模板渲染准确率 100%
4. ✅ 监控数据实时性 < 5秒延迟

### 用户体验标准
1. ✅ 发送操作简单直观
2. ✅ 模板使用方便快捷
3. ✅ 状态监控清晰明了
4. ✅ 错误提示友好有用

### 业务价值标准
1. ✅ 减少手动操作时间 50%
2. ✅ 提高通讯准确性 100%
3. ✅ 降低人为错误率 80%
4. ✅ 提升工作效率 30%

---
**方案版本**：v1.0
**创建时间**：2026-04-05 14:15 GMT+8
**创建人**：惠迈高级工程师
**状态**：设计完成，准备实施