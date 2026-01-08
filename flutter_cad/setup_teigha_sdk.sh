#!/bin/bash

# ODA SDK 下载和配置脚本
echo "=== ODA SDK 配置脚本 ==="

# 创建 SDK 目录结构
echo "1. 创建 SDK 目录结构..."
mkdir -p android/app/third_party/teigha/{include,lib/{arm64-v8a,armeabi-v7a,x86_64,x86}}
mkdir -p ios/ThirdParty/TeighaSDK

# 检查是否需要手动下载
echo ""
echo "2. 下载说明："
echo "由于 ODA Trial 激活工具是 Windows 程序，你需要："
echo ""
echo "方法 1 - 在 Windows 电脑上："
echo "   a) 运行 ODATrialActivator.exe"
echo "   b) 选择 Teigha SDK for Android 和 iOS"
echo "   c) 下载完成后复制到项目目录"
echo ""
echo "方法 2 - 直接从 ODA 网站下载："
echo "   a) 访问 https://www.opendesign.com/guestfiles/teigha"
echo "   b) 使用你的账户登录"
echo "   c) 下载以下版本："
echo "      - Teigha SDK for Android (ARM64 和 x86_64)"
echo "      - Teigha SDK for iOS"
echo ""
echo "3. 目录结构配置："
echo ""
echo "Android SDK 结构："
echo "  android/app/third_party/teigha/"
echo "  ├── include/           # 头文件"
echo "  └── lib/"
echo "      ├── arm64-v8a/     # Android ARM64 库"
echo "      ├── armeabi-v7a/   # Android ARM32 库"
echo "      ├── x86_64/        # Android x64 库"
echo "      └── x86/           # Android x86 库"
echo ""
echo "iOS SDK 结构："
echo "  ios/ThirdParty/TeighaSDK/"
echo "  ├── include/           # 头文件"
echo"   └── lib/               # 静态库和框架"
echo ""

# 创建占位符文件以测试构建
echo "4. 创建测试占位符文件..."

# Android 占位符
touch android/app/third_party/teigha/include/Teigha.h
touch android/app/third_party/teigha/lib/arm64-v8a/libTeighaCore.so
touch android/app/third_party/teigha/lib/arm64-v8a/libTD_Db.so
touch android/app/third_party/teigha/lib/arm64-v8a/libTD_Gi.so

# iOS 占位符
touch ios/ThirdParty/TeighaSDK/include/Teigha.h
touch ios/ThirdParty/TeighaSDK/lib/libTeighaCore.a

echo ""
echo "5. 占位符文件已创建，用于测试构建流程"
echo ""
echo "6. 下一步操作："
echo "   a) 获取真实的 Teigha SDK 文件"
echo "   b) 替换占位符文件"
echo "   c) 更新 CMakeLists.txt 中的路径"
echo "   d) 在 Xcode 中添加 iOS Framework"
echo ""
echo "=== 配置完成 ==="
