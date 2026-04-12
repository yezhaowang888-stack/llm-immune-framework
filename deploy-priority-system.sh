#!/bin/bash
# 部署优先级管理系统到云服务器

echo "=== 部署惠迈任务优先级管理系统 ==="
echo ""

# 检查是否在任务目录
if [ ! -d "/root/huimai-openclaw/tasks" ]; then
    echo "错误: 任务目录不存在，请先运行 task-manager.sh init"
    exit 1
fi

cd /root/huimai-openclaw/tasks

# 1. 部署优先级计算器
echo "1. 部署优先级计算器..."
cat > priority-calculator.sh << 'EOF'
#!/bin/bash
# 惠迈任务优先级计算器 v1.0

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 计算优先级分数
calculate_priority_score() {
    local u=$1 i=$2 c=$3 d=$4
    echo "scale=2; ($u*0.35) + ($i*0.40) - ($c*0.15) + ($d*0.10)" | bc
}

# 获取优先级级别
get_priority_level() {
    local score=$1
    if [ $(echo "$score >= 8.1" | bc) -eq 1 ]; then echo "紧急"
    elif [ $(echo "$score >= 6.1" | bc) -eq 1 ]; then echo "高"
    elif [ $(echo "$score >= 3.1" | bc) -eq 1 ]; then echo "中"
    else echo "低"; fi
}

# 计算四象限
get_quadrant() {
    local u=$1 i=$2
    if [ $u -ge 7 ] && [ $i -ge 7 ]; then echo "第一象限（紧急且重要）"
    elif [ $u -lt 7 ] && [ $i -ge 7 ]; then echo "第二象限（重要但不紧急）"
    elif [ $u -ge 7 ] && [ $i -lt 7 ]; then echo "第三象限（紧急但不重要）"
    else echo "第四象限（不紧急不重要）"; fi
}

# 主函数
main() {
    case $1 in
        calc)
            if [ $# -eq 5 ]; then
                score=$(calculate_priority_score $2 $3 $4 $5)
                level=$(get_priority_level $score)
                color=$([ "$level" = "紧急" ] && echo $RED || \
                        [ "$level" = "高" ] && echo $ORANGE || \
                        [ "$level" = "中" ] && echo $YELLOW || echo $GREEN)
                echo -e "分数: $score | 级别: ${color}$level${NC}"
            else
                echo "用法: $0 calc <紧急度> <重要度> <复杂度> <依赖度>"
            fi
            ;;
        quadrant)
            if [ $# -eq 3 ]; then
                get_quadrant $2 $3
            else
                echo "用法: $0 quadrant <紧急度> <重要度>"
            fi
            ;;
        *)
            echo "优先级计算器命令:"
            echo "  calc <紧急度> <重要度> <复杂度> <依赖度>  计算优先级"
            echo "  quadrant <紧急度> <重要度>               计算四象限"
            ;;
    esac
}

# 检查bc
if ! command -v bc &> /dev/null; then
    echo "请安装bc: apt-get install bc 或 yum install bc"
    exit 1
fi

main "$@"
EOF

chmod +x priority-calculator.sh
echo "✅ 优先级计算器部署完成"

# 2. 创建优先级评估脚本
echo ""
echo "2. 创建优先级评估脚本..."
cat > priority-assessment.sh << 'EOF'
#!/bin/bash
# 交互式优先级评估脚本

echo "=== 任务优先级评估 ==="
echo "评分标准: 1-10分 (10分最高)"
echo ""

read -p "任务标题: " title
read -p "任务描述: " description

echo ""
echo "请评估以下维度:"

while true; do
    read -p "紧急度 (1-10): " urgency
    [[ $urgency =~ ^[1-9]$|^10$ ]] && break
    echo "请输入1-10的数字"
done

while true; do
    read -p "重要度 (1-10): " importance
    [[ $importance =~ ^[1-9]$|^10$ ]] && break
    echo "请输入1-10的数字"
done

while true; do
    read -p "复杂度 (1-10): " complexity
    [[ $complexity =~ ^[1-9]$|^10$ ]] && break
    echo "请输入1-10的数字"
done

while true; do
    read -p "依赖度 (1-10): " dependency
    [[ $dependency =~ ^[1-9]$|^10$ ]] && break
    echo "请输入1-10的数字"
done

# 计算优先级
score=$(./priority-calculator.sh calc $urgency $importance $complexity $dependency | grep "分数:" | cut -d: -f2 | xargs)
level=$(./priority-calculator.sh calc $urgency $importance $complexity $dependency | grep "级别:" | cut -d: -f2 | xargs)
quadrant=$(./priority-calculator.sh quadrant $urgency $importance)

echo ""
echo "=== 评估结果 ==="
echo "任务: $title"
echo "描述: $description"
echo "优先级分数: $score"
echo "优先级级别: $level"
echo "四象限: $quadrant"
echo ""
echo "维度评分:"
echo "  紧急度: $urgency/10"
echo "  重要度: $importance/10"
echo "  复杂度: $complexity/10"
echo "  依赖度: $dependency/10"

