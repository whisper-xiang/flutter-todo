#ifndef HoopsBridge_h
#define HoopsBridge_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

#ifdef __cplusplus
extern "C" {
#endif

// HOOPS引擎初始化和关闭
bool HoopsEngine_Initialize(const char* license);
void HoopsEngine_Shutdown(void);
bool HoopsEngine_IsInitialized(void);

// 文件加载
int HoopsEngine_LoadFile(const char* filePath);
void HoopsEngine_UnloadModel(int modelId);

// 视图操作
void HoopsEngine_SetViewportSize(int width, int height);
void HoopsEngine_FitView(void);
void HoopsEngine_ResetView(void);
void HoopsEngine_SetViewOperation(const char* operation);

// 交互事件
void HoopsEngine_HandlePointerEvent(const char* type, double x, double y, 
                                     double deltaX, double deltaY, double scale);

// 渲染
void HoopsEngine_Render(void);
CVPixelBufferRef HoopsEngine_GetPixelBuffer(void);

// 获取错误信息
const char* HoopsEngine_GetLastError(void);

#ifdef __cplusplus
}
#endif

#endif /* HoopsBridge_h */
