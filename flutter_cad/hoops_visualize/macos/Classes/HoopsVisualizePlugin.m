#import "HoopsVisualizePlugin.h"
#import "HoopsBridgeWrapper.h"
#import "HoopsPlatformViewFactory.h"

@interface HoopsVisualizePlugin () <FlutterTexture>
@property (nonatomic, strong) NSObject<FlutterTextureRegistry>* textureRegistry;
@property (nonatomic, assign) int64_t textureId;
@property (nonatomic, assign) BOOL isRegistered;
@end

@implementation HoopsVisualizePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"hoops_visualize"
              binaryMessenger:[registrar messenger]];
    HoopsVisualizePlugin* instance = [[HoopsVisualizePlugin alloc] init];
    instance.textureRegistry = [registrar textures];
    instance.isRegistered = NO;
    [registrar addMethodCallDelegate:instance channel:channel];
    
    // 注册PlatformView工厂
    HoopsPlatformViewFactory* factory = [[HoopsPlatformViewFactory alloc] 
        initWithMessenger:[registrar messenger]];
    [registrar registerViewFactory:factory withId:@"hoops_native_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self handleInitialize:call result:result];
    } else if ([@"shutdown" isEqualToString:call.method]) {
        [self handleShutdown:result];
    } else if ([@"loadFile" isEqualToString:call.method]) {
        [self handleLoadFile:call result:result];
    } else if ([@"unloadModel" isEqualToString:call.method]) {
        [self handleUnloadModel:call result:result];
    } else if ([@"setViewOperation" isEqualToString:call.method]) {
        [self handleSetViewOperation:call result:result];
    } else if ([@"resetView" isEqualToString:call.method]) {
        [self handleResetView:result];
    } else if ([@"fitView" isEqualToString:call.method]) {
        [self handleFitView:result];
    } else if ([@"getTextureId" isEqualToString:call.method]) {
        [self handleGetTextureId:result];
    } else if ([@"setViewportSize" isEqualToString:call.method]) {
        [self handleSetViewportSize:call result:result];
    } else if ([@"handlePointerEvent" isEqualToString:call.method]) {
        [self handlePointerEvent:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleInitialize:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSString* license = args[@"license"];
    
    if (!license) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"License is required"
                                   details:nil]);
        return;
    }
    
    BOOL success = [HoopsBridgeWrapper initializeWithLicense:license];
    
    if (success && !self.isRegistered) {
        self.textureId = [self.textureRegistry registerTexture:self];
        self.isRegistered = YES;
    }
    
    result(@(success));
}

- (void)handleShutdown:(FlutterResult)result {
    if (self.isRegistered) {
        [self.textureRegistry unregisterTexture:self.textureId];
        self.isRegistered = NO;
    }
    [HoopsBridgeWrapper shutdown];
    result(nil);
}

- (void)handleLoadFile:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSString* filePath = args[@"filePath"];
    
    if (!filePath) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"File path is required"
                                   details:nil]);
        return;
    }
    
    if (![HoopsBridgeWrapper isInitialized]) {
        result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                   message:@"HOOPS engine not initialized"
                                   details:nil]);
        return;
    }
    
    int modelId = [HoopsBridgeWrapper loadFile:filePath];
    if (modelId < 0) {
        result([FlutterError errorWithCode:@"LOAD_FAILED"
                                   message:[HoopsBridgeWrapper getLastError]
                                   details:nil]);
        return;
    }
    
    [self notifyTextureUpdate];
    result(@(modelId));
}

- (void)handleUnloadModel:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSNumber* modelId = args[@"modelId"];
    
    if (!modelId) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"Model ID is required"
                                   details:nil]);
        return;
    }
    
    [HoopsBridgeWrapper unloadModel:[modelId intValue]];
    [self notifyTextureUpdate];
    result(nil);
}

- (void)handleSetViewOperation:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSString* operation = args[@"operation"];
    
    if (!operation) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"Operation is required"
                                   details:nil]);
        return;
    }
    
    [HoopsBridgeWrapper setViewOperation:operation];
    result(nil);
}

- (void)handleResetView:(FlutterResult)result {
    [HoopsBridgeWrapper resetView];
    [self notifyTextureUpdate];
    result(nil);
}

- (void)handleFitView:(FlutterResult)result {
    [HoopsBridgeWrapper fitView];
    [self notifyTextureUpdate];
    result(nil);
}

- (void)handleGetTextureId:(FlutterResult)result {
    if (self.isRegistered) {
        result(@(self.textureId));
    } else {
        result(nil);
    }
}

- (void)handleSetViewportSize:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSNumber* width = args[@"width"];
    NSNumber* height = args[@"height"];
    
    if (!width || !height) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"Width and height are required"
                                   details:nil]);
        return;
    }
    
    [HoopsBridgeWrapper setViewportSizeWithWidth:[width intValue] height:[height intValue]];
    [self notifyTextureUpdate];
    result(nil);
}

- (void)handlePointerEvent:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* args = call.arguments;
    NSString* type = args[@"type"];
    NSNumber* x = args[@"x"];
    NSNumber* y = args[@"y"];
    
    if (!type || !x || !y) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"Event type and position are required"
                                   details:nil]);
        return;
    }
    
    double deltaX = [args[@"deltaX"] doubleValue];
    double deltaY = [args[@"deltaY"] doubleValue];
    double scale = args[@"scale"] ? [args[@"scale"] doubleValue] : 1.0;
    
    [HoopsBridgeWrapper handlePointerEventWithType:type
                                                 x:[x doubleValue]
                                                 y:[y doubleValue]
                                            deltaX:deltaX
                                            deltaY:deltaY
                                             scale:scale];
    [self notifyTextureUpdate];
    result(nil);
}

- (void)notifyTextureUpdate {
    if (self.isRegistered) {
        [self.textureRegistry textureFrameAvailable:self.textureId];
    }
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = [HoopsBridgeWrapper getPixelBuffer];
    if (pixelBuffer) {
        CVPixelBufferRetain(pixelBuffer);
    }
    return pixelBuffer;
}

@end
