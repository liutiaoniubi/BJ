#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static UIWindow *gBanner = nil;

static void NTEBLog(NSString *fmt, ...) {
    va_list args; va_start(args, fmt);
    NSString *m = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[NoTodayEditBtn] %@", m);
}

// 5 秒后全屏红字，10 秒后自动消失
static void NTEBShowBanner(void) {
    if (gBanner) return;
    UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.92];
    w.userInteractionEnabled = NO;

    UILabel *lb = [[UILabel alloc] initWithFrame:w.bounds];
    lb.text = @"NoTodayEditBtn\n注入成功";
    lb.numberOfLines = 0;
    lb.textColor = [UIColor whiteColor];
    lb.font = [UIFont boldSystemFontOfSize:28];
    lb.textAlignment = NSTextAlignmentCenter;
    [w addSubview:lb];

    w.hidden = NO;
    gBanner = w;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        gBanner.hidden = YES;
        gBanner = nil;
    });
}

// 是否像「编辑」按钮
static BOOL NTEBLooksLikeEditButton(UIView *v) {
    NSString *l = [NSStringFromClass([v class]) lowercaseString];
    if ([l containsString:@"edit"] && [l containsString:@"button"]) return YES;
    if ([v isKindOfClass:[UIButton class]]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length && ([t isEqualToString:@"编辑"] ||
                         [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) return YES;
    }
    NSString *a = [(v.accessibilityIdentifier ?: @"") lowercaseString];
    if (a.length && [a containsString:@"edit"] && [a containsString:@"button"]) return YES;
    return NO;
}

// 祖先链里有没有 widget / today
static BOOL NTEBInWidgetContext(UIView *v) {
    UIResponder *r = v; int d = 0;
    while (r && d++ < 30) {
        NSString *l = [NSStringFromClass([r class]) lowercaseString];
        if ([l containsString:@"widget"] ||
            [l containsString:@"today"]  ||
            [l containsString:@"gallery"]) return YES;
        r = [r nextResponder];
    }
    return NO;
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if (!self.window || self.hidden) return;
    if (!NTEBLooksLikeEditButton(self)) return;
    if (!NTEBInWidgetContext(self)) return;
    self.hidden = YES;
    NTEBLog(@"命中并隐藏: %@", NSStringFromClass([self class]));
}
%end

%ctor {
    NTEBLog(@"ctor 执行，进程=%@", [[NSBundle mainBundle] bundleIdentifier]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NTEBShowBanner();
    });
}
