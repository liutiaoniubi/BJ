ARCHS := arm64
TARGET := iphone:clang:16.5:16.5

export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoTodayEditBtn

NoTodayEditBtn_FILES = Tweak.x
NoTodayEditBtn_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