# 建议
echo ""
echo "执行建议:"
case $quadrant in
    "第一象限（紧急且重要）")
        echo "  🔴 立即执行 - 最高优先级，需要立即处理"
        ;;
    "第二象限（重要但不紧急）")
        echo "  🟠 计划执行 - 制定详细计划，避免拖延"
        ;;
    "第三象限（紧急但不重要）")
        echo "  🟡 委托执行 - 考虑委托或快速处理"
        ;;
    "第四象限（不紧急不重要）")
        echo "  🟢 稍后执行 - 在空闲时间处理"
        ;;
esac
EOF

chmod +x priority-assessment.sh
echo "✅ 优先级评估脚本部署完成"

# 3. 更新任务管理脚本（添加优先级支持）
echo ""
echo "3. 更新任务管理脚本..."

# 备份原脚本
if [ -f "task-manager.sh" ]; then
    cp task-manager.sh task-manager.sh.backup
    echo "📋 原脚本已备份为 task-manager.sh.backup"
fi

# 创建增强版任务管理脚本
cat > task-manager-enhanced.sh << 'EOF'
#!/bin/bash
# 惠迈任务管理器（增强版）- 支持优先级管理

TASKS_DIR="/root/huimai-openclaw/tasks"
ACTIVE_DIR="$TASKS_DIR/active"
COMPLETED_DIR="$TASKS_DIR/completed"
FAILED_DIR="$TASKS_DIR/failed"

# 颜色
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取优先级颜色
get_color() {
    case $1 in
        "紧急") echo $RED;;
        "高") echo $ORANGE;;
        "中") echo $YELLOW;;
        "低") echo $GREEN;;
        *) echo $NC;;
    esac
}

# 创建任务（带优先级）
create_priority_task() {
    echo "创建新任务（带优先级评估）"
    echo "=========================="
    
    read -p "任务标题: " title
    read -p "任务描述: " description
    read -p "任务分类 [frontend/backend/database/infrastructure/security]: " category
    category=${category:-general}
    read -p "截止时间 (YYYY-MM-DD HH:MM，可选): " deadline
    read -p "预估工时 (小时): " estimated_hours
    estimated_hours=${estimated_hours:-4}
    read -p "完成标准: " completion_criteria
    
    echo ""
    echo "优先级评估（1-10分）:"
    
    while true; do
        read -p "紧急度: " urgency
        [[ $urgency =~ ^[1-9]$|^10$ ]] && break
        echo "请输入1-10"
    done
    
    while true; do
        read -p "重要度: " importance
        [[ $importance =~ ^[1-9]$|^10$ ]] && break
        echo "请输入1-10"
    done
    
    while true; do
        read -p "复杂度: " complexity
        [[ $complexity =~ ^[1-9]$|^10$ ]] && break
        echo "请输入1-10"
    done
    
    while true; do
        read -p "依赖度: " dependency
        [[ $dependency =~ ^[1-9]$|^10$ ]] && break
        echo "请输入1-10"
    done
    
    # 计算优先级
    score=$(../priority-calculator.sh calc $urgency $importance $complexity $dependency 2>/dev/null | grep "分数:" | cut -d: -f2 | xargs)
    level=$(../priority-calculator.sh calc $urgency $importance $complexity $dependency 2>/dev/null | grep "级别:" | cut -d: -f2 | xargs)
    quadrant=$(../priority-calculator.sh quadrant $urgency $importance)
    
    # 生成任务ID
    task_id="TASK-$(date +%Y%m%d)-$(printf "%03d" $(ls $ACTIVE_DIR/*.json 2>/dev/null | wc -l))"
    
    # 创建任务文件
    cat > "$ACTIVE_DIR/$task_id.json" << TASKEOF
{
  "task_id": "$task_id",
  "title": "$title",
  "description": "$description",
  "category": "$category",
  "assigned_to": "hk-engineer",
  "created_by": "惠迈高级工程师",
  "created_at": "$(date -Iseconds)",
  "deadline": "$deadline",
  "estimated_hours": $estimated_hours,
  "status": "pending",
  "progress": 0,
  "last_updated": "$(date -Iseconds)",
  "notes": ["$(date '+%H:%M'): 任务创建"],
  "completion_criteria": "$completion_criteria",
  "priority_metrics": {
    "urgency": $urgency,
    "importance": $importance,
    "complexity": $complexity,
    "dependency": $dependency,
    "score": $score,
    "level": "$level",
    "quadrant": "$quadrant"
  }
}
TASKEOF
    
    color=$(get_color "$level")
    echo ""
    echo -e "${GREEN}✅ 任务创建成功: $task_id${NC}"
    echo -e "优先级: ${color}$level${NC} (分数: $score)"
    echo "四象限: $quadrant"
}

