# Android权限调试指南

## 问题现象
在Android真机上，设置页面中没有显示相册权限选项。

## 可能原因和解决方案

### 1. 权限声明问题
**检查文件**: `android/app/src/main/AndroidManifest.xml`

确保包含以下权限：
```xml
<!-- Android 12及以下 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />

<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />
```

### 2. targetSdkVersion问题
**检查文件**: `android/app/build.gradle.kts`

确保targetSdkVersion设置正确：
- 如果targetSdkVersion >= 33 (Android 13)，必须使用新的媒体权限
- 如果targetSdkVersion <= 32，可以使用传统存储权限

### 3. 权限请求时机
确保在运行时动态请求权限，而不是只在Manifest中声明。

### 4. 权限分组问题
Android 13+将媒体权限分为：
- `READ_MEDIA_IMAGES` - 图片访问
- `READ_MEDIA_VIDEO` - 视频访问
- `READ_MEDIA_AUDIO` - 音频访问

需要分别请求这些权限。

## 调试步骤

### 第一步：检查设备信息
使用调试工具查看：
- Android版本
- SDK版本
- 应用权限状态

### 第二步：检查权限状态
在应用中点击"相册访问"后，会自动显示权限调试对话框，显示：
- 相机权限状态
- 照片权限状态  
- 存储权限状态
- 视频权限状态
- 麦克风权限状态

### 第三步：手动检查设置
1. 打开手机设置
2. 找到"应用管理"或"应用和通知"
3. 找到"flutter_cad"应用
4. 查看权限列表

### 第四步：常见问题排查

#### 问题1：设置中没有相册权限选项
**可能原因**：
- targetSdkVersion设置错误
- 权限声明不正确
- 应用未正确请求权限

**解决方案**：
1. 检查AndroidManifest.xml中的权限声明
2. 确保targetSdkVersion与权限声明匹配
3. 重新安装应用

#### 问题2：权限显示为"不允许"但无法更改
**可能原因**：
- 权限被永久拒绝
- 系统策略限制

**解决方案**：
1. 清除应用数据后重试
2. 卸载重装应用
3. 检查系统权限管理设置

#### 问题3：Android 13+特殊处理
**注意事项**：
- 必须使用`READ_MEDIA_IMAGES`而不是`READ_EXTERNAL_STORAGE`
- 需要分别请求图片和视频权限
- 可能需要同时请求多个权限

## 代码调试

### 使用权限调试工具
应用现在包含权限调试功能：
1. 点击"相册访问"
2. 如果权限被拒绝，会自动显示调试对话框
3. 查看详细的权限状态信息

### 手动调用调试
在任何地方都可以调用：
```dart
PermissionDebugHelper.showPermissionStatus(context);
```

## 验证步骤

1. **安装应用**：确保使用最新版本
2. **检查权限**：查看AndroidManifest.xml权限声明
3. **测试功能**：点击相册访问，观察权限请求
4. **查看状态**：使用调试工具查看权限状态
5. **手动设置**：如果需要，手动在系统设置中开启权限

## 常见Android版本权限要求

| Android版本 | SDK版本 | 所需权限 |
|-------------|---------|----------|
| Android 12及以下 | ≤32 | `READ_EXTERNAL_STORAGE` |
| Android 13+ | ≥33 | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` |
| 所有版本 | - | `CAMERA` |

## 联系支持
如果问题仍然存在，请提供：
1. 设备型号和Android版本
2. 权限调试对话框的截图
3. AndroidManifest.xml内容
4. 具体的错误信息
