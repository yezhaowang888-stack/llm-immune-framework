#!/bin/bash
# 惠迈任务优先级计算器 v1.0
# 基于四维度模型计算任务优先级

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 权重配置
URGENCY_WEIGHT=0.35    # 紧急度权重
IMPORTANCE_WEIGHT=0.40 # 重要度权重
COMPLEXITY_WEIGHT=-0.15 # 复杂度权重（负值，复杂度越高优先级越低）
DEPENDENCY_WEIGHT=0.10 # 依赖度权重

# 计算优先级分数
calculate_priority_score() {
    local urgency=$1
    local importance=$2
    local complexity=$3
    local dependency=$4
    
    # 验证输入范围
    for var in urgency importance complexity dependency; do
        eval "value=\$$var"
        if [ "$value" -lt 1 ] || [ "$value" -gt 10 ]; then
            echo "错误: $var 必须在1-10之间" >&2
            return 1
        fi
    done
    
    # 计算公式: 分数 = (紧急度×0.35) + (重要度×0.40) - (复杂度×0.15) + (依赖度×0.10)
    local score=$(echo "scale=2; ($urgency * $URGENCY_WEIGHT) + ($importance * $IMPORTANCE_WEIGHT) + ($complexity * $COMPLEXITY_WEIGHT) + ($dependency * $DEPENDENCY_WEIGHT)" | bc)
    
    echo "$score"
}

# 根据分数确定优先级级别
get_priority_level() {
    local score=$1
    
    if [ $(echo "$score >= 8.1" | bc) -eq 1 ]; then
        echo "紧急"
    elif [ $(echo "$score >= 6.1" | bc) -eq 1 ]; then
        echo "高"
    elif [ $(echo "$score >= 3.1" | bc) -eq 1 ]; then
        echo "中"
    else
        echo "低"
    fi
}

# 获取优先级颜色
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

# 计算四象限
calculate_quadrant() {
    local urgency=$1
    local importance=$2
    
    if [ $urgency -ge 7 ] && [ $importance -ge 7 ]; then
        echo "第一象限（紧急且重要）"
    elif [ $urgency -lt 7 ] && [ $importance -ge 7 ]; then
        echo "第二象限（重要但不紧急）"
    elif [ $urgency -ge 7 ] && [ $importance -lt 7 ]; then
        echo "第三象限（紧急但不重要）"
    else
        echo "第四象限（不紧急不重要）"
    fi
}

# 计算时间压力分数
calculate_time_pressure() {
    local deadline=$1  # ISO格式截止时间
    local created_at=$2 # ISO格式创建时间
    
    # 转换为时间戳
    local deadline_ts=$(date -d "$deadline" +%s 2>/dev/null)
    local created_ts=$(date -d "$created_at" +%s 2>/dev/null)
    local now_ts=$(date +%s)
    
    if [ -z "$deadline_ts" ] || [ -z "$created_ts" ]; then
        echo "0"
        return
    fi
    
    # 计算总时间窗口和剩余时间
    local total_hours=$(( (deadline_ts - created_ts) / 3600 ))
    local remaining_hours=$(( (deadline_ts - now_ts) / 3600 ))
    
    if [ $total_hours -le 0 ] || [ $remaining_hours -le 0 ]; then
        echo "10" # 已经过期或时间窗口为0
        return
    fi
    
    # 计算时间压力：剩余时间比例越小，压力越大
    local time_ratio=$(echo "scale=2; $remaining_hours / $total_hours" | bc)
    
    # 映射到1-10分：比例越小，分数越高
    if [ $(echo "$time_ratio <= 0.1" | bc) -eq 1 ]; then
        echo "10"
    elif [ $(echo "$time_ratio <= 0.2" | bc) -eq 1 ]; then
        echo "9"
    elif [ $(echo "$time_ratio <= 0.3" | bc) -eq 1 ]; then
        echo "8"
    elif [ $(echo "$time_ratio <= 0.4" | bc) -eq 1 ]; then
        echo "7"
    elif [ $(echo "$time_ratio <= 0.5" | bc) -eq 1 ]; then
        echo "6"
    elif [ $(echo "$time_ratio <= 0.6" | bc) -eq 1 ]; then
        echo "5"
    elif [ $(echo "$time_ratio <= 0.7" | bc) -eq 1 ]; then
        echo "4"
    elif [ $(echo "$time_ratio <= 0.8" | bc) -eq 1 ]; then
        echo "3"
    elif [ $(echo "$time_ratio <= 0.9" | bc) -eq 1 ]; then
        echo "2"
    else
        echo "1"
    fi
}

