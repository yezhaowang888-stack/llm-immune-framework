#!/bin/bash
# 触发小迈智能体通用脚本

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"
TASK_FILE="/root/huimai-openclaw/tasks/active/TASK-20260408-004.json"

echo "=== 触发小迈智能体 ==="
echo "时间: $(date)"
echo "任务: $TASK_FILE"
echo ""

# 方法1：检查并创建触发文件
echo "方法1: 文件系统触发"
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" << 'SERVEREOF'
# 尝试多个可能的触发位置
TRIGGER_PATHS=(
  "/root/huimai-openclaw/agents/xiaomai/inbox/"
  "/root/huimai-openclaw/tasks/pending/"
  "/root/agent_triggers/"
  "/tmp/xiaomai_tasks/"
)

for path in "${TRIGGER_PATHS[@]}"; do
  if [ -d "$path" ]; then
    echo "找到智能体目录: $path"
    TRIGGER_FILE="$path/task_$(date +%Y%m%d_%H%M%S).json"
    cat > "$TRIGGER_FILE" << 'TASKTRIGGER'
{
  "source": "惠迈高级工程师",
  "target": "xiaomai_agent",
  "action": "execute",
  "task_ref": "TASK-20260408-004",
  "timestamp": "$(date -Iseconds)",
  "urgent": true
}
TASKTRIGGER
    echo "触发文件已创建: $TRIGGER_FILE"
    break
  fi
done

# 如果没有找到目录，创建通用位置
if [ ! -f "$TRIGGER_FILE" ]; then
  mkdir -p /root/agent_triggers/
  TRIGGER_FILE="/root/agent_triggers/xiaomai_$(date +%s).json"
  cat > "$TRIGGER_FILE" << 'GENERICTRIGGER'
{
  "message": "小迈智能体请执行任务 TASK-20260408-004",
  "task_file": "/root/huimai-openclaw/tasks/active/TASK-20260408-004.json",
  "trigger_time": "$(date -Iseconds)"
}
GENERICTRIGGER
  echo "通用触发文件已创建: $TRIGGER_FILE"
fi
SERVEREOF

echo ""
echo "=== 触发完成 ==="
echo "请检查智能体响应"