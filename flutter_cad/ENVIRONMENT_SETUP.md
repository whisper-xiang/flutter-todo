# Flutter CAD 环境配置说明

## 环境配置

本项目支持三种环境配置：`dev`（开发）、`test`（测试）、`prod`（生产）。

### 环境配置文件

环境配置位于 `lib/config/environment_config.dart`：

- **dev**: 开发环境，启用调试模式，详细日志
- **test**: 测试环境，启用调试模式，信息级别日志  
- **prod**: 生产环境，关闭调试模式，仅错误日志

### 使用方法

#### 1. 命令行运行

```bash
# 开发环境
./scripts/run_dev.sh

# 测试环境  
./scripts/run_test.sh

# 生产环境
./scripts/run_prod.sh
```

#### 2. 手动指定环境

```bash
flutter run --dart-define=FLUTTER_FLAVOR=dev
flutter run --dart-define=FLUTTER_FLAVOR=test  
flutter run --dart-define=FLUTTER_FLAVOR=prod
```

#### 3. 代码中使用

```dart
import 'config/app_flavor.dart';

// 获取当前环境
print(AppFlavor.currentEnvironment);

// 获取API地址
print(AppFlavor.apiBaseUrl);

// 判断环境
if (AppFlavor.isDev) {
  // 开发环境逻辑
}
```

### 环境特性

- **dev**: 显示环境横幅，调试模式，详细日志
- **test**: 显示环境横幅，调试模式，信息日志
- **prod**: 无横幅，无调试模式，仅错误日志

### 构建发布

```bash
# 开发构建
flutter build apk --debug --dart-define=FLUTTER_FLAVOR=dev

# 生产构建
flutter build apk --release --dart-define=FLUTTER_FLAVOR=prod
```
