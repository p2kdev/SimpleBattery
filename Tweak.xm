@interface _UIBatteryView: UIView
  @property NSInteger chargingState;
  @property CGFloat chargePercent;
  @property BOOL saverModeActive;
  @property(nonatomic, readwrite) UIColor *fillColor;
  @property(nonatomic, retain) UIColor *backupFillColor;
  @property(nonatomic, retain) UILabel *percentLabel;
  - (void)updatePercentageColor;
  - (id)hasGestureRecognizer;
  - (void)setHasGestureRecognizer:(id)arg;
  - (void)fireDoubleTapAction;
  - (void)fireHoldAction;
@end

@interface _UIStatusBarImageView : UIView

@end

@interface _UIStaticBatteryView : _UIBatteryView
@end

static int fontSize = 16;
static double offsetY = -0.5;

%hook _UIStatusBarBatteryItem

  -(_UIBatteryView *)batteryView
  {
    _UIBatteryView *orig = %orig;
    if (!orig.percentLabel)
    {
      orig.percentLabel = [[UILabel alloc] initWithFrame: CGRectZero];
      [orig addSubview: orig.percentLabel];
      orig.percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
			[orig.percentLabel.leadingAnchor constraintEqualToAnchor:orig.leadingAnchor].active = YES;
      [orig.percentLabel.centerYAnchor constraintEqualToAnchor:orig.centerYAnchor constant:offsetY].active = YES;
      NSString *percentChar = @"";
      if (orig.chargePercent < 1)
        percentChar = @"%";

      [orig.percentLabel setText: [NSString stringWithFormat:@"%.0f%@", floor(orig.chargePercent * 100),percentChar]];
			[orig.percentLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
			[orig.percentLabel sizeToFit];
			orig.percentLabel.textAlignment = NSTextAlignmentLeft;
    }

		return orig;
  }

  //Hide the charging view
  -(_UIStatusBarImageView *)chargingView
  {
    _UIStatusBarImageView *orig = %orig;
    orig.hidden = YES;
    return orig;
  }

%end

%hook _UIBatteryView

  %property (nonatomic, retain) UILabel *percentLabel;
  %property (nonatomic, retain) UIColor *backupFillColor;

	- (void)setChargePercent: (CGFloat)percent
  	{
  		%orig;
      //percent = 1;
      if (self.percentLabel)
      {
        NSString *percentChar = @"";
        if (percent < 1)
          percentChar = @"%";

  		  [[self percentLabel] setText: [NSString stringWithFormat:@"%.0f%@", floor(percent * 100),percentChar]];
      }
  	}

  	// Update percentage label color in various events
  	%new
  	- (void)updatePercentageColor
  	{
  		if([self chargingState] != 0) [[self percentLabel] setTextColor: [UIColor greenColor]];
  		else if([self saverModeActive]) [[self percentLabel] setTextColor:  [UIColor colorWithRed:1.0 green:0.839 blue:0.039 alpha:1]];
  		else if([self chargePercent] <= 0.10) [[self percentLabel] setTextColor: [UIColor redColor]];
  		else if([self chargePercent] <= 0.20) [[self percentLabel] setTextColor:[UIColor orangeColor]];
  		else [[self percentLabel] setTextColor: [self backupFillColor]];
  	}

  	- (void)setChargingState: (long long)arg1
  	{
  		%orig;
      if (self.percentLabel)
  		  [self updatePercentageColor];
  	}

  	- (void)setSaverModeActive: (BOOL)arg1
  	{
  		%orig;
      if (self.percentLabel)
  		  [self updatePercentageColor];
  	}

  	- (void)_updateFillLayer
  	{
  		%orig;
      if (self.percentLabel)
  		  [self updatePercentageColor];
  	}

  	// Do not update any color automatically
  	- (void)_updateFillColor
  	{
      if (!self.percentLabel)
        %orig;
  	}

  	- (void)_updateBodyColors
  	{
      if (!self.percentLabel)
        %orig;
  	}

  	- (void)_updateBatteryFillColor
  	{
      if (!self.percentLabel)
        %orig;
  	}

  	// Return clear fill color but keep a backup of it
  	- (void)setFillColor: (UIColor*)arg1
  	{
  		[self setBackupFillColor: arg1];
      if (self.percentLabel)
        arg1 = [UIColor clearColor];
  		%orig(arg1);
  	}

  	- (UIColor*)fillColor
  	{
      if (!self.percentLabel)
        return %orig;
      else
  		  return [UIColor clearColor];
  	}

  	// Hide body component completely
  	- (void)setBodyColor: (UIColor*)arg1
  	{
      if (self.percentLabel)
        arg1 = [UIColor clearColor];

  		%orig(arg1);
  	}

  	- (UIColor*)bodyColor
  	{
      if (!self.percentLabel)
        return %orig;
      else
  		  return [UIColor clearColor];
  	}

  	// Hide pin component completely
  	- (void)setPinColor: (UIColor*)arg1
  	{
      if (self.percentLabel)
        arg1 = [UIColor clearColor];

  		%orig(arg1);
  	}

  	- (UIColor*)pinColor
  	{
      if (!self.percentLabel)
        return %orig;
      else
  		  return [UIColor clearColor];
  	}

  	- (CAShapeLayer*)pinShapeLayer
  	{
      if (!self.percentLabel)
        return %orig;
      else
  		  return nil;
  	}

    -(BOOL)_shouldShowBolt
    {
      if (!self.percentLabel)
        return %orig;
      else
        return NO;
    }

  	// Hide bolt symbol while charging
  	- (void)setShowsInlineChargingIndicator: (BOOL)showing
  	{
      if (self.percentLabel)
        showing = NO;

  		%orig(showing);
  	}

%end

%ctor
{
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.p2kdev.simplebattery.plist"];
  if(prefs)
  {
    fontSize = [prefs objectForKey:@"fontSize"] ? [[prefs objectForKey:@"fontSize"] intValue] : fontSize;
    offsetY = [prefs objectForKey:@"offsetY"] ? [[prefs objectForKey:@"offsetY"] doubleValue] : offsetY;
  }
}
