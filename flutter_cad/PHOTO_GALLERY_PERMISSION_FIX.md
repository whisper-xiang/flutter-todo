# 相册权限问题修复

## 问题描述
用户点击相册访问时，如果权限被拒绝，应用只显示错误消息但没有提供开启权限的路径。在Android真机上甚至没有权限提示。

## 解决方案

### 1. 添加Android权限声明
- 在 `android/app/src/main/AndroidManifest.xml` 中添加必要的权限：
  - `READ_EXTERNAL_STORAGE` - Android 12及以下版本的存储权限
  - `READ_MEDIA_IMAGES` - Android 13+的媒体图片权限
  - `CAMERA` - 相机权限

### 2. 修改 `_accessPhotoLibrary()` 方法
- 在 `lib/screens/home/components/cloud_files_tab.dart` 文件中
- 添加平台检测，区分Android版本：
  - Android 13+ (API 33+): 使用 `Permission.photos`
  - Android 12及以下: 使用 `Permission.storage`
  - iOS: 使用 `Permission.photos`
- 添加了对 `isPermanentlyDenied` 状态的检查
- 当权限被永久拒绝时，调用 `_showSettingsDialog('相册')` 引导用户到设置页面
- 在权限被拒绝的SnackBar中添加"去设置"按钮

### 3. 添加Android版本检测方法
- 新增 `_isAndroid13OrHigher()` 方法
- 使用 `DeviceInfoPlugin` 检测Android SDK版本
- 根据版本选择合适的权限API

### 4. 优化 `_showSettingsDialog()` 方法
- 为相册权限提供更准确的设置路径
- 区分 iOS 和 Android 平台的不同设置路径：
  - iOS: 设置 → 隐私与安全性 → 照片 → 选择此应用 → 读取和写入
  - Android: 设置 → 应用 → 此应用 → 权限 → 存储权限 → 允许
- 保持"去设置"按钮，直接调用 `openAppSettings()` 打开应用设置

## 修改的文件
- `android/app/src/main/AndroidManifest.xml` - 添加权限声明
- `lib/screens/home/components/cloud_files_tab.dart` - 修改权限处理逻辑

## 测试
- 添加了权限状态测试文件 `test/photo_gallery_permission_test.dart`
- 添加了Android权限测试文件 `test/android_permission_test.dart`
- 验证了不同权限状态和Android版本的处理逻辑
- 应用构建成功，无编译错误

## 使用流程
1. 用户点击"相册访问"
2. 应用根据Android版本请求相应权限：
   - Android 13+: 请求照片权限
   - Android 12-: 请求存储权限
3. 如果权限被永久拒绝，显示设置对话框
4. 如果权限被拒绝，显示带"去设置"按钮的SnackBar
5. 用户点击"去设置"直接跳转到应用设置页面
6. 用户在设置中开启相册权限
7. 返回应用后可正常访问相册

## 依赖包
- `permission_handler: ^12.0.1` - 权限管理
- `image_picker: ^1.0.7` - 图片选择
- `app_settings: ^7.0.0` - 打开应用设置
- `device_info_plus: ^10.1.0` - 设备信息检测

## Android版本兼容性
- ✅ Android 13+ (API 33+): 使用新的媒体权限API
- ✅ Android 12及以下: 使用传统存储权限
- ✅ iOS: 使用照片权限

## 调试功能
- 新增权限调试工具 `PermissionDebugHelper`
- 权限被拒绝时自动显示调试对话框
- 显示详细的权限状态和设备信息
- 提供直接跳转到设置的快捷方式

## 设置页面权限选项问题
如果Android设置页面中没有显示相册权限选项，请检查：
1. AndroidManifest.xml中的权限声明是否正确
2. targetSdkVersion是否与权限声明匹配
3. 是否使用了正确的权限API（Android 13+需要媒体权限）
4. 应用是否正确请求了运行时权限

详细调试指南请参考：`ANDROID_PERMISSION_DEBUG_GUIDE.md`
