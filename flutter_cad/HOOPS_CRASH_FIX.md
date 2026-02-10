# HOOPS二次打开崩溃修复方案

## 问题描述
用户在第二次打开HOOPS渲染页面时遇到崩溃，错误信息为：
```
libc++abi: terminating due to uncaught exception of type HPS::InvalidSpecificationException: World object has already been created
```

## 根本原因分析
1. **HOOPS World对象生命周期管理问题**: HOOPS的World对象是单例，应该在应用整个生命周期内存在，但原代码在页面关闭时删除了它
2. **初始化逻辑缺陷**: 当World对象已存在时，代码仍然尝试创建新的World对象，导致异常
3. **资源清理不当**: shutdown函数过于激进，删除了本应保持的World对象

## 修复方案

### 1. 原生层面修复 (HoopsBridge.mm)

#### 修改初始化函数
```cpp
bool HoopsEngine_Initialize(const char* license) {
    if (g_isInitialized) {
        return true;
    }
    
    // ... 其他初始化代码 ...
    
    try {
        // 如果World对象已经存在，不要重新创建
        if (!g_hpsWorld) {
            g_hpsWorld = new HPS::World(license);
            // ... 设置Exchange库目录 ...
        } else {
            NSLog(@"HOOPS World already exists, reusing existing instance");
        }
    } catch (const HPS::InvalidSpecificationException& e) {
        // 特殊处理 "World object has already been created" 错误
        NSString* errorStr = [NSString stringWithUTF8String:e.what()];
        if ([errorStr containsString:@"already been created"] || [errorStr containsString:@"World object"]) {
            NSLog(@"HOOPS World already created externally, continuing...");
            // 不设置错误，继续执行
        } else {
            SetLastError(e.what());
            return false;
        }
    }
    // ... 其他代码 ...
}
```

#### 修改shutdown函数
```cpp
void HoopsEngine_Shutdown(void) {
    // 不删除World对象，只清理当前加载的模型
    if (g_hpsWorld && g_hasModel) {
        g_cadModel = HPS::Exchange::CADModel();
        g_hasModel = false;
        g_loadedFileName = nil;
        
        if (g_loadedModels) {
            [g_loadedModels removeAllObjects];
        }
        
        NSLog(@"HOOPS model cleared, keeping World object alive");
    }
    
    // ... 其他清理代码 ...
    
    // 注意：不设置 g_isInitialized = false，保持引擎初始化状态
}
```

#### 添加完全关闭函数
```cpp
void HoopsEngine_FullShutdown(void) {
    // 完全删除World对象（仅在应用退出时使用）
    if (g_hpsWorld) {
        delete g_hpsWorld;
        g_hpsWorld = nullptr;
        NSLog(@"HOOPS World fully destroyed");
    }
    // ... 其他完全清理代码 ...
    g_isInitialized = false;
}
```

### 2. Flutter层面修复

#### HoopsNativeView生命周期管理
- 添加 `_isDisposed` 标志防止在组件销毁后执行回调
- 在所有异步操作中检查组件状态
- 改进错误处理逻辑

#### LocalAssetServer资源管理
- 添加并发控制标志防止重复启动/停止
- 改进错误处理和资源清理

## 修复效果

### 修复前
- 第一次打开HOOPS页面：✅ 成功
- 关闭页面后第二次打开：❌ 崩溃
- 错误：World object has already been created

### 修复后
- 第一次打开HOOPS页面：✅ 成功
- 关闭页面后第二次打开：✅ 成功
- 多次重复打开/关闭：✅ 正常
- 内存使用：✅ 正常（World对象复用）

## 关键文件修改

1. **hoops_visualize/macos/Classes/HoopsBridge.h**
   - 添加 `HoopsEngine_FullShutdown` 函数声明

2. **hoops_visualize/macos/Classes/HoopsBridge.mm**
   - 修改 `HoopsEngine_Initialize` 函数，处理World对象已存在的情况
   - 修改 `HoopsEngine_Shutdown` 函数，保留World对象
   - 添加 `HoopsEngine_FullShutdown` 函数用于完全关闭

3. **hoops_visualize/macos/Classes/HoopsBridgeWrapper.h/.mm**
   - 添加 `fullShutdown` 方法

4. **hoops_visualize/macos/Classes/HoopsVisualizePlugin.m**
   - 更新 `handleShutdown` 使用轻量级shutdown

5. **hoops_visualize/lib/hoops_native_view.dart**
   - 添加生命周期管理
   - 改进错误处理

6. **lib/utils/local_asset_server.dart**
   - 添加并发控制
   - 改进资源管理

## 测试验证

✅ 应用正常启动  
✅ HOOPS文件第一次加载正常  
✅ 关闭页面后第二次加载正常  
✅ 多次重复打开/关闭正常  
✅ 内存使用稳定  
✅ 无崩溃或异常  

## 注意事项

1. **World对象生命周期**: World对象现在在应用整个生命周期内存在，符合HOOPS设计原则
2. **内存管理**: 虽然World对象保持存在，但模型数据会在页面关闭时正确清理
3. **应用退出**: 如需完全清理HOOPS资源，可调用 `fullShutdown` 函数
4. **向后兼容**: 修复保持了API的向后兼容性

## 总结

通过正确管理HOOPS World对象的生命周期，并改进初始化和关闭逻辑，成功解决了二次打开崩溃的问题。修复方案既解决了当前问题，又保持了代码的健壮性和可维护性。
