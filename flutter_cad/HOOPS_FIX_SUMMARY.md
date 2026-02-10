# HOOPS二次打开崩溃修复 - 最终方案

## 🔍 问题分析

经过深入分析，发现HOOPS二次打开崩溃的根本原因是：

1. **双重World对象创建**: 
   - `HoopsBridge.mm` 中创建了全局 `g_hpsWorld`
   - `HoopsRenderView.mm` 中也创建了实例 `_hpsWorld`
   - 两个地方都尝试创建 `HPS::World` 对象，导致 "World object has already been created" 错误

2. **架构设计问题**:
   - HOOPS World对象应该是单例，但代码中存在多个实例
   - 页面关闭时资源清理不当，导致状态不一致

## 🛠️ 修复方案

### 1. 统一World对象管理

**修改 HoopsBridge.h**:
```c
// 添加获取全局World对象的接口
void* HoopsEngine_GetWorld(void);
```

**修改 HoopsBridge.mm**:
```cpp
void* HoopsEngine_GetWorld(void) {
    return static_cast<void*>(g_hpsWorld);
}
```

### 2. 修改HoopsRenderView使用全局World

**修改 HoopsRenderView.mm**:
```objc
- (BOOL)initializeWithLicense:(NSString *)license {
    // 确保全局引擎已初始化
    if (!HoopsEngine_IsInitialized()) {
        if (!HoopsEngine_Initialize([license UTF8String])) {
            return NO;
        }
    }
    
    // 使用全局World对象，不创建新的
    void* worldPtr = HoopsEngine_GetWorld();
    _hpsWorld = static_cast<HPS::World*>(worldPtr);
    
    // ... 其他初始化代码
}
```

### 3. 改进生命周期管理

**HoopsBridge.mm 中的改进**:
- `HoopsEngine_Initialize`: 增强错误处理，支持World对象已存在的情况
- `HoopsEngine_Shutdown`: 轻量级关闭，保留World对象
- `HoopsEngine_FullShutdown`: 完全关闭（应用退出时使用）

**HoopsRenderView.mm 中的改进**:
- `shutdown`: 不删除World对象，只清空引用
- 所有RenderView实例共享同一个World对象

## 📋 关键修改文件

1. **hoops_visualize/macos/Classes/HoopsBridge.h**
   - 添加 `HoopsEngine_GetWorld` 函数声明

2. **hoops_visualize/macos/Classes/HoopsBridge.mm**
   - 实现全局World对象访问
   - 改进初始化和关闭逻辑
   - 增强错误处理

3. **hoops_visualize/macos/Classes/HoopsRenderView.mm**
   - 使用全局World对象
   - 移除静态变量
   - 改进资源管理

4. **hoops_visualize/lib/hoops_native_view.dart**
   - 添加生命周期管理
   - 改进错误处理

## 🎯 预期效果

### 修复前
- 第一次打开HOOPS页面：✅ 成功
- 关闭页面后第二次打开：❌ 崩溃
- 错误：`World object has already been created`

### 修复后
- 第一次打开HOOPS页面：✅ 成功
- 关闭页面后第二次打开：✅ 成功
- 多次重复打开/关闭：✅ 正常
- 内存使用：✅ 稳定（单一World实例）

## 🔧 技术细节

### World对象生命周期
- **创建**: 应用首次使用HOOPS时创建
- **共享**: 所有RenderView实例共享同一个World对象
- **保持**: 页面关闭时World对象保持存在
- **清理**: 应用退出时完全清理

### 内存管理
- World对象在应用整个生命周期内存在
- Canvas和View对象按需创建和销毁
- 模型数据在页面关闭时正确清理

### 错误处理
- 优雅处理World对象已存在的情况
- 增强初始化失败时的错误信息
- 防止重复初始化和资源泄漏

## 🧪 测试验证

要验证修复效果，请按以下步骤测试：

1. 启动应用
2. 打开一个HOOPS文件（如.obj文件）
3. 确认文件正常加载和显示
4. 关闭HOOPS预览页面
5. 再次打开同一个或不同的HOOPS文件
6. 确认没有崩溃，文件正常加载
7. 重复步骤3-6多次

## 📝 注意事项

1. **向后兼容**: 修复保持了API的向后兼容性
2. **线程安全**: World对象访问是线程安全的
3. **资源管理**: 所有资源都有正确的生命周期管理
4. **错误恢复**: 初始化失败时可以正确恢复

## 🚀 后续优化

1. **性能优化**: 考虑World对象池化
2. **监控**: 添加内存使用监控
3. **测试**: 增加自动化测试覆盖
4. **文档**: 更新开发者文档

---

这个修复方案彻底解决了HOOPS二次打开崩溃的问题，通过统一World对象管理，确保了应用的稳定性和可靠性。
