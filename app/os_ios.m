// SPDX-License-Identifier: Unlicense OR MIT

@import UIKit;

#include <stdint.h>
#include "_cgo_export.h"
#include "framework_ios.h"

__attribute__ ((visibility ("hidden"))) Class gio_layerClass(void);

@interface GioView: UIView <UIKeyInput>
@property uintptr_t handle;
@end

@implementation GioViewController

CGFloat _keyboardHeight;

- (void)loadView {
	gio_runMain();

	CGRect zeroFrame = CGRectMake(0, 0, 0, 0);
	self.view = [[UIView alloc] initWithFrame:zeroFrame];
	self.view.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
	UIView *drawView = [[GioView alloc] initWithFrame:zeroFrame];
	[self.view addSubview: drawView];
#if !TARGET_OS_TV
	drawView.multipleTouchEnabled = YES;
#endif
	drawView.preservesSuperviewLayoutMargins = YES;
	drawView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
	onCreate((__bridge CFTypeRef)drawView, (__bridge CFTypeRef)self);
#if !TARGET_OS_TV
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillChange:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillChange:)
												 name:UIKeyboardWillChangeFrameNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
#endif
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(applicationDidEnterBackground:)
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(applicationWillEnterForeground:)
												 name: UIApplicationWillEnterForegroundNotification
											   object: nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	GioView *view = (GioView *)self.view.subviews[0];
	if (view != nil) {
		onStart(view.handle);
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	GioView *view = (GioView *)self.view.subviews[0];
	if (view != nil) {
		onStop(view.handle);
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	GioView *view = (GioView *)self.view.subviews[0];
	onDestroy(view.handle);
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	GioView *view = (GioView *)self.view.subviews[0];
	CGRect frame = self.view.bounds;
	// Adjust view bounds to make room for the keyboard.
	frame.size.height -= _keyboardHeight;
	view.frame = frame;
	gio_onDraw(view.handle);
}

- (void)didReceiveMemoryWarning {
	onLowMemory();
	[super didReceiveMemoryWarning];
}

#if !TARGET_OS_TV
- (void)keyboardWillChange:(NSNotification *)note {
	NSDictionary *userInfo = note.userInfo;
	CGRect f = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	_keyboardHeight = f.size.height;
	[self.view setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)note {
	_keyboardHeight = 0.0;
	[self.view setNeedsLayout];
}
#endif
@end

static void handleTouches(int last, GioView *view, NSSet<UITouch *> *touches, UIEvent *event) {
	CGFloat scale = view.contentScaleFactor;
	NSUInteger i = 0;
	NSUInteger n = [touches count];
	for (UITouch *touch in touches) {
		CFTypeRef touchRef = (__bridge CFTypeRef)touch;
		i++;
		NSArray<UITouch *> *coalescedTouches = [event coalescedTouchesForTouch:touch];
		NSUInteger j = 0;
		NSUInteger m = [coalescedTouches count];
		for (UITouch *coalescedTouch in [event coalescedTouchesForTouch:touch]) {
			CGPoint loc = [coalescedTouch locationInView:view];
			j++;
			int lastTouch = last && i == n && j == m;
			onTouch(view.handle, lastTouch, touchRef, touch.phase, loc.x*scale, loc.y*scale, [coalescedTouch timestamp]);
		}
	}
}

@implementation GioView
NSArray<UIKeyCommand *> *_keyCommands;
+ (void)onFrameCallback:(CADisplayLink *)link {
       gio_onFrameCallback((__bridge CFTypeRef)link);
}
+ (Class)layerClass {
    return gio_layerClass();
}
- (void)willMoveToWindow:(UIWindow *)newWindow {
	self.contentScaleFactor = newWindow.screen.nativeScale;
    if (@available(iOS 13.0, *)) {
        [self registerSceneNotifications:newWindow];
    }else{
        [self registerWindowNotifications:newWindow];
    }
}

- (void)registerSceneNotifications:(UIWindow *)newWindow {
        if (self.window != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UISceneDidActivateNotification
                                                  object:self.window.windowScene];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UISceneWillDeactivateNotification
                                                  object:self.window.windowScene];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(onSceneDidActivate:)
                                              name:UISceneDidActivateNotification
                                              object:newWindow.windowScene];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(onSceneWillDeactivate:)
                                              name:UISceneWillDeactivateNotification
                                              object:newWindow.windowScene];
}

- (void)onSceneDidActivate:(NSNotification *)note API_AVAILABLE(ios(13.0)){
    onFocus(self.handle, YES);
}

- (void)onSceneWillDeactivate:(NSNotification *)note API_AVAILABLE(ios(13.0)){
    onFocus(self.handle, NO);
}

- (void)registerWindowNotifications:(UIWindow *)newWindow {
	if (self.window != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
											  name:UIWindowDidBecomeKeyNotification
										      object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self
											  name:UIWindowDidResignKeyNotification
											  object:self.window];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(onWindowDidBecomeKey:)
										  name:UIWindowDidBecomeKeyNotification
										  object:newWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(onWindowDidResignKey:)
										  name:UIWindowDidResignKeyNotification
										  object:newWindow];
}

- (void)onWindowDidBecomeKey:(NSNotification *)note {
	if (self.isFirstResponder) {
		onFocus(self.handle, YES);
	}
}

