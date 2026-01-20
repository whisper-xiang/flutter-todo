#import "HoopsRenderView.h"
#import <Metal/Metal.h>

#include "hps.h"
#include "sprk.h"
#include "sprk_exchange.h"
#include "sprk_ops.h"

@interface HoopsRenderView () {
    HPS::World* _hpsWorld;
    HPS::Canvas _canvas;
    HPS::View _view;
    HPS::Model _model;
    HPS::Exchange::CADModel _cadModel;
    BOOL _isInitialized;
    BOOL _hasModel;
}
@end

@implementation HoopsRenderView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _isInitialized = NO;
        _hasModel = NO;
        _hpsWorld = nullptr;
        
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor darkGrayColor] CGColor];
    }
    return self;
}

- (void)dealloc {
    [self shutdown];
}

- (BOOL)initializeWithLicense:(NSString *)license {
    if (_isInitialized) {
        return YES;
    }
    
    @try {
        // 初始化HOOPS World
        _hpsWorld = new HPS::World([license UTF8String]);
        
        // 设置Exchange库目录
        NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString* frameworksPath = [bundlePath stringByAppendingPathComponent:@"Contents/Frameworks"];
        _hpsWorld->SetExchangeLibraryDirectory([frameworksPath UTF8String]);
        NSLog(@"HOOPS Exchange library path: %@", frameworksPath);
        
        // 创建Canvas - 绑定到当前NSView
        HPS::WindowHandle windowHandle = (HPS::WindowHandle)self;
        _canvas = HPS::Factory::CreateCanvas(windowHandle, "HoopsCanvas");
        
        // 创建View
        _view = HPS::Factory::CreateView("MainView");
        
        // 创建Model
        _model = HPS::Factory::CreateModel("MainModel");
        
        // 设置View的Model
        _view.AttachModel(_model);
        
        // 将View附加到Canvas
        _canvas.AttachViewAsLayout(_view);
        
        // 设置背景色
        _view.GetSegmentKey().GetMaterialMappingControl()
            .SetWindowColor(HPS::RGBAColor(0.14f, 0.14f, 0.16f, 1.0f));
        
        // 设置默认相机
        _view.GetSegmentKey().GetCameraControl()
            .SetProjection(HPS::Camera::Projection::Perspective);
        
        // 光源将在模型加载后添加，类似于HOOPS SDK示例
        
        // 添加默认操作符
        HPS::OrbitOperator* orbitOp = new HPS::OrbitOperator(HPS::MouseButtons::ButtonLeft());
        HPS::PanOperator* panOp = new HPS::PanOperator(HPS::MouseButtons::ButtonRight());
        HPS::ZoomOperator* zoomOp = new HPS::ZoomOperator(HPS::MouseButtons::ButtonMiddle());
        
        _view.GetOperatorControl()
            .Push(orbitOp)
            .Push(panOp)
            .Push(zoomOp);
        
        _isInitialized = YES;
        NSLog(@"HOOPS RenderView initialized successfully");
        
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"HOOPS initialization failed: %@", exception.reason);
        return NO;
    }
}

- (void)shutdown {
    if (!_isInitialized) return;
    
    @try {
        if (_hasModel && _cadModel.Type() != HPS::Type::None) {
            _cadModel.Delete();
        }
        
        if (_canvas.Type() != HPS::Type::None) {
            _canvas.Delete();
        }
        
        if (_hpsWorld) {
            delete _hpsWorld;
            _hpsWorld = nullptr;
        }
        
        _isInitialized = NO;
        _hasModel = NO;
    } @catch (NSException *exception) {
        NSLog(@"HOOPS shutdown error: %@", exception.reason);
    }
}

