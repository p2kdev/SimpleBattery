export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

include $(THEOS)/makefiles/common.mk

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.0:13.0
export THEOS_DEVICE_IP=192.168.86.29
export THEOS_DEVICE_PORT=2222

BUNDLE_NAME = SimpleBattery
SimpleBattery_FILES = SBPrefRootListController.m
SimpleBattery_INSTALL_PATH = /Library/PreferenceBundles
SimpleBattery_FRAMEWORKS = UIKit CoreGraphics QuartzCore
SimpleBattery_PRIVATE_FRAMEWORKS = Preferences
SimpleBattery_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SimpleBattery.plist$(ECHO_END)
