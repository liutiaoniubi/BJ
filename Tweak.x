#import <UIKit/UIKit.h>

@interface WGWidgetListFooterView : UIView
- (id)editButton;
@end

@interface SBHEditingWidgetButton : UIView
@end

%hook WGWidgetListFooterView

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        id b = [self editButton];
        if ([b isKindOfClass:[UIView class]]) ((UIView *)b).hidden = YES;
    }
    return self;
}

%end

%hook SBHEditingWidgetButton

- (void)didMoveToWindow {
    %orig;
    self.hidden = YES;
}

%end

%ctor {
    %init;
}
