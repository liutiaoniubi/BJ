#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

@interface SBHEditingWidgetButton : UIView
@end

%hook SBHEditingWidgetButton

- (void)didMoveToWindow {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
    self.userInteractionEnabled = NO;
}

%end

%hook UIButton

- (void)didMoveToWindow {
    %orig;
    if (!self.window || self.hidden) return;

    NSString *cls = [NSStringFromClass([self class]) lowercaseString];
    if ([cls containsString:@"edit"] && [cls containsString:@"button"]) {
        self.hidden = YES;
        return;
    }

    NSString *t = [self titleForState:UIControlStateNormal];
    if (t.length == 0) t = self.titleLabel.text;
    if (t.length && ([t isEqualToString:@"编辑"] ||
                     [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) {
        self.hidden = YES;
    }
}

%end
