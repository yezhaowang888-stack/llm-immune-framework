#!/bin/bash
# 执行者智能体调用包装器

EXECUTOR_HOME="/Users/mac/.openclaw/workspace/executor-agent"
CORE_SCRIPT="$EXECUTOR_HOME/scripts/executor-core.sh"

echo "🦾 执行者智能体调用器"
echo "版本: 1.0"
echo "时间: $(date)"
echo ""

if [ $# -eq 0 ]; then
    echo "用法:"
    echo "  $0 <任务ID>           # 执行指定任务"
    echo "  $0 run '<命令>'       # 直接执行SSH命令"
    echo "  $0 status            # 查看状态"
    echo "  $0 logs              # 查看日志"
    echo "  $0 test              # 测试连接"
    echo ""
    echo "示例:"
    echo "  $0 test"
    echo "  $0 run 'date'"
    echo "  $0 run 'docker ps | grep mysql'"
    exit 1
fi

case "$1" in
    test)
        echo "=== 连接测试 ==="
        "$CORE_SCRIPT" "测试连接"
        ;;
    run)
        if [ $# -lt 2 ]; then
            echo "错误: 需要提供命令"
            echo "示例: $0 run 'date'"
            exit 1
        fi
        shift
        echo "=== 执行命令 ==="
        echo "命令: $*"
        "$CORE_SCRIPT" "$@"
        ;;
    status)
        echo "=== 执行者状态 ==="
        echo "目录: $EXECUTOR_HOME"
        echo "任务数量: $(ls -1 "$EXECUTOR_HOME/tasks/"*.json 2>/dev/null | wc -l)"
        echo "日志数量: $(ls -1 "$EXECUTOR_HOME/logs/"*.log 2>/dev/null | wc -l)"
        echo "最后日志: $(ls -t "$EXECUTOR_HOME/logs/"*.log 2>/dev/null | head -1)"
        ;;
    logs)
        echo "=== 执行日志 ==="
        ls -lt "$EXECUTOR_HOME/logs/"*.log 2>/dev/null | head -10
        echo ""
        echo "查看最新日志: tail -f $(ls -t "$EXECUTOR_HOME/logs/"*.log 2>/dev/null | head -1)"
        ;;
    *)
        # 假设是任务ID
        TASK_ID="$1"
        echo "=== 执行任务: $TASK_ID ==="
        "$CORE_SCRIPT" "$TASK_ID"
        ;;
esac