# 生成优先级报告
generate_priority_report() {
    local urgency=$1
    local importance=$2
    local complexity=$3
    local dependency=$4
    local deadline=$5
    local created_at=$6
    
    # 计算各项指标
    local score=$(calculate_priority_score $urgency $importance $complexity $dependency)
    local level=$(get_priority_level $score)
    local color=$(get_priority_color $level)
    local quadrant=$(calculate_quadrant $urgency $importance)
    local time_pressure=$(calculate_time_pressure "$deadline" "$created_at")
    
    # 计算剩余时间
    local deadline_ts=$(date -d "$deadline" +%s 2>/dev/null)
    local now_ts=$(date +%s)
    local remaining_hours=0
    if [ -n "$deadline_ts" ]; then
        remaining_hours=$(( (deadline_ts - now_ts) / 3600 ))
    fi
    
    # 输出报告
    echo -e "${BLUE}=== 任务优先级分析报告 ===${NC}"
    echo ""
    echo -e "${BLUE}维度评分（1-10分）：${NC}"
    echo "  紧急度: $urgency/10"
    echo "  重要度: $importance/10"
    echo "  复杂度: $complexity/10"
    echo "  依赖度: $dependency/10"
    echo ""
    echo -e "${BLUE}计算结果：${NC}"
    echo -e "  优先级分数: $score"
    echo -e "  优先级级别: ${color}$level${NC}"
    echo "  四象限: $quadrant"
    echo ""
    echo -e "${BLUE}时间分析：${NC}"
    echo "  创建时间: $created_at"
    echo "  截止时间: $deadline"
    echo "  剩余时间: ${remaining_hours}小时"
    echo "  时间压力: $time_pressure/10"
    echo ""
    
    # 建议
    echo -e "${BLUE}执行建议：${NC}"
    case $quadrant in
        "第一象限（紧急且重要）")
            echo "  ✅ 立即执行：这是最高优先级的任务"
            echo "  📋 需要集中资源，尽快完成"
            ;;
        "第二象限（重要但不紧急）")
            echo "  ✅ 计划执行：制定详细计划，按时完成"
            echo "  📋 避免拖延，这是长期重要的任务"
            ;;
        "第三象限（紧急但不重要）")
            echo "  ⚠️ 委托执行：考虑是否可以委托给他人"
            echo "  📋 快速处理，避免占用核心资源"
            ;;
        "第四象限（不紧急不重要）")
            echo "  ⏳ 稍后执行：在空闲时间处理"
            echo "  📋 可以批量处理或自动化"
            ;;
    esac
}

# 交互式优先级评估
interactive_assessment() {
    echo -e "${BLUE}=== 任务优先级交互式评估 ===${NC}"
    echo ""
    
    # 获取紧急度
    while true; do
        read -p "紧急度（1-10分，10分最紧急）: " urgency
        if [[ $urgency =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 获取重要度
    while true; do
        read -p "重要度（1-10分，10分最重要）: " importance
        if [[ $importance =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 获取复杂度
    while true; do
        read -p "复杂度（1-10分，10分最复杂）: " complexity
        if [[ $complexity =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 获取依赖度
    while true; do
        read -p "依赖度（1-10分，10分依赖最强）: " dependency
        if [[ $dependency =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo "请输入1-10之间的数字"
        fi
    done
    
    # 获取截止时间
    read -p "截止时间（YYYY-MM-DD HH:MM，留空则无）: " deadline_input
    if [ -z "$deadline_input" ]; then
        deadline=""
    else
        deadline="$deadline_input"
    fi
    
    # 生成报告
    echo ""
    generate_priority_report $urgency $importance $complexity $dependency "$deadline" "$(date -Iseconds)"
}

# 主函数
main() {
    case $1 in
        "calc")
            shift
            if [ $# -eq 4 ]; then
                score=$(calculate_priority_score $1 $2 $3 $4)
                level=$(get_priority_level $score)
                color=$(get_priority_color $level)
                echo -e "优先级分数: $score"
                echo -e "优先级级别: ${color}$level${NC}"
            else
                echo "用法: $0 calc <紧急度> <重要度> <复杂度> <依赖度>"
                echo "示例: $0 calc 8 9 6 7"
            fi
            ;;
        "report")
            shift
            if [ $# -eq 6 ]; then
                generate_priority_report $1 $2 $3 $4 "$5" "$6"
            else
                echo "用法: $0 report <紧急度> <重要度> <复杂度> <依赖度> <截止时间> <创建时间>"
                echo "示例: $0 report 8 9 6 7 '2026-04-03 18:00:00' '2026-04-01T08:47:44+08:00'"
            fi
            ;;
        "interactive")
            interactive_assessment
            ;;
        "help"|*)
            echo -e "${BLUE}惠迈任务优先级计算器 使用说明${NC}"
            echo "命令:"
            echo "  calc <紧急度> <重要度> <复杂度> <依赖度>    计算优先级分数"
            echo "  report <紧急度> <重要度> <复杂度> <依赖度> <截止时间> <创建时间>  生成完整报告"
            echo "  interactive                              交互式优先级评估"
            echo "  help                                     显示帮助"
            echo ""
            echo "评分标准（1-10分）:"
            echo "  紧急度: 1-3(本月) 4-6(本周) 7-8(3天) 9-10(24小时)"
            echo "  重要度: 1-3(优化) 4-6(增强) 7-8(核心) 9-10(关键)"
            echo "  复杂度: 1-3(简单) 4-6(中等) 7-8(复杂) 9-10(极复杂)"
            echo "  依赖度: 1-3(独立) 4-6(少量) 7-8(强依赖) 9-10(关键路径)"
            ;;
    esac
}

# 检查bc是否安装
if ! command -v bc &> /dev/null; then
    echo -e "${RED}错误: bc命令未安装，请先安装: apt-get install bc 或 yum install bc${NC}"
    exit 1
fi

# 执行主函数
main "$@"