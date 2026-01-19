#import "HoopsPlatformViewFactory.h"
#import "HoopsRenderView.h"

@interface HoopsPlatformView : NSObject
@property (nonatomic, strong) HoopsRenderView *hoopsView;
@property (nonatomic, strong) FlutterMethodChannel *channel;
@end

@implementation HoopsPlatformView

- (instancetype)initWithFrame:(NSRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(id<FlutterBinaryMessenger>)messenger {
    self = [super init];
    if (self) {
        _hoopsView = [[HoopsRenderView alloc] initWithFrame:frame];
        
        // 创建方法通道
        NSString *channelName = [NSString stringWithFormat:@"hoops_visualize/view_%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName
                                               binaryMessenger:messenger];
        
        __weak HoopsPlatformView *weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        
        // 如果传入了初始化参数
        if (args && [args isKindOfClass:[NSDictionary class]]) {
            NSDictionary *params = (NSDictionary *)args;
            NSString *license = params[@"license"];
            if (license) {
                [_hoopsView initializeWithLicense:license];
            }
        }
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        NSString *license = call.arguments[@"license"];
        BOOL success = [_hoopsView initializeWithLicense:license];
        result(@(success));
    } else if ([@"loadFile" isEqualToString:call.method]) {
        NSString *filePath = call.arguments[@"filePath"];
        BOOL success = [_hoopsView loadFile:filePath];
        result(@(success));
    } else if ([@"fitView" isEqualToString:call.method]) {
        [_hoopsView fitView];
        result(nil);
    } else if ([@"resetView" isEqualToString:call.method]) {
        [_hoopsView resetView];
        result(nil);
    } else if ([@"shutdown" isEqualToString:call.method]) {
        [_hoopsView shutdown];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSView *)view {
    return _hoopsView;
}

- (void)dealloc {
    [_hoopsView shutdown];
}

@end

@interface HoopsPlatformViewFactory ()
@property (nonatomic, weak) id<FlutterBinaryMessenger> messenger;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, HoopsPlatformView*> *views;
@end

@implementation HoopsPlatformViewFactory

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
        _views = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSView *)createWithViewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    HoopsPlatformView *platformView = [[HoopsPlatformView alloc] initWithFrame:frame
                                                                viewIdentifier:viewId
                                                                     arguments:args
                                                               binaryMessenger:_messenger];
    // 保持对platformView的引用，防止被释放
    _views[@(viewId)] = platformView;
    return [platformView view];
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

@end
