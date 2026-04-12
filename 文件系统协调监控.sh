#!/bin/bash
# 文件系统协调监控脚本

TASK_FILE="/Users/mac/.openclaw/workspace/TO小迈-云-紧急任务.md"
LOG_FILE="/Users/mac/.openclaw/workspace/memory/文件协调日志.md"
CHECK_INTERVAL=300  # 5分钟检查一次

echo "开始文件系统协调监控 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "监控文件: $TASK_FILE"
echo "检查间隔: ${CHECK_INTERVAL}秒"
echo ""

# 创建日志文件
mkdir -p "$(dirname "$LOG_FILE")"
echo "# 文件系统协调监控日志
开始时间: $(date '+%Y-%m-%d %H:%M:%S')
监控文件: $TASK_FILE
---" > "$LOG_FILE"

check_count=0
last_modified=""

while true; do
    check_count=$((check_count + 1))
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "=== 第${check_count}次检查 ($current_time) ==="
    
    # 检查文件是否存在
    if [ ! -f "$TASK_FILE" ]; then
        echo "❌ 任务文件不存在!"
        echo "🕒 $current_time: 任务文件被删除或移动" >> "$LOG_FILE"
        break
    fi
    
    # 检查文件修改时间
    current_modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$TASK_FILE")
    
    if [ "$last_modified" != "$current_modified" ]; then
        if [ -n "$last_modified" ]; then
            echo "✅ 文件已修改! 上次修改: $last_modified, 当前: $current_modified"
            echo "🔄 $current_time: 文件被修改 (从 $last_modified 到 $current_modified)" >> "$LOG_FILE"
            
            # 检查是否有小迈-云的回复
            if grep -q "小迈-云回复" "$TASK_FILE"; then
                echo "🎉 检测到小迈-云回复!"
                echo "📋 回复内容:"
                grep -A 10 "小迈-云回复" "$TASK_FILE"
                echo "✅ $current_time: 检测到小迈-云回复" >> "$LOG_FILE"
                
                # 提取回复信息
                REPLY_TIME=$(grep -A 1 "小迈-云回复" "$TASK_FILE" | grep "回复时间" | cut -d: -f2- | xargs)
                CONFIRM_STATUS=$(grep -A 2 "小迈-云回复" "$TASK_FILE" | grep "确认状态" | cut -d: -f2- | xargs)
                
                echo "回复时间: $REPLY_TIME"
                echo "确认状态: $CONFIRM_STATUS"
                
                if [ "$CONFIRM_STATUS" = "收到" ]; then
                    echo "🎯 任务确认收到，开始监督执行..."
                    break
                fi
            fi
        fi
        last_modified="$current_modified"
    else
        echo "⏳ 文件未修改 (最后修改: $current_modified)"
        echo "⏳ $current_time: 文件未修改" >> "$LOG_FILE"
    fi
    
    # 显示文件最后几行
    echo "📄 文件最后内容:"
    tail -5 "$TASK_FILE"
    echo ""
    
    # 计算剩余时间
    deadline_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "2026-04-02T15:00:00" +%s 2>/dev/null)
    if [ -n "$deadline_ts" ]; then
        now_ts=$(date +%s)
        remaining=$((deadline_ts - now_ts))
        
        if [ $remaining -gt 0 ]; then
            remaining_min=$((remaining / 60))
            echo "⏰ 距离15:00截止还有: ${remaining_min}分钟"
        else
            echo "🔴 已超过15:00截止时间!"
            break
        fi
    fi
    
    # 等待下一次检查
    echo "等待 ${CHECK_INTERVAL} 秒后再次检查..."
    echo "---"
    sleep $CHECK_INTERVAL
done

echo ""
echo "=== 监控结束 ==="
echo "总检查次数: $check_count"
echo "最后文件状态:"
ls -la "$TASK_FILE"
echo ""
echo "日志文件: $LOG_FILE"