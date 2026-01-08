#!/bin/bash

echo "=== Teigha SDK 集成测试 ==="

# 1. 检查目录结构
echo "1. 检查目录结构..."
echo "Android SDK 目录:"
if [ -d "android/app/third_party/teigha" ]; then
    echo "✅ android/app/third_party/teigha 存在"
    echo "  包含:"
    ls -la android/app/third_party/teigha/
else
    echo "❌ Android SDK 目录不存在"
fi

echo ""
echo "iOS SDK 目录:"
if [ -d "ios/ThirdParty/TeighaSDK" ]; then
    echo "✅ ios/ThirdParty/TeighaSDK 存在"
    echo "  包含:"
    ls -la ios/ThirdParty/TeighaSDK/
else
    echo "❌ iOS SDK 目录不存在"
fi

# 2. 检查关键文件
echo ""
echo "2. 检查关键文件..."

files=(
    "lib/services/teigha_service.dart"
    "android/app/src/main/kotlin/com/example/flutter_cad/TeighaChannel.kt"
    "android/app/src/main/cpp/teigha_jni.cpp"
    "android/app/CMakeLists.txt"
    "ios/Runner/TeighaPlugin.m"
    "ios/Runner/AppDelegate.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 缺失"
    fi
done

# 3. Flutter 依赖检查
echo ""
echo "3. 检查 Flutter 环境..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter 已安装"
    flutter --version
else
    echo "❌ Flutter 未安装"
fi

# 4. 构建测试
echo ""
echo "4. 构建测试..."
echo "运行 Flutter 清理和获取依赖..."
flutter clean
flutter pub get

echo ""
echo "尝试构建 Android 版本..."
if flutter build apk --debug; then
    echo "✅ Android 构建成功"
else
    echo "❌ Android 构建失败"
fi

echo ""
echo "5. 下一步操作建议："
echo "a) 如果构建成功，可以测试应用"
echo "b) 如果构建失败，检查 Android Studio 和 NDK 配置"
echo "c) 获取真实的 Teigha SDK 文件替换占位符"
echo "d) 在真实设备上测试 DWG 文件渲染"

echo ""
echo "=== 测试完成 ==="
