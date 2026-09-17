#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

#define NTEBLog(...) NSLog(@"[NTEB] %@", [NSString stringWithFormat:__VA_ARGS__])

static NSMutableString *gReport = nil;

static void NTEBAdd(NSString *s) {
    if (!gReport) gReport = [NSMutableString string];
    if ([gReport rangeOfString:s].location == NSNotFound) {
        [gReport appendFormat:@"%@\n", s];
        NTEBLog(@"FOUND: %@", s);
    }
}

static NSString *NTEBTextOf(UIView *v) {
    NSMutableString *m = [NSMutableString string];

    if ([v isKindOfClass:[UIButton class]]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length) [m appendFormat:@"B:%@ ", t];
    }
    if ([v isKindOfClass:[UILabel class]]) {
        NSString *t = ((UILabel *)v).text;
        if (t.length) [m appendFormat:@"L:%@ ", t];
    }
    if (v.accessibilityLabel.length) [m appendFormat:@"a:%@ ", v.accessibilityLabel];
    if (v.accessibilityIdentifier.length) [m appendFormat:@"i:%@ ", v.accessibilityIdentifier];

    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) {
            [m appendFormat:@"s:%@ ", ((UILabel *)s).text];
        }
    }
    return m;
}

static BOOL NTEBHasEdit(UIView *v) {
    NSString *t = [NTEBTextOf(v) lowercaseString];
    return ([t containsString:@"编辑"] || [t containsString:@"edit"]);
}

static void NTEBHide(UIView *v) {
    v.hidden = YES;
    v.alpha = 0.0;
    v.userInteractionEnabled = NO;
}

static void NTEBScan(UIView *v, int d) {
    if (!v || d > 22) return;
    if (NTEBHasEdit(v)) {
        NTEBAdd([NSString stringWithFormat:@"%@ | %@",
                 NSStringFromClass([v class]), NTEBTextOf(v)]);
        NTEBHide(v);
    }
    for (UIView *s in v.subviews) NTEBScan(s, d + 1);
}

static void NTEBScanAll(void) {
    for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)sc).windows) {
            NTEBScan(w, 0);
        }
    }
}

static void NTEBFlush(void) {
    NSString *t = gReport.length ? gReport : @"(none)";
    [UIPasteboard generalPasteboard].string = t;
    [t writeToFile:@"/var/mobile/nteb.txt" atomically:YES
          encoding:NSUTF8StringEncoding error:nil];
    NTEBLog(@"FLUSH len=%lu", (unsigned long)t.length);
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        NTEBLog(@"loaded");
        NTEBScanAll();
        NTEBFlush();
        [NSTimer scheduledTimerWithTimeInterval:3.0
                                        repeats:YES
                                          block:^(NSTimer *timer) {
            NTEBScanAll();
            NTEBFlush();
        }];
    });
}
