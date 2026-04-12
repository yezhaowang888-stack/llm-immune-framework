#!/bin/bash
# 同步监控脚本

LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
ALERT_FILE="/tmp/sync-alert.txt"
ALERT_THRESHOLD=3 # 小时（2小时同步一次，3小时未同步就告警）

# 查找最新的同步日志
LATEST_SYNC_LOG=$(ls -t $LOG_DIR/sync-*.log 2>/dev/null | head -1)

if [ -z "$LATEST_SYNC_LOG" ]; then
    echo "❌ 未找到同步日志文件" > $ALERT_FILE
    exit 1
fi

# 检查最近同步时间
LAST_SYNC_LINE=$(grep "2小时同步完成" "$LATEST_SYNC_LOG" | tail -1)
if [ -z "$LAST_SYNC_LINE" ]; then
    echo "⚠️ 同步日志格式异常" > $ALERT_FILE
    exit 1
fi

# 提取时间戳
LAST_SYNC_TIME=$(echo "$LAST_SYNC_LINE" | sed 's/=== 2小时同步完成: //' | sed 's/ ===//')
LAST_SYNC_TIMESTAMP=$(date -j -f "%a %b %d %H:%M:%S %Z %Y" "$LAST_SYNC_TIME" +%s 2>/dev/null || echo 0)

if [ $LAST_SYNC_TIMESTAMP -eq 0 ]; then
    # 尝试其他时间格式
    LAST_SYNC_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(echo "$LAST_SYNC_TIME" | cut -d' ' -f1-2)" +%s 2>/dev/null || echo 0)
fi

CURRENT_TIMESTAMP=$(date +%s)
TIME_DIFF_HOURS=$(( (CURRENT_TIMESTAMP - LAST_SYNC_TIMESTAMP) / 3600 ))

# 生成监控报告
MONITOR_REPORT="$LOG_DIR/monitor-$(date +%Y%m%d_%H%M).md"

cat > $MONITOR_REPORT << EOF
# 数据同步监控报告
**生成时间**: $(date)

## 同步状态
- **最后同步时间**: $LAST_SYNC_TIME
- **当前时间**: $(date)
- **时间差**: ${TIME_DIFF_HOURS} 小时

## 日志分析
**最新同步日志**: $(basename $LATEST_SYNC_LOG)
**日志大小**: $(stat -f%z "$LATEST_SYNC_LOG" 2>/dev/null || stat -c%s "$LATEST_SYNC_LOG") bytes

### 最近5次同步记录
$(grep "2小时同步开始" "$LATEST_SYNC_LOG" | tail -5 | sed 's/^/- /')

### 最近错误记录
$(grep -i "error\|fail\|❌\|⚠️" "$LATEST_SYNC_LOG" | tail -10 | sed 's/^/- /')

## 备份文件状态
### 数据库备份
$(find /Users/mac/.openclaw/workspace/medical-software/mysql/backup -name "*.sql" -type f | wc -l) 个备份文件
**最新备份**: $(ls -t /Users/mac/.openclaw/workspace/medical-software/mysql/backup/*.sql 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "无")

### 代码备份
$(find /Users/mac/.openclaw/workspace/medical-software/code-backup -type d 2>/dev/null | wc -l) 个代码备份目录

## 系统状态
### 本地MySQL容器
$(docker ps | grep mysql-medgsp-local 2>/dev/null || echo "未运行")

### 磁盘空间
**备份目录**: $(du -sh /Users/mac/.openclaw/workspace/medical-software/mysql/backup 2>/dev/null | cut -f1)
**代码目录**: $(du -sh /Users/mac/.openclaw/workspace/medical-software/code-backup 2>/dev/null | cut -f1)

## 评估
EOF

# 评估状态
if [ $TIME_DIFF_HOURS -gt $ALERT_THRESHOLD ]; then
    echo "❌ **状态**: 同步异常 - 已超过${TIME_DIFF_HOURS}小时未同步" >> $MONITOR_REPORT
    echo "**建议**: 立即检查同步脚本和网络连接" >> $MONITOR_REPORT
    
    # 生成告警
    echo "❌ 同步异常: 已超过${TIME_DIFF_HOURS}小时未同步" > $ALERT_FILE
    echo "最后同步时间: $LAST_SYNC_TIME" >> $ALERT_FILE
    
elif [ $TIME_DIFF_HOURS -le 2 ]; then
    echo "✅ **状态**: 同步正常" >> $MONITOR_REPORT
    echo "**建议**: 继续保持当前同步频率" >> $MONITOR_REPORT
    echo "✅ 同步正常" > $ALERT_FILE
else
    echo "⚠️ **状态**: 同步延迟" >> $MONITOR_REPORT
    echo "**建议**: 关注同步状态，准备干预" >> $MONITOR_REPORT
    echo "⚠️ 同步延迟: ${TIME_DIFF_HOURS}小时未同步" > $ALERT_FILE
    echo "最后同步时间: $LAST_SYNC_TIME" >> $ALERT_FILE
fi

echo "" >> $MONITOR_REPORT
echo "---" >> $MONITOR_REPORT
echo "*监控脚本执行时间: $(date)*" >> $MONITOR_REPORT

# 输出简要状态
cat $ALERT_FILE