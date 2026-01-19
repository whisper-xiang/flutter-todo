#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoopsBridgeWrapper : NSObject

+ (BOOL)initializeWithLicense:(NSString *)license;
+ (void)shutdown;
+ (BOOL)isInitialized;

+ (int)loadFile:(NSString *)filePath;
+ (void)unloadModel:(int)modelId;

+ (void)setViewportSizeWithWidth:(int)width height:(int)height;
+ (void)fitView;
+ (void)resetView;
+ (void)setViewOperation:(NSString *)operation;

+ (void)handlePointerEventWithType:(NSString *)type
                                 x:(double)x
                                 y:(double)y
                            deltaX:(double)deltaX
                            deltaY:(double)deltaY
                             scale:(double)scale;

+ (void)render;
+ (CVPixelBufferRef _Nullable)getPixelBuffer CF_RETURNS_NOT_RETAINED;

+ (NSString *)getLastError;

@end

NS_ASSUME_NONNULL_END
