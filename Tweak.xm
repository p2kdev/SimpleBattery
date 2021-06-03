@interface _UIBatteryView: UIView
	@property (nonatomic,retain) UILabel * percentageLabel;
	@property (assign,nonatomic) double chargePercent;
	@property (assign,nonatomic) long long chargingState;
	@property (assign,nonatomic) BOOL saverModeActive;
	@property (assign,nonatomic) BOOL showsPercentage;
	@property (assign,nonatomic) BOOL isForStatusBar;
  @property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
  @property(nonatomic, retain) UIColor *backupTextColor;
	@property (nonatomic,copy) UIColor * bodyColor;
	@property (nonatomic,copy) UIColor * pinColor;
	-(void)setShowsPercentage:(BOOL)arg1;
	-(void)setFillLayer:(CALayer *)arg1;
	-(void)updatePercentageColor;
@end

%hook _UIStatusBarBatteryItem

	-(_UIBatteryView *)batteryView
	{
		_UIBatteryView *orig = %orig;
		orig.isForStatusBar = YES;
		return orig;
	}

%end

%hook _UIBatteryView

  %property (assign,nonatomic) BOOL isForStatusBar;
  %property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
	%property(nonatomic, retain) UIColor *backupTextColor;

	-(void)_updateFillColor
	{
		%orig;
		if (self.isForStatusBar)
		{
			UIColor *newBodyColor = self.backupTextColor;

			if ([self saverModeActive])
				newBodyColor = [UIColor colorWithRed:1.0 green:0.839 blue:0.039 alpha:1];
      else if ([self chargingState] != 0)
				newBodyColor = [UIColor systemGreenColor];
			else if ([self chargePercent] <= 0.10)
		 		newBodyColor = [UIColor redColor];
			else if ([self chargePercent] <= 0.20)
				newBodyColor = [UIColor orangeColor];

			[self setBodyColor:newBodyColor];
			[self setPinColor:newBodyColor];
		}
	}

	-(id)_batteryFillColor
	{
		self.isFetchingBatteryFillColor = YES;
		self.backupTextColor = %orig;
		self.isFetchingBatteryFillColor = NO;

		if (self.isForStatusBar)
			return [UIColor clearColor];
		else
			return self.backupTextColor;
	}

	-(BOOL)_shouldShowBolt
	{
		return self.isForStatusBar ? NO : (self.chargingState != 0 ? YES : %orig);
	}

  -(BOOL)showsInlineChargingIndicator
  {
    return self.isForStatusBar ? NO : (self.chargingState != 0 ? YES : %orig);
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
		arg1 = self.isForStatusBar;
		%orig;
	}

%end
