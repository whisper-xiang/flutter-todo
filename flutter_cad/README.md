# Flutter CAD 预览 Demo

一个 Flutter 应用程序，演示 CAD 文件管理和预览功能，采用 Provider 状态管理和 GoRouter 导航架构。

## 功能特性

- **用户认证**：模拟用户登录功能。
- **文件管理**：
  - **云端文件**：查看远程文件列表（模拟数据）。
  - **本地文件**：从本地存储选择和管理文件。
- **文件预览**：
  - 集成 WebView 用于 2D/3D 文件查看。
  - Flutter 与 JavaScript 之间的双向通信。

## 项目结构

项目采用功能优先和分层架构：

```
lib/
├── main.dart              # 应用程序入口，配置 MultiProvider 和主题
├── router.dart            # GoRouter 路由配置，定义所有应用路由
├── models/                # 数据模型
│   └── cad_file.dart      # 文件数据类（云端或本地文件）
├── providers/             # 状态管理（ChangeNotifiers）
│   ├── auth_provider.dart # 管理用户登录状态
│   └── file_provider.dart # 管理云端和本地文件列表
├── screens/               # UI 界面（页面）
│   ├── login_screen.dart      # 用户登录表单
│   ├── home_screen.dart       # 仪表盘，导航到其他模块
│   ├── file_list_screen.dart  # 显示云端文件列表
│   ├── local_file_screen.dart # 本地文件选择器实现
│   └── preview_screen.dart    # WebView 实现，包含 JS 通信
└── services/              # 数据服务 / 仓储层
    └── mock_service.dart  # 模拟后端 API 调用（登录、获取文件）
```

### 核心组件说明

- **`lib/main.dart`**:
  初始化 `MaterialApp` 并用 `MultiProvider` 包裹。这确保可以在 widget 树的任何位置访问 `AuthProvider` 和 `FileProvider`。

- **`lib/router.dart`**:
  使用 `go_router` 的集中式路由逻辑。处理重定向（例如，未认证时重定向到登录页）。

- **`lib/providers/`**:

  - `auth_provider.dart`: 处理认证的业务逻辑。
  - `file_provider.dart`: 包含获取模拟数据和使用 `file_picker` 选择本地文件的逻辑。

- **`lib/screens/preview_screen.dart`**:
  预览功能的核心。实现 `WebViewWidget` 并设置名为 `FlutterChannel` 的 `JavaScriptChannel` 来接收来自 WebView 的消息，使用 `runJavaScript` 向 WebView 发送命令。

## 快速开始

1. **安装依赖**：

   ```bash
   flutter pub get
   ```

2. **运行应用**：
   ```bash
   flutter run
   ```

## 主要依赖

- `provider`: 状态管理
- `go_router`: 声明式路由
- `webview_flutter`: WebView 集成
- `file_picker`: 本地文件选择
- `dio`: HTTP 客户端（为未来扩展准备）
- `path_provider`: 文件系统访问
- `shared_preferences`: 简单数据持久化


xcrun simctl list devices available

xcrun simctl boot 77134BEA-442A-4F99-B9FF-DA0D993398A7

flutter emulators |  open -a Simulator

flutter devices

flutter run -d "iPhone 17 Pro"



我的思路是这样:
基于websdk实现 app、exe桌面程序
功能包括:
1、账户登录
2、获取文件列表
3、选择某一个二维或者三维图纸进行在线览图、测量、批注
4、支持上传新版本、下载



我的想法是:
我们先拿出来一个东西 看着这个东西后，觉得二维这边还有提升空间，自然就会用dwg原生解析器解析会如何，向移动底层要库的时候会更容易


对于 PDF、图片等基本格式，有比较成熟的插件（syncfusion_flutter_pdfviewer 等）可以内嵌预览。
对于 Word/DOCX，社区几乎没有真正成熟、能完美还原格式（字体/样式/表格/图片）的插件。这是 Flutter 生态的一个现实问题。
很多讨论里建议：
	•	用 open_file 调用本地 App
  •	或把 Word 转成 PDF，然后用成熟 PDF 组件预览



