# Teigha SDK 集成指南

本指南说明如何在 Flutter CAD 应用中集成 Teigha SDK 来渲染 DWG 文件。

## 概述

我们已经创建了完整的 Teigha SDK 集成架构：

- **Flutter 端**: `TeighaService` 类提供 Dart API
- **Android 端**: Kotlin + JNI C++ 桥接
- **iOS 端**: Objective-C++ 桥接
- **UI 集成**: 修改后的 `PreviewScreen` 支持原生渲染

## 安装步骤

### 1. 获取 Teigha SDK

首先需要从 ODA (Open Design Alliance) 获取 Teigha SDK：

1. 访问 [ODA 官网](https://www.opendesign.com/guestfiles/teigha)
2. 注册并下载适用于你的平台的 SDK
3. 解压到项目目录

### 2. Android 配置

#### 2.1 复制 SDK 文件

```bash
# 创建 Android 第三方库目录
mkdir -p android/app/third_party/teigha

# 复制 Teigha SDK 文件 (根据你的实际路径调整)
cp -r /path/to/teigha/sdk/include android/app/third_party/teigha/
cp -r /path/to/teigha/sdk/lib android/app/third_party/teigha/
```

#### 2.2 更新 CMakeLists.txt

编辑 `android/app/CMakeLists.txt`，更新 SDK 路径：

```cmake
# 更新这些路径以匹配你的实际 Teigha SDK 安装
set(TEIGHA_SDK_ROOT "${CMAKE_SOURCE_DIR}/third_party/teigha")
```

#### 2.3 更新 JNI 代码

编辑 `android/app/src/main/cpp/teigha_jni.cpp`，添加实际的 Teigha SDK 头文件包含和实现。

### 3. iOS 配置

#### 3.1 添加 Teigha SDK 到项目

1. 打开 Xcode 项目: `ios/Runner.xcworkspace`
2. 右键点击 Runner 项目，选择 "Add Files to Runner"
3. 选择 Teigha SDK 的 `.framework` 文件
4. 在 Build Settings 中添加 Framework Search Paths

#### 3.2 更新 Objective-C++ 代码

编辑 `ios/Runner/TeighaPlugin.m`，添加实际的 Teigha SDK 实现。

## 功能特性

### 当前实现的功能

- ✅ **DWG 文件渲染**: 将 DWG 文件渲染为图像
- ✅ **文件信息获取**: 获取 DWG 文件的元数据
- ✅ **图层信息**: 获取 DWG 文件的图层列表
- ✅ **交互式查看**: 支持缩放和平移
- ✅ **回退机制**: 渲染失败时自动回退到 WebView

### API 使用示例

```dart
// 初始化 SDK
await TeighaService.initialize();

// 渲染 DWG 为图像
final imageData = await TeighaService.renderDwgToImage(
  filePath,
  width: 1024,
  height: 768,
  format: 'png',
);

// 获取文件信息
final info = await TeighaService.getDwgInfo(filePath);

// 获取图层列表
final layers = await TeighaService.getLayers(filePath);

// 清理资源
await TeighaService.cleanup();
```

## 注意事项

### 许可证要求

- Teigha SDK 需要商业许可证
- 确保遵守 ODA 的许可条款
- 测试时可以使用评估版本

### 性能优化

- 大型 DWG 文件可能需要较长渲染时间
- 建议在后台线程执行渲染操作
- 考虑实现渲染缓存机制

### 错误处理

- 应用包含完整的错误处理机制
- 渲染失败时会自动回退到 WebView 方案
- 提供用户友好的错误提示

## 开发状态

当前代码提供了完整的集成框架，但需要：

1. **实际的 Teigha SDK 实现**: 替换占位符代码
2. **SDK 配置**: 根据你的 SDK 版本调整配置
3. **测试**: 使用实际 DWG 文件测试功能

## 故障排除

### 常见问题

1. **编译错误**: 检查 SDK 路径和库文件
2. **运行时错误**: 确认 SDK 初始化成功
3. **渲染失败**: 检查 DWG 文件格式和权限

### 调试技巧

- 查看 Android Logcat 和 iOS 控制台输出
- 使用调试模式逐步排查问题
- 验证 SDK 版本兼容性

## 下一步

1. 集成实际的 Teigha SDK
2. 添加更多 CAD 格式支持
3. 实现高级渲染选项
4. 添加编辑功能

---

**注意**: 这是一个完整的集成框架，但需要你拥有有效的 Teigha SDK 许可证并正确配置 SDK 路径才能完全工作。