- (BOOL)loadFile:(NSString *)filePath {
    if (!_isInitialized) {
        NSLog(@"HOOPS not initialized");
        return NO;
    }
    
    NSLog(@"Loading file: %@", filePath);
    
    try {
        // 清除之前的模型
        if (_hasModel && _cadModel.Type() != HPS::Type::None) {
            _cadModel.Delete();
            _hasModel = NO;
        }
        _model.GetSegmentKey().Flush();
        
        // 获取文件扩展名
        NSString *extension = [[filePath pathExtension] lowercaseString];
        
        if ([extension isEqualToString:@"hsf"]) {
            // HSF文件使用Stream::File::Import
            NSLog(@"Loading HSF file with Stream::File::Import");
            
            // 检查文件是否存在
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:filePath]) {
                NSLog(@"HSF file does not exist: %@", filePath);
                [self createPlaceholderGeometry];
                _canvas.Update();
                return YES;
            }
            
            try {
                // 创建子段用于导入
                HPS::SegmentKey geometrySegment = _model.GetSegmentKey().Subsegment("HSF_Geometry");
                
                // 设置导入选项
                HPS::Stream::ImportOptionsKit streamOptions;
                streamOptions.SetSegment(geometrySegment);
                
                HPS::Stream::ImportNotifier notifier = HPS::Stream::File::Import([filePath UTF8String], streamOptions);
                notifier.Wait();  // 同步等待完成
                
                HPS::IOResult result = notifier.Status();
                NSLog(@"HSF Import status after wait: %d", (int)result);
                
                if (result == HPS::IOResult::Success) {
                    _hasModel = YES;
                    
                    // 适应视图
                    _view.FitWorld();
                    _canvas.Update();
                    
                    NSLog(@"HSF file loaded successfully: %@", [filePath lastPathComponent]);
                    return YES;
                }
                
                NSLog(@"HSF Import failed with result: %d", (int)result);
            } catch (const HPS::IOException& e) {
                NSLog(@"HSF IOException: %s, result: %d", e.what(), (int)e.result);
            }
        } else {
            // 其他CAD文件使用Exchange::File::Import
            NSLog(@"Loading CAD file with Exchange::File::Import");
            
            HPS::Exchange::ImportOptionsKit importOptions;
            importOptions.SetBRepMode(HPS::Exchange::BRepMode::BRepAndTessellation);
            
            // 为OBJ文件启用材质和纹理加载
            if ([extension isEqualToString:@"obj"]) {
                NSLog(@"Loading OBJ file - Exchange will attempt to load materials and textures by default");
                // TODO: 根据HOOPS版本，可能需要使用其他API来控制材质/纹理加载
                // importOptions.SetLoadTextures(true);
                // importOptions.SetLoadMaterials(true);
                // importOptions.SetLoadAppearance(true);
                
                // 设置纹理搜索路径为文件所在目录
                // NSString* dirPath = [filePath stringByDeletingLastPathComponent];
                // HPS::UTF8Array searchPaths;
                // searchPaths.push_back([dirPath UTF8String]);
                // importOptions.SetTextureSearchPaths(searchPaths);
                // importOptions.SetMaterialSearchPaths(searchPaths);
                
                NSLog(@"OBJ file directory: %@", [filePath stringByDeletingLastPathComponent]);
            }
            
            HPS::Exchange::ImportNotifier notifier = HPS::Exchange::File::Import([filePath UTF8String], importOptions);
            
            // 等待导入完成
            HPS::IOResult result = notifier.Status();
            while (result == HPS::IOResult::InProgress) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                result = notifier.Status();
            }
            
            if (result == HPS::IOResult::Success) {
                // 获取导入的CADModel
                _cadModel = notifier.GetCADModel();
                
                if (_cadModel.Type() != HPS::Type::None) {
                    _hasModel = YES;
                    
                    // 将CAD模型附加到Model
                    _cadModel.GetModel().GetSegmentKey().MoveTo(_model.GetSegmentKey());
                    
                    // 为OBJ文件启用更好的光照和材质效果
                    if ([extension isEqualToString:@"obj"]) {
                        NSLog(@"Loading OBJ with model-based lighting");
                        
                        // 使用基础的光照设置
                        HPS::SegmentKey modelSegment = _model.GetSegmentKey();
                        
                        // 启用光照
                        try {
                            modelSegment.GetVisibilityControl().SetLights(true);
                            NSLog(@"Enabled lights for OBJ");
                        } catch (...) {
                            NSLog(@"SetLights not available");
                        }
                        
                        // 由于MTL文件中Kd都是0.00 0.00 0.00，需要设置备用颜色
                        try {
                            // 为模型段设置备用颜色
                            modelSegment.GetMaterialMappingControl().SetFaceColor(HPS::RGBAColor(0.8, 0.8, 0.8, 1));
                            modelSegment.GetMaterialMappingControl().SetBackFaceColor(HPS::RGBAColor(0.8, 0.8, 0.8, 1));
                            
                            NSLog(@"Set fallback colors for missing textures");
                        } catch (...) {
                            NSLog(@"Failed to set fallback colors");
                        }
                        
                        // 在模型段上添加光源，类似于HOOPS SDK示例
                        try {
                            // 主光源（从右上方）
                            modelSegment.InsertDistantLight(HPS::Vector(1, 1, 0));
                            // 侧光源（从左侧）
                            modelSegment.InsertDistantLight(HPS::Vector(-1, 0, 0));
                            // 底部光源（从下方）
                            modelSegment.InsertDistantLight(HPS::Vector(0, 1, 0));
                            NSLog(@"Added model-based lights for OBJ");
                        } catch (...) {
                            NSLog(@"Failed to add model lights");
                        }
                    }
                    
                    // 适应视图
                    _view.FitWorld();
                    _canvas.Update();
                    
                    NSLog(@"CAD file loaded successfully: %@", [filePath lastPathComponent]);
                    return YES;
                }
            }
            
            NSLog(@"Exchange Import result: %d", (int)result);
        }
        
        // 导入失败，显示占位几何体
        [self createPlaceholderGeometry];
        _canvas.Update();
        return YES;
        
    } catch (const HPS::Exception& e) {
        NSLog(@"HOOPS load file error: %s", e.what());
        [self createPlaceholderGeometry];
        _canvas.Update();
        return YES;
    } catch (...) {
        NSLog(@"HOOPS load file unknown error");
        [self createPlaceholderGeometry];
        _canvas.Update();
        return YES;
    }
}

