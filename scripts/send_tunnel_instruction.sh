#!/bin/bash
# 标准化隧道指令发送脚本

SSH_KEY="/Users/mac/.ssh/cloud_sync_2h"
SERVER="root@8.217.249.184"
TASK_ID="TASK-20260408-004"

echo "=== 标准化隧道指令发送 ==="
echo "协议: SSH隧道通信 v1.0"
echo "时间: $(date)"
echo ""

# 创建标准化指令JSON
INSTRUCTION_JSON=$(cat << INSTRUCTION_EOF
{
  "protocol": "huimai_tunnel_v1",
  "version": "1.0",
  "message_id": "msg_$(date +%s)",
  "timestamp": "$(date -Iseconds)",
  "direction": "惠迈高级工程师 → 小迈智能体",
  
  "sender": {
    "id": "惠迈高级工程师",
    "role": "技术协调层",
    "location": "本地Mac"
  },
  
  "receiver": {
    "id": "小迈智能体",
    "role": "技术执行层", 
    "location": "香港服务器",
    "tunnel_port": 18789
  },
  
  "message_type": "task_execution",
  "priority": "urgent",
  
  "content": {
    "task": {
      "id": "$TASK_ID",
      "title": "修复医疗器械软件账页显示问题",
      "description": "医疗器械管理系统两个账页显示异常，页面加载不完整，数据展示错误",
      "server": "8.217.249.184",
      "task_file": "/root/huimai-openclaw/tasks/active/$TASK_ID.json",
      "diagnostic_script": "/root/tasks/diagnose_medical_issue.sh",
      "due_time": "2026-04-08T18:00:00+08:00"
    },
    
    "execution": {
      "immediate": true,
      "steps": [
        "1. 确认接收本指令",
        "2. SSH登录目标服务器",
        "3. 查看任务文件了解详情",
        "4. 执行诊断确定问题根源",
        "5. 修复问题并测试验证",
        "6. 更新任务状态"
      ],
      "expected_duration": "4小时"
    },
    
    "reporting": {
      "confirm_receipt": "立即通过隧道响应",
      "progress_updates": "每小时报告进展",
      "completion_report": "完成后提交详细报告",
      "response_timeout": "5分钟"
    }
  },
  
  "delivery": {
    "method": "ssh_tunnel",
    "tunnel_port": 18789,
    "fallback_methods": ["file_system", "visual_alert"]
  }
}
INSTRUCTION_EOF
)

echo "1. 创建标准化指令..."
echo "$INSTRUCTION_JSON" | python3 -m json.tool 2>/dev/null || echo "$INSTRUCTION_JSON"

echo ""
echo "2. 发送指令到隧道通信目录..."

# 发送到服务器隧道目录
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" << 'SERVEREOF'
# 创建隧道通信目录结构
mkdir -p /root/tunnel_comms/{inbox,outbox,archive}

# 保存指令文件
INSTRUCTION_FILE="/root/tunnel_comms/inbox/instruction_$(date +%Y%m%d_%H%M%S).json"
cat > "$INSTRUCTION_FILE" << 'INSTRFILE'
{
  "protocol": "huimai_tunnel_v1",
  "version": "1.0",
  "message_id": "msg_$(date +%s)",
  "timestamp": "$(date -Iseconds)",
  "direction": "惠迈高级工程师 → 小迈智能体",
  
  "sender": {
    "id": "惠迈高级工程师",
    "role": "技术协调层",
    "location": "本地Mac"
  },
  
  "receiver": {
    "id": "小迈智能体",
    "role": "技术执行层", 
    "location": "香港服务器",
    "tunnel_port": 18789
  },
  
  "message_type": "task_execution",
  "priority": "urgent",
  
  "content": {
    "task": {
      "id": "TASK-20260408-004",
      "title": "修复医疗器械软件账页显示问题",
      "description": "医疗器械管理系统两个账页显示异常，页面加载不完整，数据展示错误",
      "server": "8.217.249.184",
      "task_file": "/root/huimai-openclaw/tasks/active/TASK-20260408-004.json",
      "diagnostic_script": "/root/tasks/diagnose_medical_issue.sh",
      "due_time": "2026-04-08T18:00:00+08:00"
    },
    
    "execution": {
      "immediate": true,
      "steps": [
        "1. 确认接收本指令",
        "2. SSH登录目标服务器",
        "3. 查看任务文件了解详情",
        "4. 执行诊断确定问题根源",
        "5. 修复问题并测试验证",
        "6. 更新任务状态"
      ],
      "expected_duration": "4小时"
    },
    
    "reporting": {
      "confirm_receipt": "立即通过隧道响应",
      "progress_updates": "每小时报告进展",
      "completion_report": "完成后提交详细报告",
      "response_timeout": "5分钟"
    }
  },
  
  "delivery": {
    "method": "ssh_tunnel",
    "tunnel_port": 18789,
    "fallback_methods": ["file_system", "visual_alert"]
  }
}
INSTRFILE

echo "指令文件已保存: $INSTRUCTION_FILE"
echo "文件大小: $(wc -c < "$INSTRUCTION_FILE") 字节"

# 同时创建简化版本用于隧道端口发送
echo "【隧道指令】任务TASK-20260408-004已就绪，请立即处理" > /tmp/tunnel_alert.txt
SERVEREOF

echo ""
echo "3. 更新服务器提醒..."
ssh -i "$SSH_KEY" -o PasswordAuthentication=no "$SERVER" \
    "echo '=== 隧道指令已发送 ===' >> /etc/motd && \
     echo '时间: \$(date)' >> /etc/motd && \
     echo '任务: TASK-20260408-004' >> /etc/motd && \
     echo '状态: 等待小迈响应' >> /etc/motd"

echo ""
echo "=== 指令发送完成 ==="
echo "✅ 标准化指令已创建"
echo "✅ 指令文件已保存到服务器"
echo "✅ 隧道通信目录已更新"
echo "✅ 服务器提醒已设置"
echo ""
echo "等待小迈智能体通过隧道响应..."