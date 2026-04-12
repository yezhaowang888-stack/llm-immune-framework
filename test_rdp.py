#!/usr/bin/env python3
import socket
import subprocess
import sys

def test_rdp_port(ip, port=3389):
    """测试RDP端口是否开放"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"端口测试错误: {e}")
        return False

def main():
    ip = "192.168.3.96"
    port = 3389
    
    print(f"测试Surface连接: {ip}:{port}")
    print("=" * 40)
    
    # 测试端口
    if test_rdp_port(ip, port):
        print("✅ RDP端口(3389)开放")
    else:
        print("❌ RDP端口未响应")
        sys.exit(1)
    
    print("\n" + "=" * 40)
    print("连接信息:")
    print(f"IP地址: {ip}")
    print("端口: 3389")
    print("用户名: 王业朝 或 yezhaowang@163.com")
    print("密码: wr123456")
    
    print("\n" + "=" * 40)
    print("连接方法:")
    print("1. 手动安装Microsoft Remote Desktop:")
    print("   从Mac App Store搜索安装")
    print("")
    print("2. 使用现有RDP客户端:")
    print("   a. 打开客户端")
    print("   b. 新建连接")
    print("   c. 地址: 192.168.3.96")
    print("   d. 用户名: 王业朝")
    print("   e. 密码: wr123456")
    print("   f. 连接")
    
    print("\n" + "=" * 40)
    print("安全提醒:")
    print("- 建议修改为更强密码")
    print("- 使用后暂时禁用远程桌面")
    print("- 确保在安全网络环境中使用")

if __name__ == "__main__":
    main()