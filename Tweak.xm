@interface _UIBatteryView: UIView
	@property (nonatomic,retain) UILabel * percentageLabel;
	@property (nonatomic,retain) UILabel * sbPercentageLabel;
	@property (assign,nonatomic) double chargePercent;
	@property (assign,nonatomic) long long chargingState;
	@property (assign,nonatomic) BOOL saverModeActive;
	@property (assign,nonatomic) BOOL showsPercentage;
	@property (assign,nonatomic) BOOL isForStatusBar;
  @property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
  @property(nonatomic, retain) UIColor *backupTextColor;
	@property (nonatomic,retain) CALayer * fillLayer;
	@property (nonatomic,copy) UIColor * fillColor;
	@property (nonatomic,copy) UIColor * bodyColor;
	@property (nonatomic,copy) UIColor * pinColor;
	@property (nonatomic,retain) CALayer * bodyLayer;
	-(UIColor*)_batteryTextColor;
	-(void)setShowsPercentage:(BOOL)arg1;
	-(void)setFillLayer:(CALayer *)arg1;
	-(void)updatePercentageColor;
@end

@interface _UIStaticBatteryView : _UIBatteryView
@end

@interface _UIStatusBarImageView : UIImageView
@end

@interface _UIStatusBarBatteryItem
	@property (nonatomic,retain) _UIBatteryView * batteryView;
	@property (nonatomic,retain) _UIBatteryView * staticBatteryView;
	@property (nonatomic,retain) UILabel * percentView;
@end

@interface FBSystemService : NSObject
  +(id)sharedInstance;
  -(void)exitAndRelaunch:(BOOL)arg1;
@end

//1 -> Apple Method
//2 -> Pill Shaped
//3 -> Empty with Percentage
//4 -> Actual Percentage
static int style = 1;
static int labelFontSize = 15;
static double labelY = 0.5;

%hook _UIStatusBarBatteryItem

	-(_UIBatteryView *)batteryView
	{
		_UIBatteryView *orig = %orig;
		orig.isForStatusBar = YES;
		if (style == 4 && !orig.sbPercentageLabel)
		{
			orig.sbPercentageLabel = [[UILabel alloc] initWithFrame: CGRectZero];
			[orig addSubview: orig.sbPercentageLabel];
			orig.sbPercentageLabel.translatesAutoresizingMaskIntoConstraints = NO;
			[orig.sbPercentageLabel.leadingAnchor constraintEqualToAnchor:orig.leadingAnchor].active = YES;
			[orig.sbPercentageLabel.centerYAnchor constraintEqualToAnchor:orig.centerYAnchor constant:labelY].active = YES;
			NSString *percentChar = @"";
			if (orig.chargePercent < 1)
				percentChar = @"%";

			[orig.sbPercentageLabel setText: [NSString stringWithFormat:@"%.0f%@", floor(orig.chargePercent * 100),percentChar]];
			[orig.sbPercentageLabel setFont:[UIFont boldSystemFontOfSize:labelFontSize]];
			//[orig.sbPercentageLabel sizeToFit];
			orig.sbPercentageLabel.textAlignment = NSTextAlignmentLeft;
		}
		return orig;
	}

	-(_UIStaticBatteryView  *)staticBatteryView
	{
		_UIStaticBatteryView *orig = %orig;
		orig.isForStatusBar = NO;
		return orig;
	}

	//Hide the charging view
  -(_UIStatusBarImageView *)chargingView
  {
    _UIStatusBarImageView *orig = %orig;
		if (style == 4)
    	orig.hidden = YES;
    return orig;
  }

	// -(id)applyUpdate:(id)arg1 toDisplayItem:(id)arg2
	// {
	// 	id orig = %orig;
	// 	[MSHookIvar<UILabel*>(self,"_percentView") setText:nil];
	// 	return orig;
	// }

%end

