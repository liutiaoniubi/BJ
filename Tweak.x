#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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
    if (NTEBIsEditTarget(self)) {
        NTEBKill(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ NTEBKill(self); });
    }
}

- (void)setHidden:(BOOL)hidden {
    if (!hidden && NTEBIsEditTarget(self)) {
        %orig(YES);
        self.alpha = 0.0;
        return;
    }
    %orig(hidden);
}

- (void)layoutSubviews {
    %orig;
    if (!self.window) return;
    if (NTEBIsEditTarget(self)) NTEBKill(self);
    for (UIView *sub in self.subviews) {
        if (NTEBIsEditTarget(sub)) NTEBKill(sub);
    }
}

%end
