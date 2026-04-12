# Surface笔记本电脑远程连接指南

## 连接信息
- **Surface IP**: 192.168.3.96
- **设备名**: 2B.local
- **RDP端口**: 3389 (已确认开放)
- **用户名**: 王业朝 (或 yezhaowang@163.com)
- **密码**: wr123456

## 安装状态
- ⏳ Microsoft Remote Desktop: 安装中
- ⏳ FreeRDP: 安装中

## 连接方式

### 方式1：Microsoft Remote Desktop (推荐)
**安装完成后：**
1. 打开"Microsoft Remote Desktop"
2. 点击"Add PC"
3. PC name: `192.168.3.96`
4. User account: 选择"Add User Account"
5. 输入:
   - 用户名: `王业朝` 或 `yezhaowang@163.com`
   - 密码: `wr123456`
6. 点击"Add"，然后双击连接

### 方式2：使用RDP配置文件
双击 `surface-2B.rdp` 文件，输入用户名和密码

### 方式3：命令行 (FreeRDP)
```bash
# 格式1：本地账户
xfreerdp /v:192.168.3.96 /u:王业朝 /p:wr123456 /cert-ignore

# 格式2：Microsoft账户
xfreerdp /v:192.168.3.96 /u:yezhaowang@163.com /p:wr123456 /cert-ignore

# 格式3：计算机名\用户名
xfreerdp /v:192.168.3.96 /u:2B\\\\王业朝 /p:wr123456 /cert-ignore
```

## 故障排除

### 如果连接失败：
1. **检查Surface状态**：确保Surface开机并在线
2. **检查防火墙**：Windows防火墙可能阻止连接
3. **用户名格式**：尝试不同格式：
   - `王业朝`
   - `yezhaowang@163.com`
   - `2B\王业朝`
   - `.\王业朝`

### 在Surface上检查：
1. Win + R → 输入`sysdm.cpl` → 远程 → 确认远程桌面已启用
2. 检查Windows防火墙设置
3. 确保用户账户有密码

## 安全建议
1. **修改密码**：建议使用更强密码
2. **使用后禁用**：连接完成后可暂时禁用远程桌面
3. **VPN建议**：如果通过公网连接，建议使用VPN

## 快速测试命令
```bash
# 测试RDP端口
nc -z -v -G 3 192.168.3.96 3389

# 测试网络连通性
ping -c 2 192.168.3.96
```