#!/bin/bash

# Termius基础设施测试脚本

echo "=== Termius基础设施测试 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 设置路径
WORKSPACE_DIR="/Users/mac/.openclaw/workspace"
SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
TEMPLATES_DIR="$WORKSPACE_DIR/termius-templates"
LOGS_DIR="$WORKSPACE_DIR/logs"
LOG_FILE="$LOGS_DIR/termius_communications.log"

# 测试结果汇总
PASS=0
FAIL=0

test_step() {
    local name=$1
    local command=$2
    local expected=$3
    
    echo -n "测试: $name ... "
    
    if eval "$command" > /dev/null 2>&1; then
        if [ "$expected" = "pass" ]; then
            echo "✅ 通过"
            ((PASS++))
        else
            echo "❌ 失败（预期失败但通过）"
            ((FAIL++))
        fi
    else
        if [ "$expected" = "fail" ]; then
            echo "✅ 通过（预期失败）"
            ((PASS++))
        else
            echo "❌ 失败"
            ((FAIL++))
        fi
    fi
}

# 测试1：目录结构
echo "1. 测试目录结构..."
test_step "脚本目录存在" "[ -d '$SCRIPTS_DIR' ]" "pass"
test_step "模板目录存在" "[ -d '$TEMPLATES_DIR' ]" "pass"
test_step "日志目录存在" "[ -d '$LOGS_DIR' ]" "pass"
test_step "紧急模板目录存在" "[ -d '$TEMPLATES_DIR/emergency' ]" "pass"
test_step "日常模板目录存在" "[ -d '$TEMPLATES_DIR/routine' ]" "pass"
test_step "系统模板目录存在" "[ -d '$TEMPLATES_DIR/system' ]" "pass"

# 测试2：脚本文件
echo ""
echo "2. 测试脚本文件..."
test_step "监控脚本存在" "[ -f '$SCRIPTS_DIR/termius-monitor.sh' ]" "pass"
test_step "日志脚本存在" "[ -f '$SCRIPTS_DIR/termius-logger.sh' ]" "pass"
test_step "监控脚本可执行" "[ -x '$SCRIPTS_DIR/termius-monitor.sh' ]" "pass"
test_step "日志脚本可执行" "[ -x '$SCRIPTS_DIR/termius-logger.sh' ]" "pass"
test_step "Apple Script存在" "[ -f '$SCRIPTS_DIR/enhanced-termius-sender.applescript' ]" "pass"

# 测试3：模板文件
echo ""
echo "3. 测试模板文件..."
test_step "SSH模板存在" "[ -f '$TEMPLATES_DIR/emergency/ssh-problem-fix.template' ]" "pass"
test_step "MySQL模板存在" "[ -f '$TEMPLATES_DIR/emergency/mysql-deployment.template' ]" "pass"
test_step "日常检查模板存在" "[ -f '$TEMPLATES_DIR/routine/daily-checkin.template' ]" "pass"

# 测试4：日志功能
echo ""
echo "4. 测试日志功能..."
# 确保日志文件存在
touch "$LOG_FILE"

# 测试日志脚本基本功能
test_step "日志脚本stats功能" "'$SCRIPTS_DIR/termius-logger.sh' stats > /dev/null 2>&1" "pass"

# 创建测试日志条目
"$SCRIPTS_DIR/termius-logger.sh" send "基础设施测试消息" > /dev/null 2>&1
"$SCRIPTS_DIR/termius-logger.sh" success "测试成功" > /dev/null 2>&1

test_step "日志记录功能" "grep -q '基础设施测试消息' '$LOG_FILE' 2>/dev/null" "pass"
test_step "成功记录功能" "grep -q '测试成功' '$LOG_FILE' 2>/dev/null" "pass"

# 测试5：监控功能
echo ""
echo "5. 测试监控功能..."
test_step "监控脚本运行" "'$SCRIPTS_DIR/termius-monitor.sh' > /dev/null 2>&1" "pass"

# 测试6：文档文件
echo ""
echo "6. 测试文档文件..."
test_step "使用指南存在" "[ -f '$WORKSPACE_DIR/Termius自动化使用指南.md' ]" "pass"
test_step "优化方案存在" "[ -f '$WORKSPACE_DIR/Termius自动化优化方案.md' ]" "pass"
test_step "创建报告存在" "[ -f '$WORKSPACE_DIR/Termius基础设施创建报告.md' ]" "pass"

# 汇总结果
echo ""
echo "=== 测试结果汇总 ==="
echo "总测试数: $((PASS + FAIL))"
echo "通过: $PASS"
echo "失败: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo -e "\n✅ 所有测试通过！基础设施创建成功。"
    echo ""
    echo "下一步："
    echo "1. 运行监控脚本查看状态:"
    echo "   $SCRIPTS_DIR/termius-monitor.sh"
    echo ""
    echo "2. 测试日志功能:"
    echo "   $SCRIPTS_DIR/termius-logger.sh stats"
    echo ""
    echo "3. 查看可用模板:"
    echo "   ls $TEMPLATES_DIR/emergency/"
    echo ""
    echo "4. 阅读使用指南:"
    echo "   head -30 $WORKSPACE_DIR/Termius自动化使用指南.md"
else
    echo -e "\n❌ 有 $FAIL 个测试失败，请检查问题。"
    echo "失败详情："
    # 这里可以添加更详细的错误信息
    exit 1
fi

echo ""
echo "=== 基础设施状态 ==="
echo "脚本目录: $SCRIPTS_DIR ($(ls "$SCRIPTS_DIR" | wc -l) 个文件)"
echo "模板目录: $TEMPLATES_DIR ($(find "$TEMPLATES_DIR" -name "*.template" 2>/dev/null | wc -l) 个模板)"
echo "日志文件: $LOG_FILE ($(wc -l < "$LOG_FILE" 2>/dev/null || echo 0) 行)"
echo ""
echo "✅ Termius自动化基础设施测试完成"