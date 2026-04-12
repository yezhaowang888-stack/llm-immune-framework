#!/bin/bash
# 惠迈任务管理器 v1.0
# 用于管理香港工程师任务分配和跟踪

TASKS_DIR="/root/huimai-openclaw/tasks"
ACTIVE_DIR="$TASKS_DIR/active"
COMPLETED_DIR="$TASKS_DIR/completed"
FAILED_DIR="$TASKS_DIR/failed"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 初始化目录
init_dirs() {
    mkdir -p "$ACTIVE_DIR" "$COMPLETED_DIR" "$FAILED_DIR"
    echo -e "${GREEN}任务目录初始化完成${NC}"
}

# 创建新任务
create_task() {
    local task_id="TASK-$(date +%Y%m%d)-$(printf "%03d" $(ls $ACTIVE_DIR/*.json 2>/dev/null | wc -l))"
    
    cat > "$ACTIVE_DIR/$task_id.json" << EOF
{
  "task_id": "$task_id",
  "title": "$1",
  "description": "$2",
  "priority": "${3:-中}",
  "category": "${4:-general}",
  "assigned_to": "hk-engineer",
  "created_by": "惠迈高级工程师",
  "created_at": "$(date -Iseconds)",
  "deadline": "$5",
  "estimated_hours": ${6:-4},
  "status": "pending",
  "progress": 0,
  "last_updated": "$(date -Iseconds)",
  "dependencies": [],
  "attachments": [],
  "notes": ["$(date '+%H:%M'): 任务创建"],
  "completion_criteria": "$7",
  "actual_hours": 0,
  "completed_at": ""
}
EOF
    
    echo -e "${GREEN}任务创建成功: $task_id${NC}"
    echo "文件位置: $ACTIVE_DIR/$task_id.json"
}

# 更新任务状态
update_task() {
    local task_id=$1
    local status=$2
    local progress=$3
    local note=$4
    
    local task_file="$ACTIVE_DIR/$task_id.json"
    
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}任务不存在: $task_id${NC}"
        return 1
    fi
    
    # 更新任务状态
    jq ".status = \"$status\" | .progress = $progress | .last_updated = \"$(date -Iseconds)\" | .notes += [\"$(date '+%H:%M'): $note\"]" "$task_file" > "$task_file.tmp"
    mv "$task_file.tmp" "$task_file"
    
    echo -e "${GREEN}任务更新成功${NC}"
    
    # 如果任务完成或失败，移动到相应目录
    if [[ "$status" == "completed" || "$status" == "failed" ]]; then
        local target_dir=""
        if [ "$status" == "completed" ]; then
            target_dir="$COMPLETED_DIR"
            jq ".completed_at = \"$(date -Iseconds)\"" "$task_file" > "$task_file.tmp"
            mv "$task_file.tmp" "$task_file"
        else
            target_dir="$FAILED_DIR"
        fi
        
        mv "$task_file" "$target_dir/"
        echo -e "${BLUE}任务已移动到: $target_dir${NC}"
    fi
}

# 列出任务
list_tasks() {
    echo -e "${BLUE}=== 活跃任务 ===${NC}"
    for file in "$ACTIVE_DIR"/*.json 2>/dev/null; do
        if [ -f "$file" ]; then
            local task_id=$(jq -r '.task_id' "$file")
            local title=$(jq -r '.title' "$file")
            local status=$(jq -r '.status' "$file")
            local progress=$(jq -r '.progress' "$file")
            local priority=$(jq -r '.priority' "$file")
            
            echo -e "${YELLOW}$task_id${NC}: $title"
            echo "  状态: $status | 进度: ${progress}% | 优先级: $priority"
            echo ""
        fi
    done
    
    echo -e "${GREEN}=== 已完成任务 ===${NC}"
    ls "$COMPLETED_DIR"/*.json 2>/dev/null | head -5 | while read file; do
        local task_id=$(jq -r '.task_id' "$file")
        local title=$(jq -r '.title' "$file")
        echo "  $task_id: $title"
    done
}

# 查看任务详情
view_task() {
    local task_id=$1
    local task_file="$ACTIVE_DIR/$task_id.json"
    
    if [ ! -f "$task_file" ]; then
        task_file="$COMPLETED_DIR/$task_id.json"
    fi
    
    if [ ! -f "$task_file" ]; then
        task_file="$FAILED_DIR/$task_id.json"
    fi
    
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}任务不存在: $task_id${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== 任务详情 ===${NC}"
    jq '.' "$task_file"
}

# 帮助信息
show_help() {
    echo -e "${BLUE}惠迈任务管理器 使用说明${NC}"
    echo "命令:"
    echo "  init             初始化任务目录"
    echo "  create <标题> <描述> [优先级] [分类] [截止时间] [预估工时] [完成标准]"
    echo "  update <任务ID> <状态> <进度> <备注>"
    echo "  list             列出所有任务"
    echo "  view <任务ID>    查看任务详情"
    echo "  help             显示帮助"
    echo ""
    echo "状态选项: pending, assigned, in_progress, testing, completed, failed"
    echo "优先级选项: critical, 高, 中, 低"
}

# 主函数
main() {
    case $1 in
        init)
            init_dirs
            ;;
        create)
            shift
            create_task "$@"
            ;;
        update)
            shift
            update_task "$@"
            ;;
        list)
            list_tasks
            ;;
        view)
            shift
            view_task "$@"
            ;;
        help|*)
            show_help
            ;;
    esac
}

# 检查jq是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}错误: jq命令未安装，请先安装: apt-get install jq 或 yum install jq${NC}"
    exit 1
fi

# 执行主函数
main "$@"