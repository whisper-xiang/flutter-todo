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

flutter emulators

flutter devices

flutter run -d "iPhone 17 Pro"