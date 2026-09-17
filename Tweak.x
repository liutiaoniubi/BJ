#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

#define NTEBLog(...) NSLog(@"[NTEB] %@", [NSString stringWithFormat:__VA_ARGS__])

static NSMutableString *gReport = nil;

static void NTEBAppend(NSString *s) {
    if (!gReport) gReport = [NSMutableString string];
    if ([gReport rangeOfString:s].location == NSNotFound) {
        [gReport appendFormat:@"%@\n", s];
    }
}

static NSString *NTEBTextOf(UIView *v) {
    NSMutableString *m = [NSMutableString string];

    if ([v isKindOfClass:[UIButton class]]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length) [m appendFormat:@"BTN:%@ ", t];
    }
    if ([v isKindOfClass:[UILabel class]]) {
        NSString *t = ((UILabel *)v).text;
        if (t.length) [m appendFormat:@"LBL:%@ ", t];
    }
    if (v.accessibilityLabel.length) [m appendFormat:@"accL:%@ ", v.accessibilityLabel];
    if (v.accessibilityIdentifier.length) [m appendFormat:@"accI:%@ ", v.accessibilityIdentifier];

    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) {
            [m appendFormat:@"sub:%@ ", ((UILabel *)s).text];
        }
    }
    return m;
}

static BOOL NTEBHasEditText(UIView *v) {
    NSString *t = [NTEBTextOf(v) lowercaseString];
    return ([t containsString:@"编辑"] || [t containsString:@"edit"]);
}

static void NTEBScan(UIView *v, int depth) {
    if (!v || depth > 20) return;
    if (NTEBHasEditText(v)) {
        NSString *info = [NSString stringWithFormat:@"%@ | %@",
                          NSStringFromClass([v class]), NTEBTextOf(v)];
        NTEBAppend(info);
        NTEBLog(@"FOUND: %@", info);
    }
    for (UIView *s in v.subviews) NTEBScan(s, depth + 1);
}

static void NTEBShowReport(void) {
    NSString *txt = gReport.length ? gReport : @"(未扫描到含'编辑'的控件)";
    NTEBLog(@"REPORT: %@", txt);

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"扫描结果"
        message:txt preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil]];

    UIViewController *root = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                if (w.isKeyWindow) { root = w.rootViewController; break; }
            }
        }
        if (root) break;
    }
    if (root) {
        UIViewController *p = root;
        while (p.presentedViewController) p = p.presentedViewController;
        [p presentViewController:ac animated:YES completion:nil];
    }
}

@interface WGWidgetListFooterView : UIView
@end

%hook WGWidgetListFooterView

- (void)layoutSubviews {
    %orig;
    id b = nil;
    @try { b = [self valueForKey:@"editButton"]; } @catch (NSException *e) {}
    if ([b isKindOfClass:[UIView class]]) {
        ((UIView *)b).hidden = YES;
        NTEBLog(@"KVC hid: %@", NSStringFromClass([b class]));
    }
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        NTEBLog(@"vibrated - dylib loaded");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    NTEBScan(w, 0);
                }
            }
        }
        NTEBShowReport();
    });
}
