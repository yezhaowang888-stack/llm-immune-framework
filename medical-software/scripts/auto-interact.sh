#!/bin/bash
# 自动化交互脚本 - 惠迈高级工程师与小迈直接交互

LOG_DIR="/Users/mac/.openclaw/workspace/medical-software/logs"
LOG_FILE="$LOG_DIR/auto-interact-$(date +%Y%m%d).log"
INSTRUCTION_FILE="$LOG_DIR/last-instruction.txt"
RESPONSE_FILE="$LOG_DIR/last-response.txt"

mkdir -p $LOG_DIR

echo "=== 自动化交互开始: $(date) ===" >> $LOG_FILE

# 显示菜单
show_menu() {
    echo ""
    echo "🔧 惠迈高级工程师自动化交互系统"
    echo "=================================="
    echo "1. 检查服务器状态"
    echo "2. 备份数据库"
    echo "3. 同步代码文件"
    echo "4. 测试SSH连接"
    echo "5. 查看日志"
    echo "6. 自定义指令"
    echo "0. 退出"
    echo ""
    echo "请输入选项 [0-6]: "
}

# 执行指令
execute_instruction() {
    local instruction="$1"
    local description="$2"
    
    echo "[$(date)] 执行指令: $description" >> $LOG_FILE
    echo "指令: $instruction" >> $LOG_FILE
    
    # 保存指令到文件（供小迈查看）
    echo "# $(date)" > $INSTRUCTION_FILE
    echo "# $description" >> $INSTRUCTION_FILE
    echo "$instruction" >> $INSTRUCTION_FILE
    
    echo "✅ 指令已生成: $INSTRUCTION_FILE"
    echo "请小迈执行以上指令并回复结果。"
    
    # 等待响应（模拟）
    echo "[$(date)] 等待响应..." >> $LOG_FILE
}

# 处理响应
process_response() {
    local response="$1"
    
    echo "[$(date)] 收到响应:" >> $LOG_FILE
    echo "$response" >> $RESPONSE_FILE
    echo "$response" >> $LOG_FILE
    
    echo "✅ 响应已记录: $RESPONSE_FILE"
}

# 主循环
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            execute_instruction "systemctl status sshd && docker ps && df -h" "检查服务器状态"
            ;;
        2)
            execute_instruction "docker exec mysql-medgsp mysqldump -uroot -pYourPassword123! med_gsp --single-transaction --skip-lock-tables > /tmp/db_backup_$(date +%Y%m%d_%H%M%S).sql && ls -lh /tmp/db_backup_*.sql" "备份数据库"
            ;;
        3)
            execute_instruction "tar -czf /tmp/code_backup_$(date +%Y%m%d_%H%M%S).tar.gz /opt/med-gsp-system/ /usr/share/nginx/html/bio/ && ls -lh /tmp/code_backup_*.tar.gz" "同步代码文件"
            ;;
        4)
            execute_instruction "ssh -v -i ~/.ssh/cloud_sync_server localhost && ssh -v -i ~/.ssh/cloud_sync_server root@47.242.48.154 'echo 测试成功'" "测试SSH连接"
            ;;
        5)
            echo "=== 最近日志 ==="
            tail -20 $LOG_FILE
            ;;
        6)
            echo "请输入自定义指令:"
            read -r custom_cmd
            echo "请输入指令描述:"
            read -r custom_desc
            execute_instruction "$custom_cmd" "$custom_desc"
            ;;
        0)
            echo "退出自动化交互系统"
            echo "[$(date)] 系统退出" >> $LOG_FILE
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入"
            ;;
    esac
    
    # 模拟响应处理
    echo ""
    echo "是否收到小迈的响应？(y/n)"
    read -r has_response
    if [ "$has_response" = "y" ] || [ "$has_response" = "Y" ]; then
        echo "请输入响应内容（输入END结束）:"
        response=""
        while IFS= read -r line; do
            if [ "$line" = "END" ]; then
                break
            fi
            response="$response$line\n"
        done
        process_response "$response"
    fi
done