# 系统存储和App存储访问功能

## 📱 功能概述

在本地文件标签页的右上角，现在可以通过菜单访问系统存储和App存储空间，实现完整的文件管理功能。

## 🎮 使用方法

### 访问入口
1. 打开 **本地文件** 标签页
2. 点击右上角的 **更多选项** 按钮（三个点）
3. 选择存储访问选项：

#### 🔹 系统存储
- **图标**: 📱 SD存储图标（蓝色）
- **功能**: 访问设备的完整存储空间
- **权限**: 需要存储权限
- **支持**: Android 13+ 媒体权限，Android 12- 存储权限

#### 🔹 App存储
- **图标**: 📁 文件夹图标（绿色）
- **功能**: 访问应用的私有存储空间
- **权限**: 无需特殊权限
- **目录**: 文档目录、临时目录、外部存储

#### 🔹 本地文件管理
- **图标**: 💾 存储图标（橙色）
- **功能**: 跳转到本地文件管理页面
- **权限**: 已有权限

#### 🔹 刷新
- **图标**: 🔄 刷新图标（灰色）
- **功能**: 重新加载文件列表
- **权限**: 无需权限

## 📁 存储目录详解

### App存储目录

#### 📄 文档目录 (Documents)
- **路径**: `/data/data/com.example.app/app_flutter/`
- **用途**: 应用永久数据存储
- **特点**: 应用卸载时会被清除
- **适用**: 用户创建的文件、配置文件

#### 📂 临时目录 (Temporary)
- **路径**: `/data/data/com.example.app/cache/`
- **用途**: 临时文件存储
- **特点**: 系统可能自动清理
- **适用**: 缓存文件、临时下载

#### 📱 外部存储 (External) - Android
- **路径**: `/storage/emulated/0/Android/data/com.example.app/`
- **用途**: 应用外部数据存储
- **特点**: 应用卸载时会被清除
- **适用**: 大文件、用户可访问的数据

## 📋 支持的文件类型

### CAD文件
- **DWG**: AutoCAD绘图文件
- **DXF**: AutoCAD交换格式
- **OCF**: 其他CAD格式
- **OBJ**: 3D模型文件
- **HSF**: HOOPS流格式

### 文档文件
- **PDF**: PDF文档
- **DOC/DOCX**: Word文档
- **XLS/XLSX**: Excel表格
- **PPT/PPTX**: PowerPoint演示

### 媒体文件
- **图片**: JPG, PNG, GIF, BMP, WebP
- **视频**: MP4, AVI, MOV, WMV, FLV, MKV
- **音频**: MP3, WAV, FLAC, AAC, M4A, OGG

### 其他文件
- **文本**: TXT, MD, JSON, XML, HTML, CSV
- **压缩**: ZIP, RAR, 7Z, TAR, GZ

## 🔐 权限管理

### Android权限

#### Android 13+ (API 33+)
```xml
<!-- 媒体权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_DOCUMENTS" />
```

#### Android 12- (API 32-)
```xml
<!-- 存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
```

### iOS权限
- **无需特殊权限**: App存储访问
- **系统存储**: 通过文件选择器访问

## 🚀 使用流程

### 系统存储访问
1. **点击"系统存储"**
2. **权限检查**: 自动检查和请求权限
3. **文件选择**: 打开系统文件选择器
4. **多选支持**: 可同时选择多个文件
5. **文件过滤**: 只显示支持的文件类型
6. **预览打开**: 点击文件直接预览

### App存储访问
1. **点击"App存储"**
2. **目录选择**: 选择要浏览的目录
3. **文件浏览**: 显示目录中的支持文件
4. **文件详情**: 显示文件名、大小、类型
5. **快速预览**: 点击文件直接打开

## 🎯 功能特点

### 智能权限管理
- ✅ 自动检测权限状态
- ✅ 智能权限请求
- ✅ 友好的权限提示
- ✅ 一键跳转设置

### 文件类型过滤
- ✅ 只显示支持的文件类型
- ✅ 按类别组织文件
- ✅ 智能文件识别
- ✅ 优化的文件图标

### 用户体验优化
- ✅ 直观的菜单界面
- ✅ 清晰的目录结构
- ✅ 快速文件预览
- ✅ 完整的错误处理

## 📊 技术实现

### 核心包
- `file_picker: ^10.3.8` - 文件选择器
- `path_provider: ^2.1.5` - 路径获取
- `permission_handler: ^12.0.1` - 权限管理

### 主要方法
```dart
// 系统存储访问
await fp.FilePicker.platform.pickFiles(
  type: fp.FileType.custom,
  allowedExtensions: [...],
  allowMultiple: true,
);

// App存储访问
Directory? appDocDir = await getApplicationDocumentsDirectory();
Directory? appTempDir = await getTemporaryDirectory();
Directory? externalDir = await getExternalStorageDirectory();
```

## 🔒 安全特性

### 权限最小化
- 只请求必要的权限
- App存储无需特殊权限
- 系统存储需要用户授权

### 数据安全
- App存储隔离访问
- 不会访问其他应用数据
- 支持的文件类型限制

### 用户控制
- 完全的文件选择控制
- 可随时撤销权限
- 清晰的权限说明

## 🎉 使用效果

现在用户可以：
- 📱 **访问完整系统存储** - 浏览设备中的所有支持文件
- 📁 **管理App私有存储** - 访问应用的文档、临时、外部存储
- 🔍 **智能文件过滤** - 只显示相关的文件类型
- ⚡ **快速预览** - 点击文件直接打开预览
- 🔐 **安全权限管理** - 智能权限请求和管理

这为用户提供了完整的文件管理体验！🎉
