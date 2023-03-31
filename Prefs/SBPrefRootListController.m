#import <Preferences/Preferences.h>

//#define tweakPrefPath @"/User/Library/Preferences/com.p2kdev.simplebattery.plist"

@interface SBPrefRootListController : PSListController
@end

@implementation SBPrefRootListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)visitTwitter {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/p2kdev"]];
}

- (void)respring {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.p2kdev.simplebattery.respring"), NULL, NULL, YES);
}

@end
