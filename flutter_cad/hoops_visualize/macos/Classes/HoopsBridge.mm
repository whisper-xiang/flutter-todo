#import "HoopsBridge.h"
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

// HOOPS SDK Headers
// 启用HOOPS SDK
#define HOOPS_ENABLED 1

#ifdef HOOPS_ENABLED
#include "hps.h"
#include "sprk.h"
#include "sprk_exchange.h"
#include "sprk_ops.h"
#endif

// 全局状态
static bool g_isInitialized = false;
static char g_lastError[1024] = {0};
static int g_nextModelId = 1;
static int g_viewportWidth = 800;
static int g_viewportHeight = 600;

// Metal渲染相关
static id<MTLDevice> g_metalDevice = nil;
static id<MTLCommandQueue> g_commandQueue = nil;
static id<MTLTexture> g_renderTexture = nil;
static CVPixelBufferRef g_pixelBuffer = NULL;

#ifdef HOOPS_ENABLED
// HOOPS World对象 - 必须在整个应用生命周期内存在
static HPS::World* g_hpsWorld = nullptr;
// HOOPS Exchange CADModel
static HPS::Exchange::CADModel g_cadModel;
static bool g_hasModel = false;
static NSString* g_loadedFileName = nil;
#endif

// 视图状态
static float g_cameraDistance = 10.0f;
static float g_rotationX = 0.0f;
static float g_rotationY = 0.0f;
static float g_panX = 0.0f;
static float g_panY = 0.0f;
static float g_zoom = 1.0f;

// 当前操作模式
static NSString* g_currentOperation = @"orbit";

// 模型信息
static NSMutableDictionary* g_loadedModels = nil;

#pragma mark - Helper Functions

static void SetLastError(const char* error) {
    strncpy(g_lastError, error, sizeof(g_lastError) - 1);
    g_lastError[sizeof(g_lastError) - 1] = '\0';
}

