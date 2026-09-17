#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static UIWindow *gWin = nil;

static void NTEBBanner(void) {
    if (gWin) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL wg  = NSClassFromString(@"WGWidgetListFooterView") != nil;
        BOOL sbh = NSClassFromString(@"SBHEditingWidgetButton") != nil;
        BOOL td  = NSClassFromString(@"SBTodayViewController") != nil;

        UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        w.windowLevel = UIWindowLevelStatusBar + 100;
        w.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.92];
        w.userInteractionEnabled = NO;

        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, w.bounds.size.width, 90)];
        lb.numberOfLines = 0;
        lb.text = [NSString stringWithFormat:@"NTEB已加载\nWG:%@ SBH:%@ TODAY:%@",
                   wg ? @"是" : @"否", sbh ? @"是" : @"否", td ? @"是" : @"否"];
        lb.textColor = [UIColor whiteColor];
        lb.font = [UIFont boldSystemFontOfSize:20];
        lb.textAlignment = NSTextAlignmentCenter;
        [w addSubview:lb];

        w.hidden = NO;
        gWin = w;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            gWin.hidden = YES;
            gWin = nil;
        });
    });
}

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

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
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

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ NTEBBanner(); });
}
