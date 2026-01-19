#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoopsRenderView : NSView

- (BOOL)initializeWithLicense:(NSString *)license;
- (void)shutdown;
- (BOOL)loadFile:(NSString *)filePath;
- (void)fitView;
- (void)resetView;

@end

NS_ASSUME_NONNULL_END