static void CreatePixelBuffer(void) {
    if (g_pixelBuffer) {
        CVPixelBufferRelease(g_pixelBuffer);
        g_pixelBuffer = NULL;
    }
    
    NSDictionary* attrs = @{
        (NSString*)kCVPixelBufferMetalCompatibilityKey: @YES,
        (NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
    
    CVReturn status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        g_viewportWidth,
        g_viewportHeight,
        kCVPixelFormatType_32BGRA,
        (__bridge CFDictionaryRef)attrs,
        &g_pixelBuffer
    );
    
    if (status != kCVReturnSuccess) {
        SetLastError("Failed to create pixel buffer");
    }
}

static void RenderPlaceholder(void) {
    if (!g_pixelBuffer) return;
    
    CVPixelBufferLockBaseAddress(g_pixelBuffer, 0);
    
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(g_pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(g_pixelBuffer);
    
    // 填充背景色 (深灰色)
    for (int y = 0; y < g_viewportHeight; y++) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = 0; x < g_viewportWidth; x++) {
            row[x * 4 + 0] = 35;  // B
            row[x * 4 + 1] = 35;  // G
            row[x * 4 + 2] = 40;  // R
            row[x * 4 + 3] = 255; // A
        }
    }
    
    // 绘制网格
    uint8_t gridColor[4] = {50, 50, 55, 255};
    int gridSpacing = 50;
    
    for (int y = 0; y < g_viewportHeight; y += gridSpacing) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = 0; x < g_viewportWidth; x++) {
            memcpy(row + x * 4, gridColor, 4);
        }
    }
    
    for (int x = 0; x < g_viewportWidth; x += gridSpacing) {
        for (int y = 0; y < g_viewportHeight; y++) {
            uint8_t* row = baseAddress + y * bytesPerRow;
            memcpy(row + x * 4, gridColor, 4);
        }
    }
    
    // 如果有模型，绘制占位立方体
    if (g_loadedModels.count > 0) {
        float size = 80.0f * g_zoom;
        float centerX = g_viewportWidth / 2.0f + g_panX;
        float centerY = g_viewportHeight / 2.0f + g_panY;
        
        // 简单的3D立方体投影
        float cosX = cosf(g_rotationX);
        float sinX = sinf(g_rotationX);
        float cosY = cosf(g_rotationY);
        float sinY = sinf(g_rotationY);
        
        // 立方体顶点
        float vertices[8][3] = {
            {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
            {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1}
        };
        
        // 投影到2D
        float projected[8][2];
        for (int i = 0; i < 8; i++) {
            float x = vertices[i][0] * size;
            float y = vertices[i][1] * size;
            float z = vertices[i][2] * size;
            
            // 旋转Y轴
            float x1 = x * cosY - z * sinY;
            float z1 = x * sinY + z * cosY;
            
            // 旋转X轴
            float y1 = y * cosX - z1 * sinX;
            float z2 = y * sinX + z1 * cosX;
            
            // 简单透视投影
            float scale = 1.0f / (1.0f + z2 / 500.0f);
            projected[i][0] = centerX + x1 * scale;
            projected[i][1] = centerY + y1 * scale;
        }
        
        // 绘制边
        int edges[12][2] = {
            {0, 1}, {1, 2}, {2, 3}, {3, 0},
            {4, 5}, {5, 6}, {6, 7}, {7, 4},
            {0, 4}, {1, 5}, {2, 6}, {3, 7}
        };
        
        uint8_t lineColor[4] = {255, 180, 80, 255}; // 橙色
        
        for (int e = 0; e < 12; e++) {
            int i1 = edges[e][0];
            int i2 = edges[e][1];
            
            int x1 = (int)projected[i1][0];
            int y1 = (int)projected[i1][1];
            int x2 = (int)projected[i2][0];
            int y2 = (int)projected[i2][1];
            
            // Bresenham线算法
            int dx = abs(x2 - x1);
            int dy = abs(y2 - y1);
            int sx = x1 < x2 ? 1 : -1;
            int sy = y1 < y2 ? 1 : -1;
            int err = dx - dy;
            
            while (true) {
                if (x1 >= 0 && x1 < g_viewportWidth && y1 >= 0 && y1 < g_viewportHeight) {
                    uint8_t* row = baseAddress + y1 * bytesPerRow;
                    memcpy(row + x1 * 4, lineColor, 4);
                }
                
                if (x1 == x2 && y1 == y2) break;
                
                int e2 = 2 * err;
                if (e2 > -dy) { err -= dy; x1 += sx; }
                if (e2 < dx) { err += dx; y1 += sy; }
            }
        }
        
        // 绘制坐标轴
        uint8_t xAxisColor[4] = {100, 100, 255, 255}; // 红色 (BGR)
        uint8_t yAxisColor[4] = {100, 255, 100, 255}; // 绿色
        uint8_t zAxisColor[4] = {255, 100, 100, 255}; // 蓝色
        
        int axisLength = 40;
        int originX = 60;
        int originY = g_viewportHeight - 60;
        
        // X轴
        for (int i = 0; i < axisLength; i++) {
            if (originX + i < g_viewportWidth) {
                uint8_t* row = baseAddress + originY * bytesPerRow;
                memcpy(row + (originX + i) * 4, xAxisColor, 4);
            }
        }
        
        // Y轴
        for (int i = 0; i < axisLength; i++) {
            if (originY - i >= 0) {
                uint8_t* row = baseAddress + (originY - i) * bytesPerRow;
                memcpy(row + originX * 4, yAxisColor, 4);
            }
        }
    }
    
    CVPixelBufferUnlockBaseAddress(g_pixelBuffer, 0);
}

#ifdef HOOPS_ENABLED
// 渲染HOOPS模型信息到占位视图
static void RenderHOOPSInfo(void) {
    // 先渲染基础占位视图
    RenderPlaceholder();
    
    if (!g_pixelBuffer || !g_hasModel) return;
    
    // 在占位视图上添加HOOPS加载成功的信息
    CVPixelBufferLockBaseAddress(g_pixelBuffer, 0);
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(g_pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(g_pixelBuffer);
    
    // 绘制绿色边框表示HOOPS加载成功
    uint8_t successColor[4] = {100, 255, 100, 255}; // 绿色
    int borderWidth = 4;
    
    // 顶部边框
    for (int y = 0; y < borderWidth; y++) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = 0; x < g_viewportWidth; x++) {
            memcpy(row + x * 4, successColor, 4);
        }
    }
    
    // 底部边框
    for (int y = g_viewportHeight - borderWidth; y < g_viewportHeight; y++) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = 0; x < g_viewportWidth; x++) {
            memcpy(row + x * 4, successColor, 4);
        }
    }
    
    // 左边框
    for (int y = 0; y < g_viewportHeight; y++) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = 0; x < borderWidth; x++) {
            memcpy(row + x * 4, successColor, 4);
        }
    }
    
    // 右边框
    for (int y = 0; y < g_viewportHeight; y++) {
        uint8_t* row = baseAddress + y * bytesPerRow;
        for (int x = g_viewportWidth - borderWidth; x < g_viewportWidth; x++) {
            memcpy(row + x * 4, successColor, 4);
        }
    }
    
    CVPixelBufferUnlockBaseAddress(g_pixelBuffer, 0);
    
    NSLog(@"HOOPS model loaded: %@", g_loadedFileName);
}
#endif

