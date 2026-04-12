#!/bin/bash
# 简单截止时间检查脚本

echo "=== 任务截止时间检查 ==="
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TASK_FILE="/Users/mac/.openclaw/workspace/TASK-MENU-FIX-20260401.json"

if [ ! -f "$TASK_FILE" ]; then
    echo "❌ 任务文件不存在"
    exit 1
fi

# 读取任务信息
TASK_ID="TASK-MENU-FIX-20260401"
TITLE=$(grep '"title"' "$TASK_FILE" | head -1 | sed 's/.*"title": "\([^"]*\)".*/\1/')
STATUS=$(grep '"status"' "$TASK_FILE" | head -1 | sed 's/.*"status": "\([^"]*\)".*/\1/')
DEADLINE=$(grep '"deadline"' "$TASK_FILE" | head -1 | sed 's/.*"deadline": "\([^"]*\)".*/\1/')

echo "任务ID: $TASK_ID"
echo "任务标题: $TITLE"
echo "当前状态: $STATUS"
echo "截止时间: $DEADLINE"
echo ""

# 解析截止时间
if [ -n "$DEADLINE" ]; then
    # 移除时区部分
    DEADLINE_CLEAN=$(echo "$DEADLINE" | sed 's/+08:00//')
    
    # 转换为时间戳
    DEADLINE_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$DEADLINE_CLEAN" +%s 2>/dev/null)
    
    if [ -n "$DEADLINE_TS" ]; then
        NOW_TS=$(date +%s)
        TIME_DIFF=$((NOW_TS - DEADLINE_TS))
        
        if [ $TIME_DIFF -gt 0 ]; then
            # 已超时
            OVERDUE_MINUTES=$((TIME_DIFF / 60))
            OVERDUE_HOURS=$((OVERDUE_MINUTES / 60))
            OVERDUE_REMAINING_MINUTES=$((OVERDUE_MINUTES % 60))
            
            echo "🔴 任务已超时!"
            echo "超时时长: ${OVERDUE_HOURS}小时${OVERDUE_REMAINING_MINUTES}分钟"
            echo ""
            
            # 更新状态为overdue
            if [ "$STATUS" != "overdue" ] && [ "$STATUS" != "completed" ] && [ "$STATUS" != "verified" ]; then
                echo "更新任务状态为 overdue..."
                sed -i '' 's/"status":"escalated"/"status":"overdue"/' "$TASK_FILE"
                echo "✅ 状态已更新"
            fi
            
            # 记录到日志
            LOG_FILE="/Users/mac/.openclaw/workspace/memory/task_overdue_log.md"
            mkdir -p "$(dirname "$LOG_FILE")"
            echo "## $(date '+%Y-%m-%d %H:%M:%S') - 任务超时
**任务**: $TITLE
**ID**: $TASK_ID
**原截止**: $DEADLINE
**超时时长**: ${OVERDUE_HOURS}小时${OVERDUE_REMAINING_MINUTES}分钟
**当前状态**: $STATUS
---" >> "$LOG_FILE"
            
        else
            # 未超时
            REMAINING_SECONDS=$((-TIME_DIFF))
            REMAINING_MINUTES=$((REMAINING_SECONDS / 60))
            
            if [ $REMAINING_MINUTES -lt 60 ]; then
                echo "🟡 任务即将到期!"
                echo "剩余时间: ${REMAINING_MINUTES}分钟"
            else
                REMAINING_HOURS=$((REMAINING_MINUTES / 60))
                echo "🟢 任务未到期"
                echo "剩余时间: 约${REMAINING_HOURS}小时"
            fi
        fi
    else
        echo "⚠️ 无法解析截止时间格式"
    fi
else
    echo "⚠️ 无截止时间设置"
fi

echo ""
echo "=== 检查完成 ==="