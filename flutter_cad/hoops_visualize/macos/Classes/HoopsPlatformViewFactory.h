#import <FlutterMacOS/FlutterMacOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoopsPlatformViewFactory : NSObject <FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger;
- (NSView *)createWithViewIdentifier:(int64_t)viewId arguments:(id _Nullable)args;

@end

NS_ASSUME_NONNULL_END
