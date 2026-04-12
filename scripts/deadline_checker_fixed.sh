#!/bin/bash
# 截止时间自动检测脚本（修复版）

echo "开始检查任务截止时间 - $(date '+%Y-%m-%d %H:%M:%S')"

# 检查所有JSON任务文件的截止时间
TASK_DIR="/Users/mac/.openclaw/workspace"
ALERT_FILE="/Users/mac/.openclaw/workspace/memory/deadline_alerts/$(date +%Y-%m-%d).md"

mkdir -p "/Users/mac/.openclaw/workspace/memory/deadline_alerts"

# 初始化告警文件
echo "# 任务截止时间告警 - $(date '+%Y年%m月%d日 %H:%M:%S')
" > "$ALERT_FILE"

TASK_COUNT=0
OVERDUE_COUNT=0
APPROACHING_COUNT=0

# 手动指定任务文件（测试用）
TASK_FILES=(
    "/Users/mac/.openclaw/workspace/TASK-MENU-FIX-20260401.json"
)

for TASK_FILE in "${TASK_FILES[@]}"; do
    if [ ! -f "$TASK_FILE" ]; then
        echo "⚠️ 任务文件不存在: $TASK_FILE"
        continue
    fi
    
    TASK_COUNT=$((TASK_COUNT + 1))
    TASK_ID=$(basename "$TASK_FILE" .json)
    
    # 提取任务信息
    DEADLINE=$(grep -o '"deadline":"[^"]*"' "$TASK_FILE" | head -1 | cut -d'"' -f4)
    STATUS=$(grep -o '"status":"[^"]*"' "$TASK_FILE" | head -1 | cut -d'"' -f4)
    TITLE=$(grep -o '"title":"[^"]*"' "$TASK_FILE" | head -1 | cut -d'"' -f4)
    
    echo "检查任务: $TITLE ($TASK_ID)"
    echo "  状态: $STATUS, 截止时间: $DEADLINE"
    
    # 跳过已完成或已验证的任务
    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "verified" ]; then
        echo "  跳过: 任务已完成"
        continue
    fi
    
    if [ -n "$DEADLINE" ] && [ "$DEADLINE" != "null" ]; then
        # 转换时间比较
        # 尝试带时区格式
        DEADLINE_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "${DEADLINE}" +%s 2>/dev/null)
        
        # 如果不成功，尝试不带时区
        if [ -z "$DEADLINE_TS" ]; then
            DEADLINE_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${DEADLINE}" +%s 2>/dev/null)
        fi
        
        if [ -n "$DEADLINE_TS" ]; then
            NOW_TS=$(date +%s)
            TIME_DIFF=$((DEADLINE_TS - NOW_TS))
            
            echo "  时间差: $TIME_DIFF 秒"
            
            if [ $TIME_DIFF -lt 0 ]; then
                # 已超时
                OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
                OVERDUE_MINUTES=$(( (-TIME_DIFF) / 60 ))
                OVERDUE_HOURS=$((OVERDUE_MINUTES / 60))
                
                echo "## 🔴 任务超时警报 ($OVERDUE_COUNT)
**任务ID**: $TASK_ID
**任务标题**: $TITLE
**截止时间**: $DEADLINE
**当前状态**: $STATUS
**超时时长**: ${OVERDUE_HOURS}小时${OVERDUE_MINUTES}分钟
**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')
**建议行动**: 立即联系执行人跟进
---" >> "$ALERT_FILE"
                
                # 更新任务状态为超时（如果还不是overdue）
                if [ "$STATUS" != "overdue" ] && [ "$STATUS" != "completed" ]; then
                    sed -i '' "s/\"status\":\"[^\"]*\"/\"status\":\"overdue\"/" "$TASK_FILE"
                    echo "🔄 更新任务状态: $TASK_ID → overdue"
                fi
                
            elif [ $TIME_DIFF -lt 3600 ]; then
                # 1小时内到期
                APPROACHING_COUNT=$((APPROACHING_COUNT + 1))
                REMAINING_MINUTES=$((TIME_DIFF / 60))
                
                echo "## 🟡 任务即将到期 ($APPROACHING_COUNT)
**任务ID**: $TASK_ID
**任务标题**: $TITLE
**截止时间**: $DEADLINE
**当前状态**: $STATUS
**剩余时间**: ${REMAINING_MINUTES}分钟
**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')
**建议行动**: 提醒执行人注意时间
---" >> "$ALERT_FILE"
            else
                echo "  状态: 未到期"
            fi
        else
            echo "⚠️ 无法解析截止时间: $DEADLINE"
        fi
    else
        echo "⚠️ 无有效截止时间"
    fi
done

echo "
## 检查摘要
**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')
**检查任务数**: $TASK_COUNT
**超时任务数**: $OVERDUE_COUNT
**即将到期任务数**: $APPROACHING_COUNT
**告警文件**: $ALERT_FILE
" >> "$ALERT_FILE"

echo "✅ 截止时间检查完成"
echo "📊 统计: 检查了$TASK_COUNT个任务，发现$OVERDUE_COUNT个超时，$APPROACHING_COUNT个即将到期"
echo "📁 告警文件: $ALERT_FILE"

# 显示告警内容
if [ $OVERDUE_COUNT -gt 0 ]; then
    echo ""
    echo "🔴 超时任务告警:"
    tail -20 "$ALERT_FILE"
fi