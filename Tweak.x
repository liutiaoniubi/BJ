/* ============================================================================
 *  NoTodayEditBtn —— 诊断增强版
 *
 *  相比上一版新增：
 *   1. 启动时枚举系统里所有类，把「看起来像编辑按钮宿主」的类名全打进日志
 *      → 不用 FLEX 也能知道真实类名叫什么
 *   2. 全局 UIView 兜底：类名含 edit+button、或标题为「编辑/Edit」的一律隐藏
 *      → 万一 WGWidgetListFooterView 在你的系统上不存在，这层能兜住
 *
 *  日志查看（手机 NewTerm 或 SSH）：
 *    log show --last 5m --predicate 'eventMessage CONTAINS "NoTodayEditBtn"' --info --debug
 * ========================================================================== */

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define kDebugLog 1

static NSString * const kTag = @"NoTodayEditBtn";

static inline void NTEBLog(NSString *fmt, ...) {
#if kDebugLog
    va_list args; va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[%@] %@", kTag, msg);
#endif
}

#pragma mark - 诊断：枚举候选类

static void NTEBDumpCandidateClasses(void) {
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    if (!classes) return;

    NSMutableString *buf = [NSMutableString string];
    int n = 0;

    for (unsigned int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        NSString *l = [name lowercaseString];

        BOOL hit =
            ([l containsString:@"today"]) ||
            ([l containsString:@"widget"] && ([l containsString:@"footer"] ||
                                              [l containsString:@"edit"]   ||
                                              [l containsString:@"list"]   ||
                                              [l containsString:@"gallery"])) ||
            ([l containsString:@"edit"] && [l containsString:@"button"]);

        if (hit) {
            [buf appendFormat:@"%@ ", name];
            if (++n % 6 == 0) {
                NTEBLog(@"候选类 %d: %@", n, buf);
                buf = [NSMutableString string];
            }
        }
    }
    if (buf.length) NTEBLog(@"候选类(末批): %@", buf);
    NTEBLog(@"候选类共 %d 个", n);

    free(classes);
}

#pragma mark - 隐藏判定

// 祖先链里是否含 widget / today / gallery 关键词
static BOOL NTEBInWidgetContext(UIView *v) {
    UIResponder *r = v;
    int depth = 0;
    while (r && depth++ < 30) {
        NSString *l = [NSStringFromClass([r class]) lowercaseString];
        if ([l containsString:@"widget"] ||
            [l containsString:@"today"]  ||
            [l containsString:@"gallery"]) return YES;
        r = [r nextResponder];
    }
    return NO;
}

static BOOL NTEBIsEditButton(UIView *v) {
    NSString *l = [NSStringFromClass([v class]) lowercaseString];

    // 规则1：类名像 xxEditButton
    if ([l containsString:@"edit"] && [l containsString:@"button"]) return YES;

    // 规则2：标题是「编辑 / Edit」
    if ([v respondsToSelector:@selector(titleForState:)]) {
        NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
        if (t.length == 0 && [v respondsToSelector:@selector(titleLabel)]) {
            t = ((UIButton *)v).titleLabel.text;
        }
        if (t.length && ([t isEqualToString:@"编辑"] ||
                         [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) {
            return YES;
        }
    }

    // 规则3：无障碍标识含 edit
    if (v.accessibilityIdentifier.length) {
        NSString *a = [v.accessibilityIdentifier lowercaseString];
        if ([a containsString:@"edit"] && [a containsString:@"button"]) return YES;
    }
    return NO;
}

#pragma mark - 全局兜底：任何 view 挂到窗口时检查一次

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (!self.window || self.hidden) return;
    if (!NTEBIsEditButton(self)) return;
    if (!NTEBInWidgetContext(self)) return;

    self.hidden = YES;
    NTEBLog(@"[兜底] 已隐藏 %@ (标题=%@)",
            NSStringFromClass([self class]),
            [self respondsToSelector:@selector(titleForState:)]
                ? [(UIButton *)self titleForState:UIControlStateNormal] : @"-");
}

%end

#pragma mark - 精确 hook：footer 本体（若类存在）

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
        NTEBLog(@"[精确] KVC 隐藏 editButton on WGWidgetListFooterView");
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

#pragma mark - 今日视图 VC 出现时扫一遍

@interface SBTodayViewController : UIViewController
@end

%hook SBTodayViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NTEBLog(@"[VC] SBTodayViewController 出现");
}

%end

#pragma mark - 入口

%ctor {
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    NTEBLog(@"=== 已注入，进程 = %@ ===", bundle);

    NTEBLog(@"WGWidgetListFooterView 存在? %@",
            NSClassFromString(@"WGWidgetListFooterView") ? @"是" : @"否");
    NTEBLog(@"SBTodayViewController  存在? %@",
            NSClassFromString(@"SBTodayViewController") ? @"是" : @"否");

    NTEBDumpCandidateClasses();
}
