#!/bin/bash

# Termius通讯日志记录脚本
# 记录所有Termius通讯活动

LOG_FILE="/Users/mac/.openclaw/workspace/logs/termius_communications.log"
BACKUP_DIR="/Users/mac/.openclaw/workspace/backup"

# 确保日志文件存在
touch "$LOG_FILE"

log_message() {
    local type=$1
    local content=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 彩色输出到终端
    case $type in
        "SEND") echo -e "\033[34m[$timestamp] [$type] $content\033[0m" ;;
        "RECEIVE") echo -e "\033[32m[$timestamp] [$type] $content\033[0m" ;;
        "SUCCESS") echo -e "\033[32m[$timestamp] [$type] $content\033[0m" ;;
        "ERROR") echo -e "\033[31m[$timestamp] [$type] $content\033[0m" ;;
        "WARNING") echo -e "\033[33m[$timestamp] [$type] $content\033[0m" ;;
        *) echo "[$timestamp] [$type] $content" ;;
    esac
    
    # 写入日志文件（无颜色）
    echo "[$timestamp] [$type] $content" >> "$LOG_FILE"
}

# 自动备份旧日志
backup_old_logs() {
    local log_size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    
    # 如果日志文件大于10MB，进行备份
    if [ "$log_size" -gt 10485760 ]; then  # 10MB = 10*1024*1024
        local backup_file="$BACKUP_DIR/termius_log_$(date '+%Y%m%d_%H%M%S').log"
        cp "$LOG_FILE" "$backup_file"
        gzip "$backup_file"
        
        # 清空当前日志文件
        > "$LOG_FILE"
        
        log_message "SYSTEM" "日志文件已备份到: ${backup_file}.gz"
        log_message "SYSTEM" "原日志文件已清空"
    fi
}

# 显示日志统计
show_stats() {
    local total_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    local today=$(date '+%Y-%m-%d')
    local today_lines=$(grep "^\[$today" "$LOG_FILE" | wc -l)
    
    echo ""
    echo "=== 日志统计 ==="
    echo "总记录数: $total_lines"
    echo "今日记录: $today_lines"
    echo "日志文件: $LOG_FILE"
    echo "文件大小: $(du -h "$LOG_FILE" | cut -f1)"
    
    # 显示最近错误（如果有）
    local recent_errors=$(grep -i "ERROR" "$LOG_FILE" | tail -3)
    if [ -n "$recent_errors" ]; then
        echo ""
        echo "最近错误:"
        echo "$recent_errors"
    fi
}

# 主函数
main() {
    local action=$1
    local content=$2
    
    # 自动备份检查
    backup_old_logs
    
    case $action in
        "send")
            log_message "SEND" "$content"
            ;;
        "receive")
            log_message "RECEIVE" "$content"
            ;;
        "success")
            log_message "SUCCESS" "$content"
            ;;
        "error")
            log_message "ERROR" "$content"
            ;;
        "warning")
            log_message "WARNING" "$content"
            ;;
        "stats")
            show_stats
            ;;
        "tail")
            tail -20 "$LOG_FILE"
            ;;
        "search")
            grep -i "$content" "$LOG_FILE" | tail -10
            ;;
        *)
            echo "用法: $0 {send|receive|success|error|warning|stats|tail|search} [内容]"
            echo "示例:"
            echo "  $0 send '询问小迈工作情况'"
            echo "  $0 stats"
            echo "  $0 tail"
            echo "  $0 search 'ERROR'"
            ;;
    esac
}

# 执行主函数
main "$@"