- (void)createPlaceholderGeometry {
    // 创建一个简单的立方体作为占位
    HPS::SegmentKey segmentKey = _model.GetSegmentKey();
    
    // 清除之前的内容
    segmentKey.Flush();
    
    // 创建立方体顶点
    HPS::PointArray points;
    float size = 1.0f;
    points.push_back(HPS::Point(-size, -size, -size));
    points.push_back(HPS::Point(size, -size, -size));
    points.push_back(HPS::Point(size, size, -size));
    points.push_back(HPS::Point(-size, size, -size));
    points.push_back(HPS::Point(-size, -size, size));
    points.push_back(HPS::Point(size, -size, size));
    points.push_back(HPS::Point(size, size, size));
    points.push_back(HPS::Point(-size, size, size));
    
    // 创建立方体面
    HPS::IntArray faceList;
    // 前面
    faceList.push_back(4); faceList.push_back(0); faceList.push_back(1); faceList.push_back(2); faceList.push_back(3);
    // 后面
    faceList.push_back(4); faceList.push_back(4); faceList.push_back(7); faceList.push_back(6); faceList.push_back(5);
    // 左面
    faceList.push_back(4); faceList.push_back(0); faceList.push_back(3); faceList.push_back(7); faceList.push_back(4);
    // 右面
    faceList.push_back(4); faceList.push_back(1); faceList.push_back(5); faceList.push_back(6); faceList.push_back(2);
    // 顶面
    faceList.push_back(4); faceList.push_back(3); faceList.push_back(2); faceList.push_back(6); faceList.push_back(7);
    // 底面
    faceList.push_back(4); faceList.push_back(0); faceList.push_back(4); faceList.push_back(5); faceList.push_back(1);
    
    // 插入Shell
    segmentKey.InsertShell(points, faceList);
    
    // 设置颜色
    segmentKey.GetMaterialMappingControl().SetFaceColor(HPS::RGBAColor(0.7f, 0.5f, 0.3f, 1.0f));
    segmentKey.GetMaterialMappingControl().SetEdgeColor(HPS::RGBAColor(0.0f, 0.0f, 0.0f, 1.0f));
    
    // 显示边
    segmentKey.GetVisibilityControl().SetEdges(true);
    
    _hasModel = YES;
    _view.FitWorld();
    
    NSLog(@"Created placeholder geometry");
}

- (void)fitView {
    if (!_isInitialized) return;
    
    @try {
        _view.FitWorld();
        _canvas.Update();
    } @catch (NSException *exception) {
        NSLog(@"HOOPS fitView error: %@", exception.reason);
    }
}

