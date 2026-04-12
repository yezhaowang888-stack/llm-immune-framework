#!/bin/bash
# 惠迈进度汇报系统 v1.0
# 集成：日报生成 + 周报系统 + 自动提醒

TASKS_DIR="/root/huimai-openclaw/tasks"
ACTIVE_DIR="$TASKS_DIR/active"
COMPLETED_DIR="$TASKS_DIR/completed"
REPORTS_DIR="$TASKS_DIR/reports"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 初始化
init() {
    mkdir -p "$REPORTS_DIR"/{daily,weekly,monthly}
    mkdir -p "$TASKS_DIR"/reminders
    echo -e "${GREEN}进度汇报系统初始化完成${NC}"
}

# 生成日报
generate_daily_report() {
    local date=$(date +%Y-%m-%d)
    local report_file="$REPORTS_DIR/daily/report-$date.md"
    
    echo "# 惠迈工作日报 - $date" > "$report_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "" >> "$report_file"
    
    # 今日完成的任务
    echo "## ✅ 今日完成" >> "$report_file"
    local completed_today=0
    for file in "$COMPLETED_DIR"/*.json; do
        [ -f "$file" ] || continue
        completed_date=$(jq -r '.completed_at' "$file" | cut -d'T' -f1)
        if [ "$completed_date" = "$date" ]; then
            task_id=$(jq -r '.task_id' "$file")
            title=$(jq -r '.title' "$file")
            echo "- $task_id: $title" >> "$report_file"
            ((completed_today++))
        fi
    done
    [ $completed_today -eq 0 ] && echo "（无）" >> "$report_file"
    echo "" >> "$report_file"
    
    # 进行中的任务
    echo "## 🔄 进行中任务" >> "$report_file"
    local active_count=0
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        task_id=$(jq -r '.task_id' "$file")
        title=$(jq -r '.title' "$file")
        status=$(jq -r '.status' "$file")
        progress=$(jq -r '.progress' "$file")
        priority=$(jq -r '.priority_metrics.level // "中"' "$file")
        deadline=$(jq -r '.deadline' "$file")
        
        echo "- **$task_id**: $title" >> "$report_file"
        echo "  - 状态: $status | 进度: ${progress}% | 优先级: $priority" >> "$report_file"
        [ "$deadline" != "null" ] && [ -n "$deadline" ] && echo "  - 截止: $deadline" >> "$report_file"
        echo "" >> "$report_file"
        ((active_count++))
    done
    [ $active_count -eq 0 ] && echo "（无）" >> "$report_file"
    echo "" >> "$report_file"
    
    # 优先级分布
    echo "## 📊 优先级分布" >> "$report_file"
    declare -A priority_count
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        priority=$(jq -r '.priority_metrics.level // "中"' "$file")
        priority_count["$priority"]=$((priority_count["$priority"] + 1))
    done
    
    for level in "紧急" "高" "中" "低"; do
        count=${priority_count["$level"]:-0}
        [ $count -gt 0 ] && echo "- $level: $count个任务" >> "$report_file"
    done
    echo "" >> "$report_file"
    
    # 即将到期的任务（3天内）
    echo "## ⏰ 即将到期（3天内）" >> "$report_file"
    local upcoming_count=0
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        deadline=$(jq -r '.deadline' "$file")
        [ "$deadline" = "null" ] || [ -z "$deadline" ] && continue
        
        deadline_ts=$(date -d "$deadline" +%s 2>/dev/null)
        [ -z "$deadline_ts" ] && continue
        
        now_ts=$(date +%s)
        days_left=$(( (deadline_ts - now_ts) / 86400 ))
        
        if [ $days_left -ge 0 ] && [ $days_left -le 3 ]; then
            task_id=$(jq -r '.task_id' "$file")
            title=$(jq -r '.title' "$file")
            progress=$(jq -r '.progress' "$file")
            echo "- $task_id: $title (剩余${days_left}天，进度${progress}%)" >> "$report_file"
            ((upcoming_count++))
        fi
    done
    [ $upcoming_count -eq 0 ] && echo "（无）" >> "$report_file"
    echo "" >> "$report_file"
    
    # 问题和风险
    echo "## ⚠️ 需要注意" >> "$report_file"
    echo "1. 进度滞后的任务" >> "$report_file"
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        progress=$(jq -r '.progress' "$file")
        deadline=$(jq -r '.deadline' "$file")
        
        if [ "$progress" -lt 50 ] && [ "$deadline" != "null" ]; then
            deadline_ts=$(date -d "$deadline" +%s 2>/dev/null)
            [ -z "$deadline_ts" ] && continue
            
            now_ts=$(date +%s)
            days_left=$(( (deadline_ts - now_ts) / 86400 ))
            
            if [ $days_left -le 2 ]; then
                task_id=$(jq -r '.task_id' "$file")
                title=$(jq -r '.title' "$file")
                echo "   - $task_id: $title (进度${progress}%，剩余${days_left}天)" >> "$report_file"
            fi
        fi
    done
    echo "" >> "$report_file"
    
    # 明日计划
    echo "## 📅 明日计划" >> "$report_file"
    echo "1. 继续处理进行中的高优先级任务" >> "$report_file"
    echo "2. 检查即将到期的任务" >> "$report_file"
    echo "3. 根据优先级分配工作时间" >> "$report_file"
    
    echo -e "${GREEN}日报生成完成: $report_file${NC}"
    echo "报告摘要:"
    echo "  - 今日完成: $completed_today个任务"
    echo "  - 进行中: $active_count个任务"
    echo "  - 即将到期: $upcoming_count个任务"
}

# 生成周报
generate_weekly_report() {
    local week_start=$(date -d "last monday" +%Y-%m-%d)
    local week_end=$(date -d "this sunday" +%Y-%m-%d)
    local report_file="$REPORTS_DIR/weekly/report-$week_start-to-$week_end.md"
    
    echo "# 惠迈工作周报 - $week_start 至 $week_end" > "$report_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "" >> "$report_file"
    
    # 本周完成
    echo "## ✅ 本周完成" >> "$report_file"
    local week_completed=0
    for file in "$COMPLETED_DIR"/*.json; do
        [ -f "$file" ] || continue
        completed_date=$(jq -r '.completed_at' "$file" | cut -d'T' -f1)
        if [[ "$completed_date" > "$week_start" ]] || [[ "$completed_date" = "$week_start" ]]; then
            if [[ "$completed_date" < "$week_end" ]] || [[ "$completed_date" = "$week_end" ]]; then
                task_id=$(jq -r '.task_id' "$file")
                title=$(jq -r '.title' "$file")
                completed_at=$(jq -r '.completed_at' "$file")
                echo "- $task_id: $title (完成于: $completed_at)" >> "$report_file"
                ((week_completed++))
            fi
        fi
    done
    [ $week_completed -eq 0 ] && echo "（无）" >> "$report_file"
    echo "" >> "$report_file"
    
    # 任务统计
    echo "## 📈 任务统计" >> "$report_file"
    total_tasks=$(ls "$ACTIVE_DIR"/*.json 2>/dev/null | wc -l)
    completed_tasks=$(ls "$COMPLETED_DIR"/*.json 2>/dev/null | wc -l)
    echo "- 活跃任务: $total_tasks个" >> "$report_file"
    echo "- 已完成任务: $completed_tasks个" >> "$report_file"
    echo "- 本周完成: $week_completed个" >> "$report_file"
    echo "" >> "$report_file"
    
    # 优先级分析
    echo "## 🎯 优先级分析" >> "$report_file"
    declare -A priority_stats
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        priority=$(jq -r '.priority_metrics.level // "中"' "$file")
        priority_stats["$priority"]=$((priority_stats["$priority"] + 1))
    done
    
    echo "当前任务优先级分布:" >> "$report_file"
    for level in "紧急" "高" "中" "低"; do
        count=${priority_stats["$level"]:-0}
        [ $count -gt 0 ] && {
            percentage=$((count * 100 / (total_tasks > 0 ? total_tasks : 1)))
            echo "- $level: $count个 (${percentage}%)" >> "$report_file"
        }
    done
    echo "" >> "$report_file"
    
    # 进度分析
    echo "## 📊 进度分析" >> "$report_file"
    echo "任务进度分布:" >> "$report_file"
    declare -A progress_stats
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        progress=$(jq -r '.progress' "$file")
        if [ $progress -lt 25 ]; then key="0-25%"
        elif [ $progress -lt 50 ]; then key="25-50%"
        elif [ $progress -lt 75 ]; then key="50-75%"
        else key="75-100%"; fi
        progress_stats["$key"]=$((progress_stats["$key"] + 1))
    done
    
    for range in "0-25%" "25-50%" "50-75%" "75-100%"; do
        count=${progress_stats["$range"]:-0}
        [ $count -gt 0 ] && {
            percentage=$((count * 100 / (total_tasks > 0 ? total_tasks : 1)))
            echo "- $range: $count个 (${percentage}%)" >> "$report_file"
        }
    done
    echo "" >> "$report_file"
    
    # 下周重点
    echo "## 🎯 下周重点" >> "$report_file"
    echo "1. 完成高优先级任务" >> "$report_file"
    echo "2. 处理即将到期的任务" >> "$report_file"
    echo "3. 推进进度滞后的任务" >> "$report_file"
    echo "4. 根据优先级重新评估任务分配" >> "$report_file"
    
    echo -e "${GREEN}周报生成完成: $report_file${NC}"
}

# 检查提醒
check_reminders() {
    echo -e "${CYAN}=== 任务提醒检查 ===${NC}"
    
    local today=$(date +%Y-%m-%d)
    local reminder_file="$TASKS_DIR/reminders/$today.txt"
    
    # 检查即将到期的任务
    echo "即将到期的任务:" > "$reminder_file"
    local urgent_count=0
    
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        
        task_id=$(jq -r '.task_id' "$file")
        title=$(jq -r '.title' "$file")
        deadline=$(jq -r '.deadline' "$file")
        progress=$(jq -r '.progress' "$file")
        priority=$(jq -r '.priority_metrics.level // "中"' "$file")
        
        [ "$deadline" = "null" ] || [ -z "$deadline" ] && continue
        
        deadline_ts=$(date -d "$deadline" +%s 2>/dev/null)
        [ -z "$deadline_ts" ] && continue
        
        now_ts=$(date +%s)
        hours_left=$(( (deadline_ts - now_ts) / 3600 ))
        
        # 24小时内到期的任务
        if [ $hours_left -ge 0 ] && [ $hours_left -le 24 ]; then
            echo "🔴 $task_id: $title" >> "$reminder_file"
            echo "   剩余: ${hours_left}小时 | 进度: ${progress}% | 优先级: $priority" >> "$reminder_file"
            ((urgent_count++))
        # 3天内到期的任务
        elif [ $hours_left -ge 0 ] && [ $hours_left -le 72 ]; then
            echo "🟠 $task_id: $title" >> "$reminder_file"
            echo "   剩余: $((hours_left/24))天 | 进度: ${progress}% | 优先级: $priority" >> "$reminder_file"
        fi
    done
    
    # 检查进度滞后的任务
    echo "" >> "$reminder_file"
    echo "进度滞后的任务:" >> "$reminder_file"
    local lagging_count=0
    
    for file in "$ACTIVE_DIR"/*.json; do
        [ -f "$file" ] || continue
        
        task_id=$(jq -r '.task_id' "$file")
        title=$(jq -r '.title' "$file")
        progress=$(jq -r '.progress' "$file")
        created_at=$(jq -r '.created_at' "$file")
        
        # 创建超过3天但进度低于30%
        created_ts=$(date -d "$created_at" +%s 2>/dev/null)
        [ -z "$created_ts" ] && continue
        
        now_ts=$(date +%s)
        days_old=$(( (now_ts - created_ts) / 86400 ))
        
        if [ $days_old -ge 3 ] && [ $progress -lt 30 ]; then
            echo "⚠️ $task_id: $title" >> "$reminder_file"
            echo "   已进行: ${days_old}天 | 进度: ${progress}%" >> "$reminder_file"
            ((lagging_count++))
        fi
    done
    
    # 显示提醒
    if [ $urgent_count -gt 0 ] || [ $lagging_count -gt 0 ]; then
        cat "$reminder_file"
        echo -e "${YELLOW}提醒已保存到: $reminder_file${NC}"
    else
        echo -e "${GREEN}✅ 无紧急提醒${NC}"
        echo "所有任务都在正常进行中" >> "$reminder_file"
    fi
}

# 主菜单
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}=== 惠迈进度汇报系统 ===${NC}"
        echo "1. 生成今日日报"
        echo "2. 生成本周周报"
        echo "3. 检查任务提醒"
        echo "4. 初始化系统"
        echo "5. 查看今日报告"
        echo "6. 退出"
        echo ""
        
        read -p "请选择 (1-6): " choice
        
        case $choice in
            1)
                generate_daily_report
                ;;
            2)
                generate_weekly_report
                ;;
            3)
                check_reminders
                ;;
            4)
                init
                ;;
            5)
                today=$(date +%Y-%m-%d)
                report_file="$REPORTS_DIR/daily/report-$today.md"
                if [ -f "$report_file" ]; then
                    echo ""
                    cat "$report_file"
                else
                    echo -e "${YELLOW}今日报告尚未生成${NC}"
                    read -p "是否现在生成？(y/n): " generate_now
                    [[ $generate_now =~ ^[Yy]$ ]] && generate_daily_report
                fi
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
check_deps() {
