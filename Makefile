PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:13.0:13.0
export ARCHS = arm64 arm64e

TWEAK_NAME = SimpleBattery
SimpleBattery_FILES = Tweak.xm
SimpleBattery_FRAMEWORKS = UIKit
SimpleBattery_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
