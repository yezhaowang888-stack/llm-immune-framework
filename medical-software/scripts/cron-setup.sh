#!/bin/bash
# 配置2小时同步的定时任务

SYNC_SCRIPT="/Users/mac/.openclaw/workspace/medical-software/scripts/sync-2h.sh"
MONITOR_SCRIPT="/Users/mac/.openclaw/workspace/medical-software/scripts/monitor-sync.sh"

# 设置执行权限
chmod +x $SYNC_SCRIPT
chmod +x $MONITOR_SCRIPT

# 每2小时同步一次（偶数小时的第0分钟）
SYNC_CRON="0 */2 * * * $SYNC_SCRIPT"

# 每小时检查一次监控（第30分钟）
MONITOR_CRON="30 * * * * $MONITOR_SCRIPT"

# 每天凌晨3点清理旧日志
CLEAN_CRON="0 3 * * * find /Users/mac/.openclaw/workspace/medical-software/logs -name \"*.log\" -mtime +30 -delete"

echo "正在配置定时任务..."
echo ""

# 获取当前crontab
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null > $TEMP_CRON

# 移除旧的同步相关任务
grep -v "sync-2h.sh\|monitor-sync.sh\|medical-software/logs" $TEMP_CRON > ${TEMP_CRON}.clean

# 添加新任务
cat ${TEMP_CRON}.clean > $TEMP_CRON
echo "# 医疗器械管理系统数据同步任务" >> $TEMP_CRON
echo "# 配置时间: $(date)" >> $TEMP_CRON
echo "$SYNC_CRON" >> $TEMP_CRON
echo "$MONITOR_CRON" >> $TEMP_CRON
echo "$CLEAN_CRON" >> $TEMP_CRON
echo "" >> $TEMP_CRON

# 安装新的crontab
crontab $TEMP_CRON

# 清理临时文件
rm -f $TEMP_CRON ${TEMP_CRON}.clean

echo "✅ 定时任务配置完成"
echo ""
echo "配置的任务:"
echo "1. 每2小时同步: $SYNC_CRON"
echo "2. 每小时监控: $MONITOR_CRON"
echo "3. 每天清理日志: $CLEAN_CRON"
echo ""
echo "查看当前crontab:"
crontab -l