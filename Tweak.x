#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

static BOOL NTEBIsEdit(UIView *v) {
    NSString *l = [NSStringFromClass([v class]) lowercaseString];
    if ([l containsString:@"edit"] && [l containsString:@"button"]) return YES;

    if ([v isKindOfClass:[UIButton class]]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length == 0) t = ((UIButton *)v).titleLabel.text;
        if (t.length && ([t isEqualToString:@"编辑"] ||
                         [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) return YES;
    }

    NSString *a = [(v.accessibilityLabel ?: @"") lowercaseString];
    if (a.length && ([a isEqualToString:@"编辑"] || [a isEqualToString:@"edit"])) return YES;

    return NO;
}

static void NTEBKill(UIView *v) {
    v.hidden = YES;
    v.alpha = 0.0;
    v.userInteractionEnabled = NO;
}

@interface WGWidgetListFooterView : UIView
@end

%hook WGWidgetListFooterView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
    id b = nil;
    @try { b = [self valueForKey:@"editButton"]; } @catch (NSException *e) {}
    if ([b isKindOfClass:[UIView class]]) NTEBKill((UIView *)b);
}

- (void)layoutSubviews {
    %orig;
    id b = nil;
    @try { b = [self valueForKey:@"editButton"]; } @catch (NSException *e) {}
    if ([b isKindOfClass:[UIView class]]) NTEBKill((UIView *)b);
}

%end

@interface SBHEditingWidgetButton : UIView
@end

%hook SBHEditingWidgetButton

- (void)didMoveToWindow {
    %orig;
    NTEBKill(self);
}

%end

%hook UIButton

- (void)didMoveToWindow {
    %orig;
    if (!self.window || self.hidden) return;
    if (NTEBIsEdit(self)) {
        NTEBKill(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ NTEBKill(self); });
    }
}

- (void)setHidden:(BOOL)h {
    if (!h && NTEBIsEdit(self)) {
        %orig(YES);
        self.alpha = 0.0;
        return;
    }
    %orig(h);
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    });
}