| 文件类型 | 常见扩展名 | Flutter 最佳方案 | Flutter 支持程度 | iOS 原生方案 | Android 原生方案 | 内嵌预览 | 外部 App | WebView 渲染 | 能力边界 / 限制 |
|--------|------------|----------------|----------------|---------------|----------------|-----------|-----------|---------------|----------------|
| 图片 | jpg / png / webp | Image / ExtendedImage | ⭐⭐⭐⭐⭐ | UIImageView | ImageView | ✅ | ❌ | ❌ | Flutter 内可控，支持缩放裁剪，不支持专业编辑 |
| GIF | gif | Image / flutter_gif | ⭐⭐⭐⭐ | UIImageView (动图) | ImageView / Glide | ✅ | ❌ | ❌ | 大文件性能有限 |
| 视频 | mp4 / mov | video_player | ⭐⭐⭐⭐ | AVPlayer | MediaPlayer / ExoPlayer | ✅ | ❌ | ❌ | 不支持视频剪辑 |
| 音频 | mp3 / wav | just_audio | ⭐⭐⭐⭐ | AVAudioPlayer | MediaPlayer / ExoPlayer | ✅ | ❌ | ❌ | 不支持音频编辑 |
| PDF | pdf | pdfx / syncfusion_pdfviewer | ⭐⭐⭐⭐ | PDFKit | PdfRenderer / 3rd party | ✅ | ✅ | ✅ | Flutter 内可嵌，复杂 PDF 编辑有限 |
| Word | doc / docx | open_file | ⭐⭐⭐⭐ | Word / Pages | Word / WPS | ⚠️ 内嵌 WebView 可在线预览 | ✅ | ✅（在线 URL） | Flutter 不解析 Office |
| Excel | xls / xlsx | open_file | ⭐⭐⭐⭐ | Excel / Numbers | Excel / WPS | ⚠️ 内嵌 WebView 可在线预览 | ✅ | ✅（在线 URL） | Flutter 不解析 Office |
| PPT | ppt / pptx | open_file | ⭐⭐⭐⭐ | PowerPoint / Keynote | PowerPoint / WPS | ⚠️ 内嵌 WebView 可在线预览 | ✅ | ✅（在线 URL） | 不支持动画控制 |
| TXT | txt | Text / SelectableText | ⭐⭐⭐⭐⭐ | UITextView | TextView | ✅ | ❌ | ✅（HTML 可用） | 无格式能力 |
| Markdown | md | flutter_markdown | ⭐⭐⭐⭐ | UITextView / Markdown Viewer | TextView / Markdown Viewer | ✅ | ⚠️ 可外部打开 | ✅（HTML 可用） | 样式有限 |
| HTML | html | WebView | ⭐⭐⭐⭐ | WKWebView | WebView | ✅ | ⚠️ 可外部浏览器 | ✅ | JS/CSS 支持依赖 WebView |
| ZIP | zip / rar | archive | ⭐⭐⭐ | 系统文件管理器 | 系统文件管理器 / 7-Zip | ❌ | ⚠️ 外部查看器 | ❌ | Flutter 不做文件管理器 |
| CSV | csv | csv + Table | ⭐⭐⭐ | Numbers / Excel | Excel / WPS | ✅ | ⚠️ 可外部打开 | ⚠️ WebView | 大文件性能有限 |
| JSON | json | 自解析 / 可视化 | ⭐⭐⭐⭐ | Xcode JSON Viewer / App | Android Studio JSON Viewer / App | ✅ | ⚠️ 可外部打开 | ⚠️ WebView | Flutter 内解析可控 |
| DWG | dwg | ❌ | ⭐ | AutoCAD / CAD App | AutoCAD / CAD App | ❌ | ✅ | ❌ | Flutter 无 CAD 支持 |
| PSD | psd | ❌ | ⭐ | Photoshop / Affinity | Photoshop / Affinity | ❌ | ✅ | ❌ | Flutter 无原生 PSD 渲染 |