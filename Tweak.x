#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define LOADER_TEST 1

static void NTEBLog(NSString *fmt, ...) {
    va_list args; va_start(args, fmt);
    NSString *m = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[NoTodayEditBtn] %@", m);
}

static BOOL NTEBIsEditTarget(UIView *v) {
    NSString *cls = [NSStringFromClass([v class]) lowercaseString];

    if ([cls containsString:@"edit"] && [cls containsString:@"button"]) return YES;

    if ([v isKindOfClass:[UIButton class]]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length == 0) t = ((UIButton *)v).titleLabel.text;
        if (t.length && ([t isEqualToString:@"编辑"] ||
                         [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) return YES;
    }

    NSString *acc = [(v.accessibilityIdentifier ?: @"") lowercaseString];
    if (acc.length && [acc containsString:@"edit"] && [acc containsString:@"button"]) return YES;

    NSString *lbl = [(v.accessibilityLabel ?: @"") lowercaseString];
    if (lbl.length && ([lbl isEqualToString:@"编辑"] || [lbl isEqualToString:@"edit"])) return YES;

    return NO;
}

static void NTEBKill(UIView *v) {
    v.hidden = YES;
    v.alpha = 0.0;
    v.userInteractionEnabled = NO;
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;

#if LOADER_TEST
    NSString *c = NSStringFromClass([self class]);
    if ([c containsString:@"SBIcon"] && [c containsString:@"View"]) {
        self.alpha = 0.4;
    }
#endif

    if (NTEBIsEditTarget(self)) {
        NTEBKill(self);
        NTEBLog(@"kill: %@", NSStringFromClass([self class]));
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ NTEBKill(self); });
    }
}

- (void)setHidden:(BOOL)hidden {
    if (!hidden && NTEBIsEditTarget(self)) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}

%end

%ctor {
    NTEBLog(@"loaded in %@", [[NSBundle mainBundle] bundleIdentifier]);
}
