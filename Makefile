ARCHS := arm64e
TARGET := iphone:clang:16.5:16.5

# 隐根(RootHide / Relaxin) → roothide，deb 架构 iphoneos-arm64e
export THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoTodayEditBtn

NoTodayEditBtn_FILES = Tweak.x
NoTodayEditBtn_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unknown-pragmas

include $(THEOS_MAKE_PATH)/tweak.mk
