ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:14.0

# ┌──────────────────────────────────────────────────────────┐
# │ 隐根(RootHide) 专用配置                                   │
# │  THEOS_PACKAGE_SCHEME = roothide                          │
# │   → deb 的 Architecture 变成 iphoneos-arm64e              │
# │   → 依赖库用 @loader_path/.jbroot/... 链接（随机路径）     │
# │   → 文件落到随机命名的 jbroot 目录，不再有固定 /var/jb     │
# │                                                           │
# │ 三种方案对照：                                             │
# │   rootful  (有根, iOS14-) → Architecture: iphoneos-arm    │
# │   rootless (无根, Dopamine/palera1n) → iphoneos-arm64     │
# │   roothide (隐根, Dopamine-RootHide) → iphoneos-arm64e ★  │
# └──────────────────────────────────────────────────────────┘

# 想改回普通无根越狱：把下面这行改成 rootless
# 有根越狱(checkra1n/unc0ver)：整行注释掉
export THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoTodayEditBtn

NoTodayEditBtn_FILES = Tweak.x
NoTodayEditBtn_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unknown-pragmas

# 下面这行在 USE_CEPHEI=1 时再加（Tweak.x 顶部宏要同步改）
# NoTodayEditBtn_FRAMEWORKS = UIKit Cephei
# NoTodayEditBtn_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
