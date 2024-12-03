export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:16.5:16.0
export ARCHS = arm64 arm64e
export THEOS_DEVICE_IP = 192.168.86.47
export FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Oriental
Oriental_FILES = Oriental.xm
Oriental_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "sbreload"

include $(THEOS_MAKE_PATH)/aggregate.mk