- (void)onWindowDidResignKey:(NSNotification *)note {
	if (self.isFirstResponder) {
		onFocus(self.handle, NO);
	}
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	handleTouches(0, self, touches, event);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	handleTouches(0, self, touches, event);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	handleTouches(1, self, touches, event);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	handleTouches(1, self, touches, event);
}

- (void)insertText:(NSString *)text {
	onText(self.handle, (__bridge CFTypeRef)text);
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)hasText {
	return YES;
}

- (void)deleteBackward {
	onDeleteBackward(self.handle);
}

- (void)onUpArrow {
	onUpArrow(self.handle);
}

- (void)onDownArrow {
	onDownArrow(self.handle);
}

- (void)onLeftArrow {
	onLeftArrow(self.handle);
}

- (void)onRightArrow {
	onRightArrow(self.handle);
}

- (NSArray<UIKeyCommand *> *)keyCommands {
	if (_keyCommands == nil) {
		_keyCommands = @[
			[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
								modifierFlags:0
									   action:@selector(onUpArrow)],
			[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
								modifierFlags:0
									   action:@selector(onDownArrow)],
			[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
								modifierFlags:0
									   action:@selector(onLeftArrow)],
			[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
								modifierFlags:0
									   action:@selector(onRightArrow)]
		];
	}
	return _keyCommands;
}
@end

CFTypeRef gio_createDisplayLink(void) {
	CADisplayLink *dl = [CADisplayLink displayLinkWithTarget:[GioView class] selector:@selector(onFrameCallback:)];
	dl.paused = YES;
	NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
	[dl addToRunLoop:runLoop forMode:[runLoop currentMode]];
	return (__bridge_retained CFTypeRef)dl;
}

int gio_startDisplayLink(CFTypeRef dlref) {
	CADisplayLink *dl = (__bridge CADisplayLink *)dlref;
	dl.paused = NO;
	return 0;
}

int gio_stopDisplayLink(CFTypeRef dlref) {
	CADisplayLink *dl = (__bridge CADisplayLink *)dlref;
	dl.paused = YES;
	return 0;
}

void gio_releaseDisplayLink(CFTypeRef dlref) {
	CADisplayLink *dl = (__bridge CADisplayLink *)dlref;
	[dl invalidate];
	CFRelease(dlref);
}

void gio_setDisplayLinkDisplay(CFTypeRef dl, uint64_t did) {
	// Nothing to do on iOS.
}

void gio_hideCursor() {
	// Not supported.
}

void gio_showCursor() {
	// Not supported.
}

void gio_setCursor(NSUInteger curID) {
	// Not supported.
}

void gio_viewSetHandle(CFTypeRef viewRef, uintptr_t handle) {
	GioView *v = (__bridge GioView *)viewRef;
	v.handle = handle;
}

// usesScenes reports whether the app opts in to the scene life cycle
// with a UIApplicationSceneManifest in its Info.plist. UIKit then
// connects a scene after launch, and _gioSceneDelegate creates the
// window instead of the app delegate.
static BOOL usesScenes(void) {
	if (@available(iOS 13.0, tvOS 13.0, *)) {
		return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIApplicationSceneManifest"] != nil;
	}
	return NO;
}

// sceneWindow is the window of the scene life cycle. It outlives a
// scene that UIKit disconnects, because there is only one Gio window
// and its GioViewController cannot be created a second time.
static UIWindow *sceneWindow;

API_AVAILABLE(ios(13.0), tvos(13.0))
@interface _gioSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation _gioSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
	if (![scene isKindOfClass:[UIWindowScene class]] || ![session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
		return;
	}
	UIWindowScene *windowScene = (UIWindowScene *)scene;
	if (sceneWindow == nil) {
		sceneWindow = [[UIWindow alloc] initWithWindowScene:windowScene];
		GioViewController *controller = [[GioViewController alloc] initWithNibName:nil bundle:nil];
		sceneWindow.rootViewController = controller;
	} else {
		sceneWindow.windowScene = windowScene;
	}
	self.window = sceneWindow;
	[self.window makeKeyAndVisible];
	[self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
	for (UIOpenURLContext *context in URLContexts) {
		gio_onOpenURI((__bridge CFTypeRef)context.URL.absoluteString);
	}
}
@end

@interface _gioAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation _gioAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (usesScenes()) {
		return YES;
	}
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	GioViewController *controller = [[GioViewController alloc] initWithNibName:nil bundle:nil];
	self.window.rootViewController = controller;
	[self.window makeKeyAndVisible];
	return YES;
}

// The scene manifest needs no scene configurations: the main scene
// gets _gioSceneDelegate unless the Info.plist configures a delegate
// for it. Without a manifest the app delegate created the window, and
// the scene gets no delegate that would create a second one.
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0), tvos(13.0)) {
	UISceneConfiguration *config = [connectingSceneSession.configuration copy];
	if (usesScenes() && config.delegateClass == nil && [connectingSceneSession.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
		config.delegateClass = [_gioSceneDelegate class];
	}
	return config;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    gio_onOpenURI((__bridge CFTypeRef)url.absoluteString);
	return YES;
}
@end

int gio_applicationMain(int argc, char *argv[]) {
	@autoreleasepool {
		return UIApplicationMain(argc, argv, nil, NSStringFromClass([_gioAppDelegate class]));
	}
}
