/* ============================================================================
 *  NoTodayEditBtn
 *  隐藏 iOS「今日视图 / 小组件页面」底部的“编辑”按钮
 *
 *  类名来源：从 Lynx 2 (com.mtac.lynxtwo) 二进制中提取的实际 hook 目标
 *    - WGWidgetListFooterView  ← 编辑按钮的宿主 view（footer）
 *      其内部方法 _editButtonLayoutFramesInBounds:forVisualConfiguration:
 *      withTranslationOffset:inRTL:doneButton:addWidgetButton:doneButtonFrame:
 *      addWidgetButtonFrame:  → 证明 editButton / doneButton / addWidgetButton
 *      都挂在这个类上
 *    - SBTodayViewController   ← 今日视图的 VC（作为额外触发点）
 *
 *  验证设备：iOS 14 / 15 / 16（Lynx 2 支持 14.0–16.5，同类符号在 iOS 16 仍存在）
 * ========================================================================== */

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 配置

// 打印调试日志（logos 版本用 NSLog，可在控制台/syslog 中 grep NoTodayEditBtn）
#define kDebugLog 1

// 1 = 启用 Cephei 设置面板开关（Makefile 需链接 Cephei，control 加依赖 ws.hbang.common）
// 0 = 零依赖，安装/respring 后直接生效（推荐先用这个验证）
#define USE_CEPHEI 0

#if USE_CEPHEI
#import <Cephei/HBPreferences.h>
static HBPreferences *ntebPrefs;
static BOOL ntebEnabled = YES;
#else
static BOOL ntebEnabled = YES;   // 默认开启
#endif

static NSString * const kPrefsKey = @"disableWidgetsEditButton";

#pragma mark - 私有类声明（只在编译期可见，运行期由 SpringBoard 提供）

@interface WGWidgetListFooterView : UIView
- (id)editButton;      // 不保证公开，实际用 KVC 取，这里仅消除编译警告
@end

@interface SBTodayViewController : UIViewController
@end

#pragma mark - 工具

static inline void NTEBLog(NSString *fmt, ...) {
#if kDebugLog
    va_list args; va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[NoTodayEditBtn] %@", msg);
#endif
}

// 遍历兜底：找出看起来像“编辑按钮”的子视图
static void NTEBSweepEditButton(UIView *host) {
    for (UIView *sub in host.subviews) {
        if (sub.hidden) continue;

        NSString *cls = NSStringFromClass([sub class]);
        NSString *lower = [cls lowercaseString];

        // 类名形如 ...EditButton / ...EditingButton
        if (([lower containsString:@"edit"] && [lower containsString:@"button"]) ||
            [lower isEqualToString:@"sbheditingwidgetbutton"]) {
            sub.hidden = YES;
            NTEBLog(@"已隐藏(类名匹配): %@", cls);
            continue;
        }

        // 标题为“编辑 / Edit”的按钮
        if ([sub isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)sub;
            NSString *t = [b titleForState:UIControlStateNormal];
            if (t.length == 0) t = b.titleLabel.text;
            if (t.length && ([t isEqualToString:@"编辑"] ||
                             [t caseInsensitiveCompare:@"Edit"] == NSOrderedSame)) {
                b.hidden = YES;
                NTEBLog(@"已隐藏(标题匹配): %@ title=%@", cls, t);
            }
        }
    }
}

// 核心：在 footer 上干掉 editButton
static void NTEBHideEditButton(UIView *footer) {
    if (!ntebEnabled || !footer) return;

    // ── 方式一：KVC 取 editButton（最准，Lynx 用的就是这个属性）──
    // valueForKey:@"editButton" 会依次尝试 editButton / _editButton 方法，
    // 再退回到 _editButton 实例变量
    id btn = nil;
    @try {
        btn = [footer valueForKey:@"editButton"];
    } @catch (NSException *e) {
        btn = nil;
    }

    if ([btn isKindOfClass:[UIView class]]) {
        UIView *v = (UIView *)btn;
        if (!v.hidden) {
            v.hidden = YES;
            NTEBLog(@"已隐藏 editButton (KVC) on %@", NSStringFromClass([footer class]));
        }
        return;
    }

    // ── 方式二：KVC 没取到，遍历子视图兜底 ──
    NTEBSweepEditButton(footer);
}

#pragma mark - Hook 1：footer 本体（主战场）

%hook WGWidgetListFooterView

- (void)didMoveToWindow {
    %orig;
    if (self.window) NTEBHideEditButton(self);
}

// editButton 可能是懒加载 / 布局时才创建，layoutSubviews 里再兜一次底
- (void)layoutSubviews {
    %orig;
    NTEBHideEditButton(self);
}

%end

#pragma mark - Hook 2：今日视图 VC（额外触发点，防止 footer 已被 layout 过）

%hook SBTodayViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!ntebEnabled) return;

    // 递归找 WGWidgetListFooterView 并隐藏其 editButton（深度有限，开销可忽略）
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:[self view]];
    NSInteger depth = 0;
    while (queue.count > 0 && depth < 200) {
        UIView *v = queue.firstObject;
        [queue removeObjectAtIndex:0];
        depth++;

        if ([v isKindOfClass:%c(WGWidgetListFooterView)]) {
            NTEBHideEditButton(v);
            continue;   // footer 内部不用再往下钻
        }
        for (UIView *sub in v.subviews) {
            if (sub) [queue addObject:sub];
        }
    }
}

%end

#pragma mark - 初始化

%ctor {
#if USE_CEPHEI
    ntebPrefs = [[HBPreferences alloc] initWithIdentifier:@"com.yourname.notodayeditbtn"];
    [ntebPrefs registerBool:&ntebEnabled default:YES forKey:kPrefsKey];
#endif

    NTEBLog(@"已注入 (%@)，开关=%@",
            [[NSBundle mainBundle] bundleIdentifier],
            ntebEnabled ? @"开" : @"关");
}
