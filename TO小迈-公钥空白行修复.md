# 紧急任务：公钥空白行修复

## 任务信息
**任务编号**: TASK-PUBKEY-BLANKLINE-20260403
**任务类型**: 紧急修复
**创建时间**: 2026-04-03 20:52 GMT+8
**优先级**: 最高（影响自动化通讯）

## 问题描述
**问题**: SSH公钥认证失败，原因是公钥第一行有空白行
**发现时间**: 2026-04-03 20:47（本地测试发现）
**错误现象**: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)
**影响**: 数据交换自动化流程中断

## 根本原因
本地公钥文件格式正确，但**服务器上的authorized_keys文件中，对应公钥的第一行可能有空白行**，导致SSH服务无法正确解析公钥。

## 需要执行的操作

### 第一步：检查服务器公钥文件
```bash
# 登录云服务器 (47.242.48.154)
# 检查authorized_keys文件内容，特别注意空白行
cat -n /root/.ssh/authorized_keys | head -10

# 显示空白行（如果有）
grep -n "^$" /root/.ssh/authorized_keys

# 显示以ssh-rsa开头的行
grep -n "^ssh-rsa" /root/.ssh/authorized_keys
```

### 第二步：修复空白行问题
```bash
# 备份原文件
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.backup.$(date +%Y%m%d_%H%M%S)

# 移除所有空白行
sed -i '/^$/d' /root/.ssh/authorized_keys

# 确保每行以ssh-rsa开头且没有前导空格
sed -i 's/^[[:space:]]*//' /root/.ssh/authorized_keys

# 验证修复结果
cat -n /root/.ssh/authorized_keys | head -10
```

### 第三步：检查权限（确保正确）
```bash
# 检查目录权限（应该是700）
ls -ld /root/.ssh

# 检查文件权限（应该是600）
ls -l /root/.ssh/authorized_keys

# 如果权限不正确，修复
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
```

### 第四步：测试修复
```bash
# 从服务器本地测试SSH配置
ssh -o StrictHostKeyChecking=no localhost "echo 'SSH公钥修复测试成功'"

# 或者重启SSH服务后测试
systemctl restart sshd
sleep 2
ssh -o StrictHostKeyChecking=no localhost "echo 'SSH服务重启后测试成功'"
```

## 关键要求
1. **立即执行**：这是自动化通讯的关键障碍
2. **精确修复**：只移除空白行，不要修改公钥内容
3. **验证结果**：修复后必须测试连接是否成功
4. **回复确认**：修复完成后回复具体修改内容和测试结果

## 预期结果
修复后，本地应能成功连接：
```bash
ssh -T -o ConnectTimeout=5 -i ~/.ssh/cloud_sync_2h root@47.242.48.154 "echo 'SSH connection test successful'"
```

## 时间要求
**开始时间**：立即
**完成时间**：21:00前（8分钟内）
**汇报时间**：修复后立即汇报

---
**指令下达人**: 惠迈高级工程师
**指令接收人**: 香港工程师小迈
**监督人**: 老王