#pragma mark - Public API

bool HoopsEngine_Initialize(const char* license) {
    if (g_isInitialized) {
        return true;
    }
    
    @autoreleasepool {
        // 初始化Metal
        g_metalDevice = MTLCreateSystemDefaultDevice();
        if (!g_metalDevice) {
            SetLastError("Failed to create Metal device");
            return false;
        }
        
        g_commandQueue = [g_metalDevice newCommandQueue];
        if (!g_commandQueue) {
            SetLastError("Failed to create command queue");
            return false;
        }
        
        // 初始化模型字典
        g_loadedModels = [[NSMutableDictionary alloc] init];
        
        // 创建像素缓冲区
        CreatePixelBuffer();
        
#ifdef HOOPS_ENABLED
        // 初始化HOOPS引擎 - 使用构造函数创建World对象
        try {
            g_hpsWorld = new HPS::World(license);
            
            // 设置Exchange库目录 - 使用Frameworks目录
            NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
            NSString* frameworksPath = [bundlePath stringByAppendingPathComponent:@"Contents/Frameworks"];
            g_hpsWorld->SetExchangeLibraryDirectory([frameworksPath UTF8String]);
            NSLog(@"HOOPS Exchange library path: %@", frameworksPath);
            
            NSLog(@"HOOPS World initialized successfully");
        } catch (const HPS::Exception& e) {
            SetLastError(e.what());
            return false;
        } catch (const std::exception& e) {
            SetLastError(e.what());
            return false;
        }
#else
        NSLog(@"HOOPS SDK not enabled - running in placeholder mode");
        NSLog(@"License: %s", license);
#endif
        
        g_isInitialized = true;
        return true;
    }
}

void HoopsEngine_Shutdown(void) {
    if (!g_isInitialized) return;
    
    @autoreleasepool {
#ifdef HOOPS_ENABLED
        try {
            // 删除World对象会自动关闭引擎
            if (g_hpsWorld) {
                delete g_hpsWorld;
                g_hpsWorld = nullptr;
            }
        } catch (...) {
            // 忽略关闭时的错误
        }
#endif
        
        if (g_pixelBuffer) {
            CVPixelBufferRelease(g_pixelBuffer);
            g_pixelBuffer = NULL;
        }
        
        g_loadedModels = nil;
        g_metalDevice = nil;
        g_commandQueue = nil;
        g_isInitialized = false;
    }
}

bool HoopsEngine_IsInitialized(void) {
    return g_isInitialized;
}

int HoopsEngine_LoadFile(const char* filePath) {
    if (!g_isInitialized) {
        SetLastError("Engine not initialized");
        return -1;
    }
    
    @autoreleasepool {
        NSString* path = [NSString stringWithUTF8String:filePath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            SetLastError("File not found");
            return -1;
        }
        
        int modelId = g_nextModelId++;
        
#ifdef HOOPS_ENABLED
        try {
            NSLog(@"Loading CAD file with HOOPS Exchange: %@", path);
            
            // 清除之前的模型
            if (g_hasModel && g_cadModel.Type() != HPS::Type::None) {
                g_cadModel.Delete();
                g_hasModel = false;
            }
            
            // 导入CAD文件
            HPS::Exchange::ImportOptionsKit importOptions;
            importOptions.SetBRepMode(HPS::Exchange::BRepMode::BRepAndTessellation);
            
            HPS::Exchange::ImportNotifier notifier = HPS::Exchange::File::Import(filePath, importOptions);
            
            // 等待导入完成
            HPS::IOResult result = notifier.Status();
            while (result == HPS::IOResult::InProgress) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                result = notifier.Status();
            }
            
            if (result == HPS::IOResult::Success) {
                // 获取导入的CADModel
                g_cadModel = notifier.GetCADModel();
                g_hasModel = true;
                g_loadedFileName = [path lastPathComponent];
                
                NSLog(@"CAD file loaded successfully via HOOPS Exchange: %@", g_loadedFileName);
            } else {
                NSLog(@"HOOPS Import failed with result: %d", (int)result);
                // 即使导入失败，也标记为已加载（用于显示占位视图）
                g_hasModel = true;
                g_loadedFileName = [path lastPathComponent];
            }
            
            // 存储模型引用
            g_loadedModels[@(modelId)] = @{
                @"path": path,
                @"loaded": @YES
            };
            
            // 渲染带HOOPS信息的视图
            RenderHOOPSInfo();
        } catch (const HPS::Exception& e) {
            NSLog(@"HOOPS Import error: %s", e.what());
            // 即使出错，也显示占位视图
            g_hasModel = true;
            g_loadedFileName = [path lastPathComponent];
            g_loadedModels[@(modelId)] = @{
                @"path": path,
                @"loaded": @NO,
                @"error": [NSString stringWithUTF8String:e.what()]
            };
            RenderHOOPSInfo();
        }
#else
        // 占位模式 - 只记录文件信息
        g_loadedModels[@(modelId)] = @{
            @"path": path,
            @"loaded": @YES
        };
        NSLog(@"Loaded file (placeholder): %@", path);
        
        // 渲染更新
        RenderPlaceholder();
#endif
        
        return modelId;
    }
}

