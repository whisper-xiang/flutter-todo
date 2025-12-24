<!--
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-23 09:26:27
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2025-12-24 11:29:42
 * @FilePath: /flutter_todolist/README.md
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
-->

# flutter_todolist

A new Flutter project.

## 项目结构

```
flutter_todolist/
├── lib/                    # 应用源代码
│   └── main.dart           # 应用入口文件
├── test/                   # 测试代码
│   └── widget_test.dart    # Widget 测试
├── macos/                  # macOS 平台配置
├── ios/                    # iOS 平台配置
├── android/                # Android 平台配置
├── web/                    # Web 平台配置
├── linux/                  # Linux 平台配置
├── windows/                # Windows 平台配置
├── pubspec.yaml            # 项目依赖配置
└── analysis_options.yaml   # Dart 代码分析配置
```

## 运行方式

### macOS 桌面端

```bash
flutter run -d macos
```

### Chrome 网页端

```bash
flutter run -d chrome
```

### iOS 真机（需配置签名）

```bash
flutter run -d "设备名称"
```

> 需要先在 Xcode 中配置开发者证书

### iOS 模拟器

```bash
open -a Simulator
flutter run -d "iPhone 15"
```

> 需要先在 Xcode → Settings → Platforms 中下载 iOS 模拟器运行时

### 多端同时预览

在不同终端窗口中分别运行上述命令即可同时预览多个平台。

## 热重载

运行后按 `r` 热重载，按 `R` 热重启，按 `q` 退出。