- (void)resetView {
    if (!_isInitialized) return;
    
    @try {
        _view.GetSegmentKey().GetCameraControl().Reset();
        _view.FitWorld();
        _canvas.Update();
    } @catch (NSException *exception) {
        NSLog(@"HOOPS resetView error: %@", exception.reason);
    }
}

- (BOOL)isFlipped {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (HPS::MouseButtons)getMouseButtons:(NSEvent *)event {
    HPS::MouseButtons buttons;
    NSUInteger flags = [event modifierFlags];
    
    if ([event type] == NSEventTypeLeftMouseDown || 
        [event type] == NSEventTypeLeftMouseUp || 
        [event type] == NSEventTypeLeftMouseDragged) {
        buttons.Left(true);
    }
    if ([event type] == NSEventTypeRightMouseDown || 
        [event type] == NSEventTypeRightMouseUp || 
        [event type] == NSEventTypeRightMouseDragged) {
        buttons.Right(true);
    }
    if ([event type] == NSEventTypeOtherMouseDown || 
        [event type] == NSEventTypeOtherMouseUp || 
        [event type] == NSEventTypeOtherMouseDragged) {
        buttons.Middle(true);
    }
    
    return buttons;
}

- (HPS::ModifierKeys)getModifierKeys:(NSEvent *)event {
    HPS::ModifierKeys modifiers;
    NSUInteger flags = [event modifierFlags];
    
    if (flags & NSEventModifierFlagShift) {
        modifiers.Shift(true);
    }
    if (flags & NSEventModifierFlagControl) {
        modifiers.Control(true);
    }
    if (flags & NSEventModifierFlagOption) {
        modifiers.Alt(true);
    }
    if (flags & NSEventModifierFlagCommand) {
        modifiers.Meta(true);
    }
    
    return modifiers;
}

- (HPS::WindowPoint)getWindowPoint:(NSEvent *)event {
    NSPoint locationInView = [self convertPoint:[event locationInWindow] fromView:nil];
    NSRect bounds = [self bounds];
    
    // 转换为HOOPS归一化坐标 (-1 到 1)
    float normalizedX = (locationInView.x / bounds.size.width) * 2.0f - 1.0f;
    float normalizedY = (locationInView.y / bounds.size.height) * 2.0f - 1.0f;
    
    // 由于isFlipped返回YES，Y轴需要翻转
    normalizedY = -normalizedY;
    
    return HPS::WindowPoint(normalizedX, normalizedY, 0);
}

- (void)mouseDown:(NSEvent *)event {
    if (!_isInitialized) return;
    
    [[self window] makeFirstResponder:self];
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons = [self getMouseButtons:event];
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonDown, windowPoint, buttons, modifiers));
}

- (void)mouseUp:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons = [self getMouseButtons:event];
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonUp, windowPoint, buttons, modifiers));
}

- (void)mouseDragged:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Left(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::Move, windowPoint, buttons, modifiers));
}

- (void)rightMouseDown:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Right(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonDown, windowPoint, buttons, modifiers));
}

- (void)rightMouseUp:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Right(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonUp, windowPoint, buttons, modifiers));
}

- (void)rightMouseDragged:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Right(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::Move, windowPoint, buttons, modifiers));
}

- (void)otherMouseDown:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Middle(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonDown, windowPoint, buttons, modifiers));
}

- (void)otherMouseUp:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Middle(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::ButtonUp, windowPoint, buttons, modifiers));
}

- (void)otherMouseDragged:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::MouseButtons buttons;
    buttons.Middle(true);
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::Move, windowPoint, buttons, modifiers));
}

- (void)scrollWheel:(NSEvent *)event {
    if (!_isInitialized) return;
    
    HPS::WindowPoint windowPoint = [self getWindowPoint:event];
    HPS::ModifierKeys modifiers = [self getModifierKeys:event];
    
    float deltaY = [event scrollingDeltaY];
    
    _canvas.GetWindowKey().GetEventDispatcher().InjectEvent(
        HPS::MouseEvent(HPS::MouseEvent::Action::Scroll, deltaY, windowPoint, modifiers));
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (_isInitialized && _canvas.Type() != HPS::Type::None) {
        _canvas.Update();
    }
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    
    if (_isInitialized && _canvas.Type() != HPS::Type::None) {
        _canvas.Update();
    }
}

@end