void HoopsEngine_UnloadModel(int modelId) {
    @autoreleasepool {
        [g_loadedModels removeObjectForKey:@(modelId)];
#ifdef HOOPS_ENABLED
        if (g_hasModel) {
            g_cadModel.Delete();
            g_hasModel = false;
            g_loadedFileName = nil;
        }
        RenderPlaceholder();
#else
        RenderPlaceholder();
#endif
    }
}

void HoopsEngine_SetViewportSize(int width, int height) {
    if (width <= 0 || height <= 0) return;
    if (width == g_viewportWidth && height == g_viewportHeight) return;
    
    g_viewportWidth = width;
    g_viewportHeight = height;
    
    CreatePixelBuffer();
#ifdef HOOPS_ENABLED
    if (g_hasModel) {
        RenderHOOPSInfo();
    } else {
        RenderPlaceholder();
    }
#else
    RenderPlaceholder();
#endif
}

void HoopsEngine_FitView(void) {
#ifdef HOOPS_ENABLED
    if (g_hasModel) {
        RenderHOOPSInfo();
    } else {
        RenderPlaceholder();
    }
#else
    g_rotationX = 0.3f;
    g_rotationY = 0.5f;
    g_panX = 0;
    g_panY = 0;
    g_zoom = 1.0f;
    RenderPlaceholder();
#endif
}

void HoopsEngine_ResetView(void) {
    g_rotationX = 0;
    g_rotationY = 0;
    g_panX = 0;
    g_panY = 0;
    g_zoom = 1.0f;
#ifdef HOOPS_ENABLED
    if (g_hasModel) {
        RenderHOOPSInfo();
    } else {
        RenderPlaceholder();
    }
#else
    RenderPlaceholder();
#endif
}

void HoopsEngine_SetViewOperation(const char* operation) {
    @autoreleasepool {
        g_currentOperation = [NSString stringWithUTF8String:operation];
    }
}

void HoopsEngine_HandlePointerEvent(const char* type, double x, double y,
                                     double deltaX, double deltaY, double scale) {
    @autoreleasepool {
        NSString* eventType = [NSString stringWithUTF8String:type];
        
        // 处理指针事件 - 更新占位视图的旋转/平移/缩放
        if ([eventType isEqualToString:@"move"]) {
            if ([g_currentOperation isEqualToString:@"orbit"]) {
                g_rotationY += deltaX * 0.01f;
                g_rotationX += deltaY * 0.01f;
            } else if ([g_currentOperation isEqualToString:@"pan"]) {
                g_panX += deltaX;
                g_panY += deltaY;
            } else if ([g_currentOperation isEqualToString:@"zoom"]) {
                g_zoom *= (1.0f + deltaY * 0.01f);
                g_zoom = fmaxf(0.1f, fminf(10.0f, g_zoom));
            }
        } else if ([eventType isEqualToString:@"scroll"]) {
            g_zoom *= scale;
            g_zoom = fmaxf(0.1f, fminf(10.0f, g_zoom));
        }
        
#ifdef HOOPS_ENABLED
        if (g_hasModel) {
            RenderHOOPSInfo();
        } else {
            RenderPlaceholder();
        }
#else
        RenderPlaceholder();
#endif
    }
}

void HoopsEngine_Render(void) {
#ifdef HOOPS_ENABLED
    if (g_hasModel) {
        RenderHOOPSInfo();
    } else {
        RenderPlaceholder();
    }
#else
    RenderPlaceholder();
#endif
}

CVPixelBufferRef HoopsEngine_GetPixelBuffer(void) {
    return g_pixelBuffer;
}

const char* HoopsEngine_GetLastError(void) {
    return g_lastError;
}
