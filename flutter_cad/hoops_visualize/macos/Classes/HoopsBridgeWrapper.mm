#import "HoopsBridgeWrapper.h"
#import "HoopsBridge.h"

@implementation HoopsBridgeWrapper

+ (BOOL)initializeWithLicense:(NSString *)license {
    return HoopsEngine_Initialize([license UTF8String]);
}

+ (void)shutdown {
    HoopsEngine_Shutdown();
}

+ (BOOL)isInitialized {
    return HoopsEngine_IsInitialized();
}

+ (int)loadFile:(NSString *)filePath {
    return HoopsEngine_LoadFile([filePath UTF8String]);
}

+ (void)unloadModel:(int)modelId {
    HoopsEngine_UnloadModel(modelId);
}

+ (void)setViewportSizeWithWidth:(int)width height:(int)height {
    HoopsEngine_SetViewportSize(width, height);
}

+ (void)fitView {
    HoopsEngine_FitView();
}

+ (void)resetView {
    HoopsEngine_ResetView();
}

+ (void)setViewOperation:(NSString *)operation {
    HoopsEngine_SetViewOperation([operation UTF8String]);
}

+ (void)handlePointerEventWithType:(NSString *)type
                                 x:(double)x
                                 y:(double)y
                            deltaX:(double)deltaX
                            deltaY:(double)deltaY
                             scale:(double)scale {
    HoopsEngine_HandlePointerEvent([type UTF8String], x, y, deltaX, deltaY, scale);
}

+ (void)render {
    HoopsEngine_Render();
}

+ (CVPixelBufferRef)getPixelBuffer {
    return HoopsEngine_GetPixelBuffer();
}

+ (NSString *)getLastError {
    const char* error = HoopsEngine_GetLastError();
    return [NSString stringWithUTF8String:error];
}

@end
