#!/bin/bash
# 任务状态自动记录脚本
# 使用: ./task_state_logger.sh TASK_ID OLD_STATUS NEW_STATUS CHANGED_BY "变更原因"

TASK_ID=$1
OLD_STATUS=$2
NEW_STATUS=$3
CHANGED_BY=$4
REASON=${5:-"状态变更"}

# 记录文件
LOG_FILE="/Users/mac/.openclaw/workspace/memory/task_states/$(date +%Y-%m-%d).md"

# 创建目录
mkdir -p "/Users/mac/.openclaw/workspace/memory/task_states"

# 获取任务上下文
TASK_FILE="/Users/mac/.openclaw/workspace/TASK-${TASK_ID}.json"
TASK_CONTEXT=""
if [ -f "$TASK_FILE" ]; then
    TASK_TITLE=$(grep -o '"title":"[^"]*"' "$TASK_FILE" | head -1 | cut -d'"' -f4)
    TASK_CONTEXT="**任务标题**: $TASK_TITLE"
else
    TASK_CONTEXT="**注意**: 任务文件未找到"
fi

# 记录状态变更
echo "## $(date '+%Y-%m-%d %H:%M:%S') - 任务状态变更
**任务ID**: $TASK_ID
$TASK_CONTEXT
**变更人**: $CHANGED_BY
**原状态**: $OLD_STATUS
**新状态**: $NEW_STATUS
**变更原因**: $REASON
---" >> "$LOG_FILE"

echo "✅ 状态变更已记录: $TASK_ID $OLD_STATUS → $NEW_STATUS"
echo "📁 记录位置: $LOG_FILE"