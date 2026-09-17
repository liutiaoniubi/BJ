#import <UIKit/UIKit.h>

@interface WGWidgetListFooterView : UIView
- (id)editButton;
@end

%hook WGWidgetListFooterView

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        id btn = [self editButton];
        if ([btn isKindOfClass:[UIView class]]) {
            ((UIView *)btn).hidden = YES;
        }
    }
    return self;
}

%end
