# SSH公钥认证问题 - 完整解决方案

## 问题描述
SSH公钥认证失败，错误信息：
```
Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)
```

## 根本原因分析
根据2026-04-03晚上的诊断，问题可能是：
1. **服务器端authorized_keys文件第一行空白行**
2. SSH服务配置问题
3. 文件权限问题

## 解决方案（按优先级排序）

### 方案1：服务器端修复（首选）
**执行人**：香港工程师小迈

#### 步骤1：检查authorized_keys文件
```bash
# 1. 查看文件内容（特别注意第一行）
cat -A ~/.ssh/authorized_keys | head -5

# 2. 检查文件权限
ls -la ~/.ssh/authorized_keys

# 3. 正确的权限应该是：
# -rw------- 1 root root   # 600权限
```

#### 步骤2：重新创建authorized_keys文件
```bash
# 1. 备份原文件
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup.$(date +%Y%m%d)

# 2. 删除原文件
rm ~/.ssh/authorized_keys

# 3. 重新创建（确保没有空白行）
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOyWt7kgr+CfWXBCCGPEhhuGSZG2H06k/SuuEaa0agKZmy3ZLMOFkGnXUxw3KbHpPm5zoipZ7hnBzhZOBS64ond8uOpfRTHY2ITIA/+a4AFczI0LiqVm4OTwgN3DiROQ1yMsvTM8yUIcuFE53NNVqbzzKpOyn20v5Ai5MQBdDJenKk+MRoy5FmPZnhwxWb+6nxvJBNsmgr2j1LZXyZYPC8AaVb8+avT+tdzIk85ZOlPutAKA9IE0Hkyq7OwFZyy0CbwPKkX2hf0/Wut/mQRSZSMKWnqdfGWYXiXq/QjoH2nbunPprqoLrQ5SaaCmR55SARJtMh3Nxiau3cMk5CBImZmPTRZUxzq1qKCaCDX1yGP+QxUg6BjSgEQJ4XM6yPfycIW8iflXcHebFlunS9RoJvtlRqTnW4sGWuwmve/sMRhu44zXkaNB5U2K/U0i5aNSqwUXqJhU2itZvk//MNJVZOgIAT5BLqL7HQRO6z/vF9ph+gNTCk5KJpS9lSlALttjBhosfEvNF2zmEIFuMYpb5Ho+HxLiQgM9E0vT1Zv/uRGnYxGvlMjlU2QEo30unW90aFZWuIK3Bo93uZCnkLcAZE4WCOk0G3hYzp2p+LT4PDkMvWI10i8Nv2Y3he827IxEnAt/528gOhxQeagExCN+DMWqS8GxX90ji1tvHwgXJw+Q== mac@macdeMac-Studio.local" > ~/.ssh/authorized_keys

# 4. 设置正确权限
chmod 600 ~/.ssh/authorized_keys
chown root:root ~/.ssh/authorized_keys

# 5. 检查.ssh目录权限
chmod 700 ~/.ssh
```

#### 步骤3：检查SSH服务配置
```bash
# 1. 检查SSH配置
grep -i "PubkeyAuthentication" /etc/ssh/sshd_config

# 2. 确保配置为：
# PubkeyAuthentication yes

# 3. 重启SSH服务
systemctl restart sshd

# 4. 检查服务状态
systemctl status sshd
```

#### 步骤4：查看SSH日志
```bash
# 查看认证日志
tail -f /var/log/auth.log
# 或
tail -f /var/log/secure
```

### 方案2：备用连接方式（如果方案1失败）

#### 方式A：密码认证临时方案
```bash
# 1. 在Termius中保存密码
# 2. 使用expect脚本自动化密码输入
# 3. 建立临时连接通道
```

#### 方式B：WebSocket代理
```bash
# 1. 在服务器端启动WebSocket代理
# 2. 本地通过WebSocket连接
# 3. 转发SSH流量
```

#### 方式C：HTTP文件传输
```bash
# 1. 服务器端提供HTTP文件下载
# 2. 本地通过curl/wget下载文件
# 3. 手动同步数据
```

### 方案3：本地测试验证

#### 测试脚本：`test-ssh-fix.sh`
```bash
#!/bin/bash
echo "=== SSH修复验证测试 ==="
echo "测试时间: $(date)"

# 测试1：基本连接
echo -e "\n[测试1] 基本SSH连接测试"
ssh -T -o ConnectTimeout=5 -i ~/.ssh/cloud_sync_2h root@47.242.48.154 "echo 'SSH连接成功！'"

if [ $? -eq 0 ]; then
    echo "✅ SSH连接成功"
else
    echo "❌ SSH连接失败"
    
    # 测试2：详细诊断
    echo -e "\n[测试2] 详细诊断模式"
    ssh -vvv -T -o ConnectTimeout=5 -i ~/.ssh/cloud_sync_2h root@47.242.48.154 2>&1 | tail -30
fi

echo -e "\n=== 测试完成 ==="
```

## 验证步骤

