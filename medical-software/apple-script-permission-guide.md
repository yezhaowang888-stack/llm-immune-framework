# Apple Script权限授权指南

## 老王晚上需要授权的权限

### 第一步：打开系统偏好设置
1. 点击屏幕左上角苹果菜单 🍎
2. 选择"系统偏好设置"
3. 点击"安全性与隐私"

### 第二步：解锁设置（关键）
1. 点击左下角锁图标 🔒
2. 输入您的管理员密码
3. 锁图标变为打开状态

### 第三步：授权自动化权限
1. 点击"隐私"标签页
2. 在左侧列表中找到"自动化"
3. 在右侧找到Termius应用
4. 勾选Termius旁边的复选框

### 第四步：授权辅助功能权限
1. 仍在"隐私"标签页
2. 在左侧列表中找到"辅助功能"
3. 点击右下角"+"按钮
4. 在应用程序中找到Termius并添加
5. 确保Termius被勾选

### 第五步：可能需要的其他权限
如果后续需要，可能还需要授权：
- **屏幕录制**：如果需要捕获Termius输出
- **文件和文件夹**：如果需要读写脚本文件
- **完全磁盘访问**：如果需要深度系统集成

### 验证授权成功
授权后，我可以测试以下Apple Script：

```applescript
tell application "Termius"
    get name of every window
end tell
```

如果返回Termius窗口信息，说明授权成功。

## 晚上检查清单

### 1. MySQL容器检查
```bash
# 打开Terminal，运行检查脚本
cd /Users/mac/.openclaw/workspace/medical-software
./check-mysql.sh

# 或手动检查
docker ps | grep mysql
```

### 2. Apple Script权限检查
- 确认已按上述步骤授权
- 如果有任何权限提示，点击"允许"

### 3. 反馈给我
请告诉我：
1. MySQL容器是否运行正常
2. Apple Script权限是否授权成功
3. 是否遇到任何问题

## 问题解决

### 如果MySQL容器启动失败
1. 运行 `docker logs medgsp-mysql-local` 查看错误
2. 截图或描述错误信息
3. 我会提供解决方案

### 如果权限授权失败
1. 尝试重启Termius应用
2. 重启系统偏好设置
3. 如果仍失败，我们可以使用备选方案

## 备选方案
如果Apple Script权限问题无法解决：
1. 使用命令行expect脚本自动化SSH
2. 使用Python pyautogui库
3. 先解决其他问题，权限问题后续处理

---
**重要**：授权后请告诉我，我可以立即开始Apple Script自动化测试。