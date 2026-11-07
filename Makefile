TARGET := iphone:clang:9.3:8.0
INSTALL_TARGET_PROCESSES = Preferences accountsd gamed FindMyiPhone FindMyFriends imagent
ARCHS = armv7


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GSAPort

GSAPort_FILES = Tweak.x SessionSupport.x AccountDiagnostics.x
GSAPort_CFLAGS = -fobjc-arc -Wno-gcc-compat -I$(THEOS_PROJECT_DIR)/openssl/include
GSAPort_LDFLAGS = $(THEOS_PROJECT_DIR)/openssl/lib/libcrypto.a -framework IOKit -framework CFNetwork -lz
GSAPort_FRAMEWORKS = UIKit Accounts

include $(THEOS_MAKE_PATH)/tweak.mk
