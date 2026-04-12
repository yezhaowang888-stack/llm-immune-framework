#!/bin/bash

# Termius自动化监控脚本
# 监控Termius状态、通讯记录和系统健康

echo "=== Termius自动化监控面板 ==="
echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Termius进程状态
echo -e "${BLUE}1. Termius进程状态:${NC}"
if pgrep -x "Termius" > /dev/null; then
    echo -e "   ${GREEN}✅ 运行中${NC} (PID: $(pgrep -x "Termius" | tr '\n' ',' | sed 's/,$//'))"
else
    echo -e "   ${RED}❌ 未运行${NC}"
fi

# 2. Apple Script权限
echo ""
echo -e "${BLUE}2. Apple Script权限:${NC}"
osascript -e 'tell application "System Events" to get name of processes' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✅ 权限正常${NC}"
else
    echo -e "   ${RED}❌ 权限问题${NC}"
    echo "   需要授权：系统偏好设置 → 安全性与隐私 → 自动化"
fi

# 3. 通讯日志
echo ""
echo -e "${BLUE}3. 最近通讯记录:${NC}"
LOG_FILE="/Users/mac/.openclaw/workspace/logs/termius_communications.log"
if [ -f "$LOG_FILE" ]; then
    echo "   最近5条记录:"
    tail -5 "$LOG_FILE" | while IFS= read -r line; do
        if echo "$line" | grep -q "ERROR"; then
            echo -e "   ${RED}$line${NC}"
        elif echo "$line" | grep -q "SUCCESS"; then
            echo -e "   ${GREEN}$line${NC}"
        else
            echo "   $line"
        fi
    done
else
    echo -e "   ${YELLOW}⚠️ 暂无通讯记录${NC}"
fi

# 4. 自动化日志
echo ""
echo -e "${BLUE}4. 自动化日志状态:${NC}"
AUTO_LOG="/Users/mac/.openclaw/workspace/logs/termius_automation.log"
if [ -f "$AUTO_LOG" ]; then
    LOG_SIZE=$(wc -l < "$AUTO_LOG")
    LAST_ERROR=$(grep -i "error\|fail" "$AUTO_LOG" | tail -1)
    
    echo "   日志行数: $LOG_SIZE"
    if [ -n "$LAST_ERROR" ]; then
        echo -e "   最近错误: ${RED}$LAST_ERROR${NC}"
    else
        echo -e "   最近错误: ${GREEN}无错误记录${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️ 自动化日志文件不存在${NC}"
fi

# 5. 模板状态
echo ""
echo -e "${BLUE}5. 消息模板状态:${NC}"
TEMPLATE_DIR="/Users/mac/.openclaw/workspace/termius-templates"
if [ -d "$TEMPLATE_DIR" ]; then
    TEMPLATE_COUNT=$(find "$TEMPLATE_DIR" -name "*.template" 2>/dev/null | wc -l)
    echo -e "   模板数量: ${GREEN}$TEMPLATE_COUNT${NC}"
    
    if [ "$TEMPLATE_COUNT" -gt 0 ]; then
        echo "   可用模板分类:"
        for category in emergency routine system; do
            COUNT=$(find "$TEMPLATE_DIR/$category" -name "*.template" 2>/dev/null | wc -l)
            if [ "$COUNT" -gt 0 ]; then
                echo -e "     - ${BLUE}$category${NC}: $COUNT 个模板"
            fi
        done
    else
        echo -e "   ${YELLOW}⚠️ 暂无模板文件${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️ 模板目录未创建${NC}"
fi

# 6. 系统健康状态
echo ""
echo -e "${BLUE}6. 系统健康状态:${NC}"

# 磁盘空间
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "   磁盘空间: ${RED}⚠️ $DISK_USAGE% 使用${NC}"
elif [ "$DISK_USAGE" -gt 70 ]; then
    echo -e "   磁盘空间: ${YELLOW}⚠️ $DISK_USAGE% 使用${NC}"
else
    echo -e "   磁盘空间: ${GREEN}✅ $DISK_USAGE% 使用${NC}"
fi

# 内存使用
MEM_FREE=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print $5}' | sed 's/%//')
if [ "$MEM_FREE" -lt 10 ]; then
    echo -e "   内存空闲: ${RED}⚠️ $MEM_FREE% 空闲${NC}"
elif [ "$MEM_FREE" -lt 20 ]; then
    echo -e "   内存空闲: ${YELLOW}⚠️ $MEM_FREE% 空闲${NC}"
else
    echo -e "   内存空闲: ${GREEN}✅ $MEM_FREE% 空闲${NC}"
fi

echo ""
echo "=== 监控结束 ==="
echo "建议操作:"
echo "1. 确保Termius正在运行"
echo "2. 检查Apple Script权限"
echo "3. 定期查看通讯日志"
echo "4. 根据需要更新消息模板"
