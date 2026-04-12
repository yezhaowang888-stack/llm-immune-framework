#!/bin/bash
# 实时监控小迈-云回复

echo "开始实时监控小迈-云回复..."
echo "监控文件: /Users/mac/.openclaw/workspace/TO小迈-云-紧急任务.md"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

LAST_CONTENT=""
CHECK_COUNT=0

while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 检查文件是否存在
    if [ ! -f "/Users/mac/.openclaw/workspace/TO小迈-云-紧急任务.md" ]; then
        echo "❌ [$CURRENT_TIME] 文件不存在!"
        sleep 10
        continue
    fi
    
    # 获取当前内容
    CURRENT_CONTENT=$(tail -20 "/Users/mac/.openclaw/workspace/TO小迈-云-紧急任务.md")
    
    # 检查是否有变化
    if [ "$CURRENT_CONTENT" != "$LAST_CONTENT" ]; then
        echo "✅ [$CURRENT_TIME] 文件有更新! (检查次数: $CHECK_COUNT)"
        echo "=== 最新内容 ==="
        tail -10 "/Users/mac/.openclaw/workspace/TO小迈-云-紧急任务.md"
        echo "================"
        
        # 检查是否包含小迈-云回复
        if echo "$CURRENT_CONTENT" | grep -q "小迈-云回复"; then
            echo "🎉 检测到小迈-云回复!"
            echo "开始任务监督..."
            break
        fi
        
        LAST_CONTENT="$CURRENT_CONTENT"
    else
        if [ $((CHECK_COUNT % 6)) -eq 0 ]; then
            echo "⏳ [$CURRENT_TIME] 等待更新... (已检查 $CHECK_COUNT 次)"
        fi
    fi
    
    # 计算剩余时间
    DEADLINE_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "2026-04-02T15:00:00" +%s 2>/dev/null)
    if [ -n "$DEADLINE_TS" ]; then
        NOW_TS=$(date +%s)
        REMAINING=$((DEADLINE_TS - NOW_TS))
        
        if [ $REMAINING -le 0 ]; then
            echo "🔴 已超过15:00截止时间!"
            break
        elif [ $REMAINING -lt 1800 ]; then
            REMAINING_MIN=$((REMAINING / 60))
            echo "⚠️  距离15:00只剩 ${REMAINING_MIN} 分钟!"
        fi
    fi
    
    sleep 10  # 每10秒检查一次
done

echo ""
echo "监控结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "总检查次数: $CHECK_COUNT"