# 查看优先级看板
view_priority_board() {
    echo "=== 优先级任务看板 ==="
    echo ""
    
    # 按优先级分组
    declare -A urgent high medium low
    
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        task_id=$(jq -r '.task_id' "$file" 2>/dev/null)
        title=$(jq -r '.title' "$file" 2>/dev/null)
        level=$(jq -r '.priority_metrics.level' "$file" 2>/dev/null)
        progress=$(jq -r '.progress' "$file" 2>/dev/null)
        
        case $level in
            "紧急") urgent["$task_id"]="$title (${progress}%)";;
            "高") high["$task_id"]="$title (${progress}%)";;
            "中") medium["$task_id"]="$title (${progress}%)";;
            "低") low["$task_id"]="$title (${progress}%)";;
        esac
    done
    
    # 显示
    echo -e "${RED}🔴 紧急优先级${NC}"
    for id in "${!urgent[@]}"; do echo "  • $id: ${urgent[$id]}"; done
    [ ${#urgent[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${ORANGE}🟠 高优先级${NC}"
    for id in "${!high[@]}"; do echo "  • $id: ${high[$id]}"; done
    [ ${#high[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${YELLOW}🟡 中优先级${NC}"
    for id in "${!medium[@]}"; do echo "  • $id: ${medium[$id]}"; done
    [ ${#medium[@]} -eq 0 ] && echo "  （无任务）"
    echo ""
    
    echo -e "${GREEN}🟢 低优先级${NC}"
    for id in "${!low[@]}"; do echo "  • $id: ${low[$id]}"; done
    [ ${#low[@]} -eq 0 ] && echo "  （无任务）"
}

# 主菜单
main_menu() {
    while true; do
        echo ""
        echo "=== 惠迈任务管理系统 ==="
        echo "1. 创建新任务（带优先级）"
        echo "2. 查看优先级看板"
        echo "3. 列出所有任务"
        echo "4. 更新任务状态"
        echo "5. 运行优先级评估"
        echo "6. 退出"
        echo ""
        
        read -p "请选择 (1-6): " choice
        
        case $choice in
            1)
                create_priority_task
                ;;
            2)
                view_priority_board
                ;;
            3)
                ../task-manager.sh list
                ;;
            4)
                read -p "任务ID: " task_id
                read -p "状态 (in_progress/testing/completed/failed): " status
                read -p "进度 (0-100): " progress
                read -p "备注: " note
                ../task-manager.sh update "$task_id" "$status" "$progress" "$note"
                ;;
            5)
                ../priority-assessment.sh
                ;;
            6)
                echo "退出系统"
                exit 0
                ;;
            *)
                echo "无效选择"
                ;;
        esac
    done
}

# 检查依赖
if [ ! -f "../task-manager.sh" ]; then
    echo "错误: 基础任务管理器未找到"
    exit 1
fi

if [ ! -f "../priority-calculator.sh" ]; then
    echo "错误: 优先级计算器未找到"
    exit 1
fi

main_menu
EOF

chmod +x task-manager-enhanced.sh
echo "✅ 增强版任务管理器部署完成"

# 4. 创建使用指南
echo ""
echo "4. 创建使用指南..."
cat > 优先级系统使用指南.md << 'EOF'
# 惠迈任务优先级管理系统 - 使用指南

## 系统概述
本系统在原有任务管理系统基础上，增加了科学的优先级评估功能，帮助更合理地分配和执行任务。

## 核心组件

### 1. 优先级计算器 (`priority-calculator.sh`)
- 基于四维度模型计算任务优先级
- 输出优先级分数和级别
- 计算四象限分类

### 2. 优先级评估脚本 (`priority-assessment.sh`)
- 交互式优先级评估
- 提供执行建议
- 生成评估报告

### 3. 增强版任务管理器 (`task-manager-enhanced.sh`)
- 集成优先级评估的任务创建
- 优先级看板视图
- 与原有系统兼容

## 使用流程

### 创建带优先级的任务
```bash
cd /root/huimai-openclaw/tasks
./task-manager-enhanced.sh
# 选择1: 创建新任务（带优先级）
```

### 交互式评估任务优先级
```bash
cd /root/huimai-openclaw/tasks
./priority-assessment.sh
```

### 查看优先级看板
```bash
cd /root/huimai-openclaw/tasks
./task-manager-enhanced.sh
# 选择2: 查看优先级看板
```

## 优先级评估维度

### 1. 紧急度 (1-10分)
- 1-3分: 本月内完成即可
- 4-6分: 本周内需要完成
- 7-8分: 3天内需要完成
- 9-10分: 24小时内必须完成

### 2. 重要度 (1-10分)
- 1-3分: 优化改进，不影响核心功能
- 4-6分: 功能增强，提升用户体验
- 7-8分: 核心功能维护，影响部分用户
- 9-10分: 关键系统功能，影响所有用户

### 3. 复杂度 (1-10分)
- 1-3分: 简单配置或小修改
- 4-6分: 中等复杂度功能开发
- 7-8分: 复杂系统集成或重构
- 9