%hook _UIBatteryView

	%property (nonatomic, retain) UILabel *sbPercentageLabel;
  %property (assign,nonatomic) BOOL isForStatusBar;
  %property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
	%property(nonatomic, retain) UIColor *backupTextColor;

	-(id)initWithFrame:(CGRect)arg1
	{
		self = %orig;
    if (self)
    {
			self.isForStatusBar = NO;
			self.isFetchingBatteryFillColor = NO;
			self.backupTextColor = nil;
    }
    return self;
	}

	// -(void)layoutSubviews
	// {
	// 	%orig;
	// 	if (self.sbPercentageLabel && ([self.superview class] == objc_getClass("_UIStatusBarForegroundView")))
	// 	{
	// 		if (self.sbPercentageLabel.translatesAutoresizingMaskIntoConstraints)
	// 		{
	// 			self.sbPercentageLabel.translatesAutoresizingMaskIntoConstraints = NO;
	// 			[self.sbPercentageLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
	// 			[self.sbPercentageLabel.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor].active = YES;
	// 		}
	// 	}
	// }

	- (void)setChargePercent: (CGFloat)percent
	{
		%orig;
    if (self.sbPercentageLabel && style == 4)
    {
      NSString *percentChar = @"";
      if (percent < 1)
        percentChar = @"%";

		  [[self sbPercentageLabel] setText: [NSString stringWithFormat:@"%.0f%@", floor(percent * 100),percentChar]];
    }
	}

	-(void)__updateFillLayer
	{
		%orig;
		if (self.isForStatusBar && style == 2)
		{
			CGRect origFrame = self.fillLayer.frame;
			origFrame.origin.x = 1;
			origFrame.origin.y = 1;
			origFrame.size.width = self.bodyLayer.frame.size.width - 4;
			origFrame.size.height = self.bodyLayer.frame.size.height - 2;
			self.fillLayer.frame = origFrame;
		}
	}

	-(void)_updateFillColor
	{
		%orig;
		if (self.isForStatusBar && style > 1)
		{
			UIColor *newBodyColor = self.backupTextColor;

			if ([self saverModeActive])
				newBodyColor = [UIColor colorWithRed:1.0 green:0.839 blue:0.039 alpha:1];
			else if ([self chargePercent] <= 0.10)
				newBodyColor = [UIColor redColor];
			else if ([self chargePercent] <= 0.20)
				newBodyColor = [UIColor orangeColor];
			else if ([self chargingState] != 0)
				newBodyColor = [UIColor systemGreenColor];

			if (style == 4 && self.sbPercentageLabel)
			{
				self.sbPercentageLabel.textColor = newBodyColor;
				newBodyColor = [UIColor clearColor];
			}
			else if (self.sbPercentageLabel)
				self.sbPercentageLabel.textColor = [UIColor clearColor];

			[self setBodyColor:newBodyColor];
			[self setPinColor:newBodyColor];
		}
	}

	-(id)_batteryTextColor
	{
		if (style == 2)
		{
			if ([self saverModeActive])
				return [UIColor blackColor];
			else if ([self chargePercent] <= 0.20)
				return [UIColor whiteColor];
			else if ([self chargingState] != 0)
				return [UIColor blackColor];
			else
			{
				UIColor *orig = %orig;
				CGFloat r,g,b,a,r1,g1,b1,a1;
				[self.backupTextColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
				[orig getRed:&r green:&g blue:&b alpha:&a];
				return [UIColor colorWithRed:1.-r1 green:1.-g1 blue:1.-b1 alpha:a];
			}
		}
		else
			return %orig;
	}

	-(id)_batteryFillColor
	{
		self.isFetchingBatteryFillColor = YES;
		self.backupTextColor = %orig;
		self.isFetchingBatteryFillColor = NO;

		if (self.isForStatusBar && style > 2)
			return [UIColor clearColor];

		return self.backupTextColor;
	}

	-(BOOL)_shouldShowBolt
	{
		return self.isForStatusBar ? NO : %orig;
	}

  -(BOOL)showsInlineChargingIndicator
  {
    return self.isForStatusBar ? NO : %orig;
  }

	-(BOOL)_currentlyShowsPercentage
	{
		if (style == 1 && self.isForStatusBar)
			return YES;
		else if (style > 1 && style < 4 && self.isForStatusBar)
			return !self.isFetchingBatteryFillColor;
		return %orig;
	}

	-(BOOL)showsPercentage
	{
		if (style == 1 && self.isForStatusBar)
			return YES;
		else if (style > 1 && style < 4 && self.isForStatusBar)
			return !self.isFetchingBatteryFillColor;
		return %orig;
	}

	// -(void)setShowsPercentage:(BOOL)arg1
	// {
	// 	%orig(self.isForStatusBar && style < 4);
	// }

%end

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void reloadSettings() {

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.p2kdev.simplebattery.plist"];
	if(prefs)
	{
    //isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : isEnabled;
    style = [prefs objectForKey:@"style"] ? [[prefs objectForKey:@"style"] intValue] : style;
		labelFontSize = [prefs objectForKey:@"labelFontSize"] ? [[prefs objectForKey:@"labelFontSize"] intValue] : labelFontSize;
    labelY = [prefs objectForKey:@"labelY"] ? [[prefs objectForKey:@"labelY"] doubleValue] : labelY;
	}
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.p2kdev.simplebattery.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.p2kdev.simplebattery.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