### 验证1：本地测试
```bash
# 运行测试脚本
chmod +x test-ssh-fix.sh
./test-ssh-fix.sh
```

### 验证2：功能测试
```bash
# 测试文件传输
scp -i ~/.ssh/cloud_sync_2h test.txt root@47.242.48.154:/tmp/

# 测试命令执行
ssh -i ~/.ssh/cloud_sync_2h root@47.242.48.154 "ls -la /root/medgsp_backup_20260403_1300/"
```

### 验证3：自动化测试
```bash
# 测试自动化脚本
./medical-software/scripts/sync-2h.sh --test
```

## 问题排查清单

### 如果仍然失败，检查：

#### 1. 网络层面
```bash
# 检查网络连通性
ping -c 3 47.242.48.154

# 检查端口
nc -zv 47.242.48.154 22
```

#### 2. 防火墙层面
```bash
# 服务器端检查防火墙
iptables -L -n | grep 22
ufw status | grep 22

# 本地检查防火墙
sudo pfctl -s rules | grep ssh
```

#### 3. SSH配置层面
```bash
# 检查所有相关配置
grep -i "Authentication\|Pubkey\|Password" /etc/ssh/sshd_config

# 检查允许的用户
grep -i "AllowUsers\|AllowGroups" /etc/ssh/sshd_config
```

#### 4. 密钥层面
```bash
# 验证密钥对
ssh-keygen -l -f ~/.ssh/cloud_sync_2h
ssh-keygen -l -f ~/.ssh/cloud_sync_2h.pub

# 检查密钥类型
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud_sync_2h_new
```

## 紧急备用方案

### 方案A：临时工作区
1. 使用现有备份文件工作
2. 本地搭建测试环境
3. 准备修复方案文档

### 方案B：人工干预
1. 电话联系小迈确认状态
2. 远程桌面协助
3. 分步指导操作

### 方案C：计划调整
1. 调整工作优先级
2. 先解决其他可推进问题
3. SSH问题作为独立任务处理

## 执行时间表

### 阶段1：立即执行（今天）
1. ✅ 发送询问消息给小迈
2. 🔄 准备完整解决方案文档
3. 🔄 创建验证测试脚本

### 阶段2：等待回复（13:30前）
1. ⏸️ 等待小迈回复昨天工作情况
2. ⏸️ 根据回复调整方案
3. ⏸️ 制定具体执行计划

### 阶段3：执行修复（今天下午）
1. ⏸️ 小迈执行服务器端修复
2. ⏸️ 本地测试验证
3. ⏸️ 建立完整自动化通道

### 阶段4：后续工作（明天）
1. ⏸️ MySQL容器部署
2. ⏸️ 页面问题解决
3. ⏸️ 自动化运维体系建立

## 沟通模板

### 给小迈的指令模板
```
【SSH公钥修复指令】

请立即执行以下操作：

1. 检查authorized_keys文件：
   cat -A ~/.ssh/authorized_keys | head -5

2. 重新创建authorized_keys文件：
   echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOyWt7kgr+CfWXBCCGPEhhuGSZG2H06k/SuuEaa0agKZmy3ZLMOFkGnXUxw3KbHpPm5zoipZ7hnBzhZOBS64ond8uOpfRTHY2ITIA/+a4AFczI0LiqVm4OTwgN3DiROQ1yMsvTM8yUIcuFE53NNVqbzzKpOyn20v5Ai5MQBdDJenKk+MRoy5FmPZnhwxWb+6nxvJBNsmgr2j1LZXyZYPC8AaVb8+avT+tdzIk85ZOlPutAKA9IE0Hkyq7OwFZyy0CbwPKkX2hf0/Wut/mQRSZSMKWnqdfGWYXiXq/QjoH2nbunPprqoLrQ5SaaCmR55SARJtMh3Nxiau3cMk5CBImZmPTRZUxzq1qKCaCDX1yGP+QxUg6BjSgEQJ4XM6yPfycIW8iflXcHebFlunS9RoJvtlRqTnW4sGWuwmve/sMRhu44zXkaNB5U2K/U0i5aNSqwUXqJhU2itZvk//MNJVZOgIAT5BLqL7HQRO6z/vF9ph+gNTCk5KJpS9lSlALttjBhosfEvNF2zmEIFuMYpb5Ho+HxLiQgM9E0vT1Zv/uRGnYxGvlMjlU2QEo30unW90aFZWuIK3Bo93uZCnkLcAZE4WCOk0G3hYzp2p+LT4PDkMvWI10i8Nv2Y3he827IxEnAt/528gOhxQeagExCN+DMWqS8GxX90ji1tvHwgXJw+Q== mac@macdeMac-Studio.local" > ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys

3. 重启SSH服务：
   systemctl restart sshd

4. 回复执行结果和测试状态。
```

---
**文档版本**：v1.0
**创建时间**：2026-04-05 13:28 GMT+8
**更新人**：惠迈高级工程师
**状态**：等待执行