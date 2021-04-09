#import "FlutterUnityPlugin.h"

#import <UnityFramework/UnityFramework.h>
#import <ReplayKit/ReplayKit.h>
#import <Photos/Photos.h>

UnityFramework * gUfw;

void UfwLoad()
{
    static bool once = false;
    if (once) return;
    once = true;
    NSString * bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:
                             @"/Frameworks/UnityFramework.framework"];
    NSBundle * bundle = [NSBundle bundleWithPath: bundlePath];
    if (![bundle isLoaded]) {
        [bundle load];
    }
    gUfw = [[bundle principalClass] getInstance];
}

void UfwRun()
{
    static bool once = false;
    if (once) return;
    once = true;
    NSArray<NSString *> * arguments = [[NSProcessInfo processInfo] arguments];
    int argc = (int)[arguments count];
    char ** argv = malloc((argc + 1) * sizeof(char *));
    for (int i = 0; i < argc; i++) {
        argv[i] = strdup([[arguments objectAtIndex: i] UTF8String]);
    }
    argv[argc] = NULL;
    [gUfw setDataBundleId: "com.unity3d.framework"];
    [gUfw runEmbeddedWithArgc: argc argv: argv appLaunchOpts: [[NSDictionary alloc] init]];
    [[[gUfw appController] window] setWindowLevel: UIWindowLevelNormal - 1];
}

void UfwPause()
{
    id app = [UIApplication sharedApplication];
    id appController = [gUfw appController];
    [appController applicationWillResignActive: app];
}

void UfwResume()
{
    id app = [UIApplication sharedApplication];
    id appController = [gUfw appController];
    [appController applicationWillEnterForeground: app];
    [appController applicationDidBecomeActive: app];
}

NSMutableArray * gViews;

@interface FrameLayout : UIView
@end

@implementation FrameLayout

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectIsEmpty([self bounds])) {
        [(UIView *)[[gUfw appController] unityView] setFrame: [self bounds]];
    }
}

@end

@interface FlutterUnityView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId binaryMessenger:
(NSObject<FlutterBinaryMessenger> *)messenger;

@end

@implementation FlutterUnityView {
    int64_t _viewId;
    FrameLayout * _view;
    FlutterMethodChannel * _channel;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId binaryMessenger:
(NSObject<FlutterBinaryMessenger> *)messenger {
    if (self = [super init]) {
        [gViews addObject: self];
        _viewId = viewId;
        _view = [[FrameLayout alloc] initWithFrame: frame];
        [_view setBackgroundColor: [UIColor blackColor]];
        _channel = [FlutterMethodChannel methodChannelWithName:
                    [NSString stringWithFormat: @"unity_view_%lld", viewId] binaryMessenger: messenger];
        __weak __typeof(self) weakSelf = self;
        [_channel setMethodCallHandler:
         ^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf onMethodCall: call result: result];
        }];
        [self _attach];
    }
    return self;
}

- (nonnull UIView *)view {
    return _view;
}

- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)onMethodCall:(FlutterMethodCall * _Nonnull)call result:(FlutterResult  _Nonnull)result {
    NSLog(@"onMethodCall: %@", call.method);
    if ([call.method isEqualToString: @"dispose"]) {
        [self _remove];
        result(nil);
    } else {
        [self _reattach];
        if ([call.method isEqualToString: @"pause"]) {
            UfwPause();
            result(nil);
        } else if ([call.method isEqualToString: @"resume"]) {
            UfwResume();
            result(nil);
        } else if ([call.method isEqualToString: @"send"]) {
            NSDictionary * jsonObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithLongLong: _viewId], @"id",
                                         call.arguments[@"message"], @"data",
                                         nil];
            NSError * error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject: jsonObject options: kNilOptions error: &error];
            if (!jsonData && error) {
                NSLog(@"%@", [error localizedDescription]);
                result([FlutterError errorWithCode: [NSString stringWithFormat: @"%ld", (long)[error code]]
                                           message: [error localizedDescription]
                                           details: nil]);
            } else {
                [gUfw sendMessageToGOWithName: [call.arguments[@"gameObjectName"] UTF8String]
                                 functionName: [call.arguments[@"methodName"] UTF8String]
                                      message: [[[NSString alloc] initWithData: jsonData encoding: NSUTF8StringEncoding] UTF8String]];
                result(nil);
            }
        } 
        else {
            result(FlutterMethodNotImplemented);
        }
    }
}

- (int64_t)viewId {
    return _viewId;
}

- (void)onMessage:(NSString *)message {
    NSLog(@"onMessage: %@", message);
    [_channel invokeMethod: @"onUnityViewMessage" arguments: message];
}

- (void)_remove {
    [gViews removeObject: self];
    [_channel setMethodCallHandler: nil];
    UIView * unityView = (UIView *)[[gUfw appController] unityView];
    UIView * superview = [unityView superview];
    if (superview == _view) {
        if (![gViews count]) {
            [unityView removeFromSuperview];
            [superview layoutIfNeeded];
            UfwPause();
        } else {
            [[gViews lastObject] _reattach];
        }
    }
}

- (void)_attach {
    UfwRun();
    UIView * unityView = (UIView *)[[gUfw appController] unityView];
    UIView * superview = [unityView superview];
    if (superview) {
        [unityView removeFromSuperview];
        [superview layoutIfNeeded];
    }
    [_view addSubview: unityView];
    [_view layoutIfNeeded];
    UfwResume();
}

- (void)_reattach {
    UIView * unityView = (UIView *)[[gUfw appController] unityView];
    UIView * superview = [unityView superview];
    if (superview != _view) {
        [self _attach];
        [_channel invokeMethod: @"onUnityViewReattached" arguments: nil];
    }
}

@end

@interface FlutterUnityViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

@implementation FlutterUnityViewFactory {
    NSObject<FlutterBinaryMessenger> * _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    if (self = [super init]) {
        _messenger = messenger;
    }
    return self;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                            viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    FlutterUnityView * view = [[FlutterUnityView alloc] initWithFrame: frame viewIdentifier: viewId
                                                      binaryMessenger: _messenger];
    return view;
}

@end

@implementation FlutterUnityPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    UfwLoad();
    gViews = [[NSMutableArray alloc] init];
    FlutterUnityViewFactory * viewFactory = [[FlutterUnityViewFactory alloc] initWithMessenger: [registrar messenger]];
    [registrar registerViewFactory: viewFactory withId: @"unity_view"];
}

@end

__attribute__((used)) void FlutterUnityPluginOnMessage(const char * data)
{
    NSLog(@"FlutterUnityPluginOnMessage: %s", data);
    NSData * jsonData = [[NSString stringWithUTF8String: data] dataUsingEncoding: NSUTF8StringEncoding];
    NSError * error;
    NSDictionary * jsonObject = [NSJSONSerialization JSONObjectWithData: jsonData options: kNilOptions error: &error];
    if (!jsonObject && error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        id messageId = jsonObject[@"id"];
        id messageData = jsonObject[@"data"];
        for (FlutterUnityView * view in gViews) {
            if ((int64_t)messageId < 0 || (int64_t)messageId == [view viewId]) {
                [view onMessage: messageData];
            }
        }
    }
}
