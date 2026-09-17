#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define kDebugLog 1

static void NTEBLog(NSString *fmt, ...) {
#if kDebugLog
    va_list args; va_start(args, fmt);
    NSString *m = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[NoTodayEditBtn] %@", m);
#endif
}

static BOOL NTEBIsEditButton(UIView *v) {
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

    return NO;
}

static BOOL NTEBInWidgetContext(UIView *v) {
    UIResponder *r = v;
    int d = 0;
    while (r && d++ < 30) {
        NSString *l = [NSStringFromClass([r class]) lowercaseString];
        if ([l containsString:@"widget"] ||
            [l containsString:@"today"]  ||
            [l containsString:@"gallery"]) return YES;
        r = [r nextResponder];
    }
    return NO;
}

@interface WGWidgetListFooterView : UIView
@end

%hook WGWidgetListFooterView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
    id btn = nil;
    @try { btn = [self valueForKey:@"editButton"]; } @catch (NSException *e) {}
    if ([btn isKindOfClass:[UIView class]]) {
        ((UIView *)btn).hidden = YES;
        NTEBLog(@"hid editButton via KVC");
    }
}

- (void)layoutSubviews {
    %orig;
    id btn = nil;
    @try { btn = [self valueForKey:@"editButton"]; } @catch (NSException *e) {}
    if ([btn isKindOfClass:[UIView class]]) {
        ((UIView *)btn).hidden = YES;
    }
}

%end

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (!self.window || self.hidden) return;
    if (!NTEBIsEditButton(self)) return;
    if (!NTEBInWidgetContext(self)) return;

    self.hidden = YES;
    NTEBLog(@"hid %@", NSStringFromClass([self class]));
}

%end

%ctor {
    NTEBLog(@"loaded in %@", [[NSBundle mainBundle] bundleIdentifier]);
    NTEBLog(@"WGWidgetListFooterView exists: %@",
            NSClassFromString(@"WGWidgetListFooterView") ? @"YES" : @"NO");
}
