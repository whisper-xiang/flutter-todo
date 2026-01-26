# 文档和文件访问权限增强指南

## 📋 权限增强概述

为了提供更全面的文档和文件访问功能，我们增强了应用的权限配置，支持更多类型的文件访问和更广泛的存储空间访问。

## 🔧 Android权限增强

### 新增权限配置

#### 1. 分区存储权限
```xml
<!-- Android 11+ 分区存储权限 -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
                 tools:ignore="ScopedStorage" />
```

#### 2. 完整媒体权限
```xml
<!-- Android 13+ 使用媒体权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_DOCUMENTS" />
```

#### 3. 特定目录访问权限
```xml
<!-- 特定目录访问权限 -->
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_DOWNLOAD_MANAGER" />
```

#### 4. 传统存储权限
```xml
<!-- 文档和文件访问权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
```

### Android版本适配

#### Android 13+ (API 33+)
- ✅ **媒体权限**: READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, READ_MEDIA_AUDIO, READ_MEDIA_DOCUMENTS
- ✅ **管理权限**: MANAGE_EXTERNAL_STORAGE (可选，用于更广泛访问)

#### Android 11-12 (API 30-32)
- ✅ **存储权限**: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
- ✅ **管理权限**: MANAGE_EXTERNAL_STORAGE (可选)

#### Android 10及以下 (API 29-)
- ✅ **存储权限**: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE

## 🍎 iOS权限增强

### 新增权限配置

#### 1. 文档目录访问
```xml
<key>NSDocumentsFolderUsageDescription</key>
<string>此应用需要访问文档文件夹以读取和保存CAD文件、PDF文档和其他工作文件</string>
```

#### 2. 桌面目录访问
```xml
<key>NSDesktopFolderUsageDescription</key>
<string>此应用需要访问桌面文件夹以读取和保存CAD文件、PDF文档和其他工作文件</string>
```

#### 3. 下载目录访问
```xml
<key>NSDownloadsFolderUsageDescription</key>
<string>此应用需要访问下载文件夹以读取和保存CAD文件、PDF文档和其他工作文件</string>
```

#### 4. 媒体库访问
```xml
<key>NSPhotosLibraryUsageDescription</key>
<string>此应用需要访问照片库以导入图片文件用于CAD项目和文档</string>
```

#### 5. 相机访问
```xml
<key>NSCameraUsageDescription</key>
<string>此应用需要访问摄像头以拍摄照片用于CAD项目和文档</string>
```

#### 6. 麦克风访问
```xml
<key>NSMicrophoneUsageDescription</key>
<string>此应用需要访问麦克风以录制音频注释和说明</string>
```

#### 7. 系统管理权限
```xml
<key>NSSystemAdministrationUsageDescription</key>
<string>此应用需要系统管理权限以执行高级文件操作</string>
```

#### 8. Apple事件访问
```xml
<key>NSAppleEventsUsageDescription</key>
<string>此应用需要访问Apple事件以与其他应用程序集成</string>
```

## 🚀 增强的权限处理逻辑

### Android权限检查
```dart
// Android 13+ 需要媒体权限
var storageStatus = await Permission.storage.status;
var mediaImagesStatus = await Permission.photos.status;
var mediaVideoStatus = await Permission.videos.status;
var mediaAudioStatus = await Permission.audio.status;
var manageStorageStatus = await Permission.manageExternalStorage.status;

// 检查各种权限状态
List<Permission> deniedPermissions = [];

if (storageStatus.isDenied) deniedPermissions.add(Permission.storage);
if (mediaImagesStatus.isDenied) deniedPermissions.add(Permission.photos);
if (mediaVideoStatus.isDenied) deniedPermissions.add(Permission.videos);
if (mediaAudioStatus.isDenied) deniedPermissions.add(Permission.audio);

// 批量请求权限
Map<Permission, PermissionStatus> results = await deniedPermissions.request();
```

### iOS权限检查
```dart
// iOS权限检查
var photosStatus = await Permission.photos.status;

if (photosStatus.isDenied) {
  photosStatus = await Permission.photos.request();
  if (photosStatus.isDenied) {
    _showPermissionDialog('照片权限', '需要照片权限才能访问文档和文件');
    return;
  }
}
```

## 📁 支持的文件类型扩展

### CAD和3D文件
- **DWG**: AutoCAD绘图文件
- **DXF**: AutoCAD交换格式
- **OCF**: 其他CAD格式
- **OBJ**: 3D模型文件
- **HSF**: HOOPS流格式
- **STL**: 3D打印文件
- **STEP**: STEP格式3D文件
- **IGES**: IGES格式3D文件
- **FBX**: FBX格式3D文件
- **DAE**: Collada格式3D文件

