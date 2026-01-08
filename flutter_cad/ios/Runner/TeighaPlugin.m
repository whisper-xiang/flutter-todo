#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TeighaPlugin : NSObject<FlutterPlugin>
@end

@implementation TeighaPlugin {
    BOOL _isInitialized;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"teigha_sdk"
              binaryMessenger:[registrar messenger]];
    TeighaPlugin* instance = [[TeighaPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self initializeSDK:result];
    } else if ([@"renderDwgToImage" isEqualToString:call.method]) {
        [self renderDwgToImage:call result:result];
    } else if ([@"getDwgInfo" isEqualToString:call.method]) {
        [self getDwgInfo:call result:result];
    } else if ([@"getLayers" isEqualToString:call.method]) {
        [self getLayers:call result:result];
    } else if ([@"cleanup" isEqualToString:call.method]) {
        [self cleanupSDK:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initializeSDK:(FlutterResult)result {
    @try {
        if (_isInitialized) {
            NSLog(@"Teigha SDK already initialized");
            result(nil);
            return;
        }

        // TODO: Initialize Teigha SDK
        // Example (actual implementation depends on Teigha SDK setup):
        // [self initializeTeighaNative];
        
        _isInitialized = YES;
        NSLog(@"Teigha SDK initialized successfully");
        result(nil);
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to initialize Teigha SDK: %@", exception.reason);
        result([FlutterError errorWithCode:@"INIT_ERROR"
                                   message:@"Failed to initialize Teigha SDK"
                                   details:exception.reason]);
    }
}

- (void)cleanupSDK:(FlutterResult)result {
    @try {
        if (!_isInitialized) {
            result(nil);
            return;
        }

        // TODO: Cleanup Teigha SDK
        // [self cleanupTeighaNative];
        
        _isInitialized = NO;
        NSLog(@"Teigha SDK cleaned up successfully");
        result(nil);
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to cleanup Teigha SDK: %@", exception.reason);
        result([FlutterError errorWithCode:@"CLEANUP_ERROR"
                                   message:@"Failed to cleanup Teigha SDK"
                                   details:exception.reason]);
    }
}

- (void)renderDwgToImage:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        if (!_isInitialized) {
            result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                       message:@"Teigha SDK not initialized"
                                       details:nil]);
            return;
        }

        NSString* filePath = call.arguments[@"filePath"];
        NSNumber* width = call.arguments[@"width"] ?: @1024;
        NSNumber* height = call.arguments[@"height"] ?: @768;
        NSString* format = call.arguments[@"format"] ?: @"png";

        if (!filePath) {
            result([FlutterError errorWithCode:@"INVALID_ARGS"
                                       message:@"File path is required"
                                       details:nil]);
            return;
        }

        NSLog(@"Rendering DWG: %@, size: %@x%@, format: %@", filePath, width, height, format);

        // TODO: Implement actual DWG rendering using Teigha SDK
        // This is a placeholder implementation
        NSData* imageData = [self renderDwgToImageNative:filePath 
                                                    width:width.intValue 
                                                   height:height.intValue 
                                                   format:format];

        if (imageData) {
            FlutterStandardTypedData* flutterData = [FlutterStandardTypedData typedDataWithBytes:imageData];
            result(flutterData);
            NSLog(@"DWG rendering completed successfully");
        } else {
            result([FlutterError errorWithCode:@"RENDER_ERROR"
                                       message:@"Failed to render DWG file"
                                       details:nil]);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to render DWG: %@", exception.reason);
        result([FlutterError errorWithCode:@"RENDER_ERROR"
                                   message:@"Failed to render DWG file"
                                   details:exception.reason]);
    }
}

- (void)getDwgInfo:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        if (!_isInitialized) {
            result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                       message:@"Teigha SDK not initialized"
                                       details:nil]);
            return;
        }

        NSString* filePath = call.arguments[@"filePath"];
        if (!filePath) {
            result([FlutterError errorWithCode:@"INVALID_ARGS"
                                       message:@"File path is required"
                                       details:nil]);
            return;
        }

        NSLog(@"Getting DWG info for: %@", filePath);

        // TODO: Implement actual DWG info extraction using Teigha SDK
        // This is a placeholder implementation
        NSDictionary* info = [self getDwgInfoNative:filePath];

        if (info) {
            result(info);
            NSLog(@"DWG info retrieved successfully");
        } else {
            result([FlutterError errorWithCode:@"INFO_ERROR"
                                       message:@"Failed to get DWG info"
                                       details:nil]);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to get DWG info: %@", exception.reason);
        result([FlutterError errorWithCode:@"INFO_ERROR"
                                   message:@"Failed to get DWG info"
                                   details:exception.reason]);
    }
}

- (void)getLayers:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        if (!_isInitialized) {
            result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                       message:@"Teigha SDK not initialized"
                                       details:nil]);
            return;
        }

        NSString* filePath = call.arguments[@"filePath"];
        if (!filePath) {
            result([FlutterError errorWithCode:@"INVALID_ARGS"
                                       message:@"File path is required"
                                       details:nil]);
            return;
        }

        NSLog(@"Getting layers for: %@", filePath);

        // TODO: Implement actual layer extraction using Teigha SDK
        // This is a placeholder implementation
        NSArray<NSString*>* layers = [self getLayersNative:filePath];

        if (layers) {
            result(layers);
            NSLog(@"Layers retrieved successfully: %lu layers", (unsigned long)layers.count);
        } else {
            result([FlutterError errorWithCode:@"LAYERS_ERROR"
                                       message:@"Failed to get layers"
                                       details:nil]);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to get layers: %@", exception.reason);
        result([FlutterError errorWithCode:@"LAYERS_ERROR"
                                   message:@"Failed to get layers"
                                   details:exception.reason]);
    }
}

// Native methods - these would be implemented in Objective-C++ with Teigha SDK
- (NSData*)renderDwgToImageNative:(NSString*)filePath 
                            width:(int)width 
                           height:(int)height 
                           format:(NSString*)format {
    // TODO: Implement actual DWG rendering using Teigha SDK
    // This is a placeholder implementation that creates a simple test image
    
    int imageSize = width * height * 4; // RGBA
    unsigned char* imageData = (unsigned char*)malloc(imageSize);
    
    // Generate a simple test pattern (gradient)
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int index = (y * width + x) * 4;
            imageData[index] = (x * 255) / width;     // R
            imageData[index + 1] = (y * 255) / height; // G
            imageData[index + 2] = 128;                // B
            imageData[index + 3] = 255;                // A
        }
    }
    
    NSData* result = [NSData dataWithBytesNoCopy:imageData length:imageSize freeWhenDone:YES];
    return result;
}

- (NSDictionary*)getDwgInfoNative:(NSString*)filePath {
    // TODO: Implement actual DWG info extraction using Teigha SDK
    // This is a placeholder implementation
    return @{
        @"version": @"AC1032", // AutoCAD 2018
        @"author": @"Unknown",
        @"created": @"2024-01-01",
        @"modified": @"2024-01-01",
        @"units": @"Millimeters"
    };
}

- (NSArray<NSString*>*)getLayersNative:(NSString*)filePath {
    // TODO: Implement actual layer extraction using Teigha SDK
    // This is a placeholder implementation
    return @[@"0", @"Layer1", @"Layer2", @"Dimensions", @"Text", @"Hatch"];
}

@end
