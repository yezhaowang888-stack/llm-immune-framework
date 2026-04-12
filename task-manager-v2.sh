#!/bin/bash
# 惠迈任务管理器 v2.0
# 集成优先级管理功能

TASKS_DIR="/root/huimai-openclaw/tasks"
ACTIVE_DIR="$TASKS_DIR/active"
COMPLETED_DIR="$TASKS_DIR/completed"
FAILED_DIR="$TASKS_DIR/failed"
PRIORITY_CALCULATOR="$TASKS_DIR/priority-calculator.sh"

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 优先级颜色映射
get_priority_color() {
    local level=$1
    
    case $level in
        "紧急")
            echo "$RED"
            ;;
        "高")
            echo "$ORANGE"
            ;;
        "中")
            echo "$YELLOW"
            ;;
        "低")
            echo "$GREEN"
            ;;
        *)
            echo "$NC"
            ;;
    esac
}

# 初始化目录
init_dirs() {
    mkdir -p "$ACTIVE_DIR" "$COMPLETED_DIR" "$FAILED_DIR"
    echo -e "${GREEN}任务目录初始化完成${NC}"
}

# 交互式获取优先级维度
get_priority_interactive() {
    echo -e "${CYAN}=== 任务优先级评估 ===${NC}"
    
    # 紧急度
    while true; do
        read -p "紧急度（1-10分，10分最紧急）: " urgency
        if [[ $urgency =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 重要度
    while true; do
        read -p "重要度（1-10分，10分最重要）: " importance
        if [[ $importance =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 复杂度
    while true; do
        read -p "复杂度（1-10分，10分最复杂）: " complexity
        if [[ $complexity =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 依赖度
    while true; do
        read -p "依赖度（1-10分，10分依赖最强）: " dependency
        if [[ $dependency =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    echo "$urgency $importance $complexity $dependency"
}

# 计算优先级信息
calculate_priority_info() {
    local urgency=$1
    local importance=$2
    local complexity=$3
    local dependency=$4
    local deadline=$5
    local created_at=$6
    
    # 使用优先级计算器
    if [ -f "$PRIORITY_CALCULATOR" ]; then
        local score=$("$PRIORITY_CALCULATOR" calc $urgency $importance $complexity $dependency 2>/dev/null | grep "优先级分数" | cut -d: -f2 | xargs)
        local level=$("$PRIORITY_CALCULATOR" calc $urgency $importance $complexity $dependency 2>/dev/null | grep "优先级级别" | cut -d: -f2 | xargs)
        
        # 计算四象限
        local quadrant=""
        if [ $urgency -ge 7 ] && [ $importance -ge 7 ]; then
            quadrant="第一象限（紧急且重要）"
        elif [ $urgency -lt 7 ] && [ $importance -ge 7 ]; then
            quadrant="第二象限（重要但不紧急）"
        elif [ $urgency -ge 7 ] && [ $importance -lt 7 ]; then
            quadrant="第三象限（紧急但不重要）"
        else
            quadrant="第四象限（不紧急不重要）"
        fi
        
        echo "$score $level $quadrant"
    else
        # 简单计算（如果没有计算器）
        local score=$(echo "scale=2; ($urgency * 0.35) + ($importance * 0.40) - ($complexity * 0.15) + ($dependency * 0.10)" | bc 2>/dev/null || echo "0")
        
        local level="中"
        if [ $(echo "$score >= 8.1" | bc 2>/dev/null || echo "0") -eq 1 ]; then
            level="紧急"
        elif [ $(echo "$score >= 6.1" | bc 2>/dev/null || echo "0") -eq 1 ]; then
            level="高"
        elif [ $(echo "$score >= 3.1" | bc 2>/dev/null || echo "0") -eq 1 ]; then
            level="中"
        else
            level="低"
        fi
        
        # 计算四象限
        local quadrant=""
        if [ $urgency -ge 7 ] && [ $importance -ge 7 ]; then
            quadrant="第一象限（紧急且重要）"
        elif [ $urgency -lt 7 ] && [ $importance -ge 7 ]; then
            quadrant="第二象限（重要但不紧急）"
        elif [ $urgency -ge 7 ] && [ $importance -lt 7 ]; then
            quadrant="第三象限（紧急但不重要）"
        else
            quadrant="第四象限（不紧急不重要）"
        fi
        
        echo "$score $level $quadrant"
    fi
}

# 创建新任务（带优先级）
create_task() {
    local task_id="TASK-$(date +%Y%m%d)-$(printf "%03d" $(ls $ACTIVE_DIR/*.json 2>/dev/null | wc -l))"
    
    # 获取任务基本信息
    local title=$1
    local description=$2
    local category=${3:-general}
    local deadline=${4:-""}
    local estimated_hours=${5:-4}
    local completion_criteria=${6:-""}
    
    # 获取优先级维度
    echo -e "${CYAN}创建任务: $title${NC}"
    read -p "是否进行优先级评估？(y/n, 默认y): " do_priority
    do_priority=${do_priority:-y}
    
    local urgency=5 importance=5 complexity=5 dependency=5
    
    if [[ $do_priority =~ ^[Yy]$ ]]; then
        echo "请评估以下维度（1-10分）:"
        priority_dims=$(get_priority_interactive)
        urgency=$(echo $priority_dims | cut -d' ' -f1)
        importance=$(echo $priority_dims | cut -d' ' -f2)
        complexity=$(echo $priority_dims | cut -d' ' -f3)
        dependency=$(echo $priority_dims | cut -d' ' -f4)
    fi
    
    # 计算优先级信息
    local created_at=$(date -Iseconds)
    local priority_info=$(calculate_priority_info $urgency $importance $complexity $dependency "$deadline" "$created_at")
    local score=$(echo $priority_info | cut -d' ' -f1)
    local level=$(echo $priority_info | cut -d' ' -f2)
    local quadrant=$(echo $priority_info | cut -d' ' -f3)
    
    # 创建任务JSON文件
    cat > "$ACTIVE_DIR/$task_id.json" << EOF
{
  "task_id": "$task_id",
  "title": "$title",
  "description": "$description",
  "category": "$category",
  "assigned_to": "hk-engineer",
  "created_by": "惠迈高级工程师",
  "created_at": "$created_at",
  "deadline": "$deadline",
  "estimated_hours": $estimated_hours,
  "status": "pending",
  "progress": 0,
  "last_updated": "$created_at",
  "dependencies": [],
  "attachments": [],
  "notes": ["$(date '+%H:%M'): 任务创建"],
  "completion_criteria": "$completion_criteria",
  "actual_hours": 0,
  "completed_at": "",
  "priority_metrics": {
    "urgency": $urgency,
    "importance": $importance,
    "complexity": $complexity,
    "dependency": $dependency,
    "calculated_score": $score,
    "priority_level": "$level",
    "quadrant": "$quadrant"
  }
}
EOF
    
    local color=$(get_priority_color "$level")
    echo -e "${GREEN}任务创建成功: $task_id${NC}"
    echo -e "优先级: ${color}$level${NC} (分数: $score)"
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

# 列出任务（按优先级排序）
list_tasks() {
    local sort_by=${1:-priority}  # 默认按优先级排序
    
    echo -e "${BLUE}=== 活跃任务（按${sort_by}排序）===${NC}"
    
    # 收集所有任务
    declare -A tasks
    for file in "$ACTIVE_DIR"/*.json; do
        if [ -f "$file" ]; then
            local task_id=$(jq -r '.task_id' "$file" 2>/dev/null)
            local title=$(jq -r '.title' "$file" 2>/dev/null)
            local status=$(jq -r '.status' "$file" 2>/dev/null)
            local progress=$(jq -r '.progress' "$file" 2>/dev/null)
            local priority_level=$(jq -r '.priority_metrics.priority_level' "$file" 2>/dev/null)
            local score=$(jq -r '.priority_metrics.calculated_score' "$file" 2>/dev/null)
            local quadrant=$(jq -r '.priority_metrics.quadrant' "$file" 2>/dev/null)
            local deadline=$(jq -r '.deadline' "$file" 2>/dev/null)
            
            if [ -n "$task_id" ]; then
                tasks["$task_id"]="$title|$status|$progress|$priority_level|$score|$quadrant|$deadline"
            fi
        fi
    done
    
    # 按优先级分数排序
    for task_id in $(echo "${!tasks[@]}" | tr ' ' '\n' | sort -r); do
        IFS='|' read -r title status progress priority_level score quadrant deadline <<< "${tasks[$task_id]}"
        
        local color=$(get_priority_color "$priority_level")
        
        echo -e "${color}▶ $task_id${NC}: $title"
        echo "  状态: $status | 进度: ${progress}% | 优先级: ${color}$priority_level${NC} (${score}分)"
        echo "  象限: $quadrant"
        if [ "$deadline" != "null" ] && [ -n "$deadline" ]; then
            echo "  截止: $deadline"
        fi
        echo ""
    done
    
    echo -e "${GREEN}=== 已完成任务（最近5个）===${NC}"
    ls "$COMPLETED_DIR"/*.json 2>/dev/null | head -5 | while read file; do
        local task_id=$(jq -r '.task_id' "$file" 2>/dev/null)
        local title=$(jq -r '.title' "$file" 2>/dev/null)
        if [ -n "$task_id" ]; then
            echo "  $task_id: $title"
        fi
    done
}

# 查看任务详情
view_task() {
    local task_id=$1
    local task_file=""
    
    # 查找任务文件
    for dir in "$ACTIVE_DIR" "$COMPLETED_DIR" "$FAILED_DIR"; do
        if [ -f "$dir/$task_id.json" ]; then
            task_file="$dir/$task_id.json"
            break
        fi
    done
    
    if [ -z "$task_file" ]; then
        echo -e "${RED}任务不存在: $task_id${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== 任务详情 ===${NC}"
    jq '.' "$task_file"
}

# 查看优先级报告
priority_report() {
    local task_id=$1
    
    local task_file="$ACTIVE_DIR/$task_id.json"
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}任务不存在或不是活跃任务: $task_id${NC}"
        return 1
    fi
    
    # 提取优先级信息
    local urgency=$(jq -r '.priority_metrics.urgency' "$task_file")
    local importance=$(jq -r '.priority_metrics.importance' "$task_file")
    local complexity=$(jq -r '.priority_metrics.complexity' "$task_file")
    local dependency=$(jq -r '.priority_metrics.dependency' "$task_file")
    local deadline=$(jq -r '.deadline' "$task_file")
    local created_at=$(jq -r '.created_at' "$task_file")
    
    # 使用优先级计算器生成报告
    if [ -f "$PRIORITY_CALCULATOR" ]; then
        "$PRIORITY_CALCULATOR" report $urgency $importance $complexity $dependency "$deadline" "$created_at"
    else
        echo -e "${RED}优先级计算器未找到${NC}"
        echo "请先部署 priority-calculator.sh"
    fi
}

# 四象限看板
quadrant_board() {
    echo -e "${BLUE}=== 四象限任务看板 ===${NC}"
    echo ""
    
    # 定义四个象限的数组
    declare -a quadrant1 quadrant2 quadrant3 quadrant4
    
    # 遍历所有活跃任务
    for file in "$ACTIVE_DIR"/*.json; do
        if [ -f "$file" ]; then
            local task_id=$(jq -r '.task_id' "$file" 2>/dev/null)
            local title=$(jq -r '.title' "$file" 2>/dev/null)
            local quadrant=$(jq -r '.priority_metrics.quadrant' "$file" 2>/dev/null)
            
            if [ -n "$task_id" ]; then
                case "$quadrant" in
                    "第一象限（紧急且重要）")
                        quadrant1+=("$task_id: $title")
                        ;;
                    "第二象限（重要但不紧急）")
                        quadrant2+=("$task_id: $title")
                        ;;
                    "第三象限（紧急但不重要）")
                        quadrant3+=("$task_id: $title")
                        ;;
                    "第四象限（不紧急不重要）")
                        quadrant4+=("$task_id: $title")
                        ;;
                esac
            fi
        fi
    done
    
    # 显示四象限
    echo -e "${RED}第一象限：紧急且重要（立即执行）${NC}"
    for item in "${quadrant1[@]}"; do
        echo "  • $item"
    done
    [ ${#quadrant1[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${ORANGE}第二象限：重要但不紧急（计划执行）${NC}"
    for item in "${quadrant2[@]}"; do
        echo "  • $item"
    done
    [ ${#quadrant2[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${YELLOW}第三象限：紧急但不重要（委托执行）${NC}"
    for item in "${quadrant3[@]}"; do
        echo "  • $item"
    done
    [ ${#quadrant3[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${GREEN}第四象限：不紧急不重要（稍后执行）${NC}"
    for item in "${quadrant4[@]}"; do
        echo "  • $item"
    done
    [ ${#quadrant4[@]} -eq 0 ] && echo "  （无任务）"
}

# 帮助信息
show_help() {
    echo -e "${BLUE}惠迈任务管理器