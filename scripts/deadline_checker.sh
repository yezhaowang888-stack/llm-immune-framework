#!/bin/bash
# 截止时间自动检测脚本
# 使用: ./deadline_checker.sh

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

# 查找所有任务文件
find "$TASK_DIR" -name "*.json" -type f | while read TASK_FILE; do
    # 只处理TASK-开头的文件
    if [[ $(basename "$TASK_FILE") != TASK-*.json ]]; then
        continue
    fi
    TASK_COUNT=$((TASK_COUNT + 1))
    TASK_ID=$(basename "$TASK_FILE" .json)
    
    # 提取任务信息
    DEADLINE=$(grep -o '"deadline":"[^"]*"' "$TASK_FILE" | cut -d'"' -f4)
    STATUS=$(grep -o '"status":"[^"]*"' "$TASK_FILE" | cut -d'"' -f4)
    TITLE=$(grep -o '"title":"[^"]*"' "$TASK_FILE" | head -1 | cut -d'"' -f4)
    
    # 跳过已完成或已验证的任务
    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "verified" ]; then
        continue
    fi
    
    if [ -n "$DEADLINE" ]; then
        # 转换时间比较（处理带时区和不带时区的情况）
        DEADLINE_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "${DEADLINE}" +%s 2>/dev/null || 
                      date -j -f "%Y-%m-%dT%H:%M:%S" "${DEADLINE}" +%s 2>/dev/null || 
                      echo "0")
        
        if [ "$DEADLINE_TS" != "0" ]; then
            NOW_TS=$(date +%s)
            TIME_DIFF=$((DEADLINE_TS - NOW_TS))
            
            if [ $TIME_DIFF -lt 0 ]; then
                # 已超时
                OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
                OVERDUE_MINUTES=$(( (-TIME_DIFF) / 60 ))
                
                echo "## 🔴 任务超时警报 ($OVERDUE_COUNT)
**任务ID**: $TASK_ID
**任务标题**: $TITLE
**截止时间**: $DEADLINE
**当前状态**: $STATUS
**超时时长**: ${OVERDUE_MINUTES}分钟
**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')
**建议行动**: 立即联系执行人跟进
---" >> "$ALERT_FILE"
                
                # 更新任务状态为超时（如果还不是overdue）
                if [ "$STATUS" != "overdue" ]; then
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
            fi
        fi
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