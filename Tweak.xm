@interface _UIBatteryView: UIView
	@property (nonatomic,retain) UILabel * percentageLabel;
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

@interface _UIStatusBarBatteryItem
	@property (nonatomic,retain) _UIBatteryView * batteryView;
	@property (nonatomic,retain) _UIBatteryView * staticBatteryView;
	@property (nonatomic,retain) UILabel * percentView;
@end

%hook _UIStatusBarBatteryItem

	-(_UIBatteryView *)batteryView
	{
		_UIBatteryView *orig = %orig;
		orig.isForStatusBar = YES;
		return orig;
	}

	-(_UIStaticBatteryView  *)staticBatteryView
	{
		_UIStaticBatteryView *orig = %orig;
		orig.isForStatusBar = YES;
		return orig;
	}

	-(id)applyUpdate:(id)arg1 toDisplayItem:(id)arg2
	{
		id orig = %orig;
		[MSHookIvar<UILabel*>(self,"_percentView") setText:nil];
		return orig;
	}

%end

%hook _UIBatteryView

  %property (assign,nonatomic) BOOL isForStatusBar;
  %property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
	%property(nonatomic, retain) UIColor *backupTextColor;

	-(void)__updateFillLayer
	{
		%orig;
		if (self.isForStatusBar)
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
		if (self.isForStatusBar)
		{
			UIColor *newBodyColor = self.backupTextColor;

			// if ([self saverModeActive])
			// 	newBodyColor = [UIColor colorWithRed:1.0 green:0.839 blue:0.039 alpha:1];
      // else if ([self chargingState] != 0)
			// 	newBodyColor = [UIColor systemGreenColor];
			// else if ([self chargePercent] <= 0.10)
		 	// 	newBodyColor = [UIColor redColor];
			// else if ([self chargePercent] <= 0.20)
			// 	newBodyColor = [UIColor orangeColor];

			[self setBodyColor:newBodyColor];
			[self setPinColor:newBodyColor];
		}
	}

	-(id)_batteryTextColor
	{
		if ([self saverModeActive] || [self chargingState] != 0)
			return [UIColor blackColor];
		else
		{
			CGFloat r,g,b,a;
			[self.backupTextColor getRed:&r green:&g blue:&b alpha:&a];
			return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
		}
	}

	-(id)_batteryFillColor
	{
		self.isFetchingBatteryFillColor = YES;
		self.backupTextColor = %orig;
		self.isFetchingBatteryFillColor = NO;

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
		return self.isForStatusBar && !self.isFetchingBatteryFillColor;
	}

	-(BOOL)showsPercentage
	{
		return self.isForStatusBar && !self.isFetchingBatteryFillColor;
	}

	-(void)setShowsPercentage:(BOOL)arg1
	{
		%orig(self.isForStatusBar);
	}

%end