### 文档和办公文件
- **PDF**: PDF文档
- **DOC/DOCX**: Word文档
- **XLS/XLSX**: Excel表格
- **PPT/PPTX**: PowerPoint演示
- **TXT**: 纯文本文件
- **MD**: Markdown文档
- **RTF**: 富文本格式
- **ODT/ODS/ODP**: OpenDocument格式

### 设计和图像文件
- **JPG/JPEG**: JPEG图像
- **PNG**: PNG图像
- **GIF**: GIF动画
- **BMP**: BMP位图
- **WEBP**: WebP图像
- **TIFF**: TIFF图像
- **SVG**: 矢量图形
- **PSD**: Photoshop文件
- **AI**: Illustrator文件
- **EPS**: PostScript文件
- **SKETCH**: Sketch设计文件

### 媒体文件
- **MP4**: MP4视频
- **AVI**: AVI视频
- **MOV**: QuickTime视频
- **WMV**: Windows Media视频
- **FLV**: Flash视频
- **MKV**: Matroska视频
- **WEBM**: WebM视频
- **M4V**: iTunes视频
- **3GP**: 3GPP视频
- **MP3**: MP3音频
- **WAV**: WAV音频
- **FLAC**: FLAC无损音频
- **AAC**: AAC音频
- **M4A**: M4A音频
- **OGG**: OGG音频
- **WMA**: WMA音频
- **OPUS**: OPUS音频

### 数据和网页文件
- **JSON**: JSON数据
- **XML**: XML文档
- **HTML/HTM**: HTML网页
- **CSS**: CSS样式表
- **JS**: JavaScript文件
- **CSV**: CSV数据文件

### 压缩文件
- **ZIP**: ZIP压缩包
- **RAR**: RAR压缩包
- **7Z**: 7-Zip压缩包
- **TAR**: TAR归档
- **GZ**: Gzip压缩
- **BZ2**: Bzip2压缩
- **XZ**: XZ压缩

### 安装包文件
- **EXE**: Windows可执行文件
- **DMG**: macOS磁盘映像
- **PKG**: macOS安装包
- **DEB**: Debian包
- **RPM**: RPM包
- **APK**: Android应用包
- **IPA**: iOS应用包

## 🎯 权限使用场景

### 1. 系统存储访问
- 📱 **Android**: 需要存储权限和媒体权限
- 🍎 **iOS**: 需要照片权限
- 📁 **功能**: 访问设备中的所有支持文件类型

### 2. App存储访问
- 📱 **Android**: 无需特殊权限
- 🍎 **iOS**: 无需特殊权限
- 📁 **功能**: 访问应用私有存储空间

### 3. 文档目录访问
- 📱 **Android**: 需要存储权限
- 🍎 **iOS**: 需要文档目录权限
- 📁 **功能**: 访问系统文档目录

### 4. 媒体库访问
- 📱 **Android**: 需要媒体权限
- 🍎 **iOS**: 需要照片库权限
- 📁 **功能**: 访问照片和视频文件

## 🔒 权限安全特性

### 最小权限原则
- ✅ 只请求必要的权限
- ✅ 按需请求权限
- ✅ 用户友好的权限说明

### 权限状态管理
- ✅ 实时权限状态检查
- ✅ 智能权限请求流程
- ✅ 永久拒绝处理

### 用户体验优化
- ✅ 清晰的权限说明
- ✅ 一键跳转设置
- ✅ 详细的设置路径指导

## 📊 权限兼容性

### Android版本支持
| Android版本 | 存储权限 | 媒体权限 | 管理权限 |
|-------------|----------|----------|----------|
| Android 10+ | ✅ | ❌ | ❌ |
| Android 11+ | ✅ | ❌ | ✅ |
| Android 12+ | ✅ | ❌ | ✅ |
| Android 13+ | ❌ | ✅ | ✅ |

### iOS版本支持
| iOS版本 | 照片权限 | 文档权限 | 相机权限 |
|---------|----------|----------|----------|
| iOS 13+ | ✅ | ✅ | ✅ |
| iOS 14+ | ✅ | ✅ | ✅ |
| iOS 15+ | ✅ | ✅ | ✅ |
| iOS 16+ | ✅ | ✅ | ✅ |
| iOS 17+ | ✅ | ✅ | ✅ |

## 🎉 增强效果

现在应用支持：

1. **📁 更广泛的文件类型** - 支持50+种文件格式
2. **🔒 更全面的权限管理** - Android和iOS完整权限支持
3. **📱 更好的版本适配** - 支持Android 10+和iOS 13+
4. **🎯 更智能的权限处理** - 批量权限检查和请求
5. **📋 更详细的权限说明** - 用户友好的权限描述

用户现在可以访问设备中的几乎所有类型的文档和文件！🎉
