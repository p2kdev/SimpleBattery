#import <UIKit/UIKit.h>

@interface CALayer (SB)
	@property (nonatomic, retain) NSString *compositingFilter;
	@property (nonatomic, assign) BOOL allowsGroupOpacity;
	@property (nonatomic, assign) BOOL allowsGroupBlending;
@end

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
	@property (readonly, nonatomic, getter=isLowBattery) BOOL lowBattery;	
	@property (nonatomic,retain) CALayer * fillLayer;
	@property (nonatomic,copy) UIColor * fillColor;
	@property (nonatomic,copy) UIColor * bodyColor;
	@property (nonatomic,copy) UIColor * pinColor;
	@property (nonatomic,retain) CALayer * bodyLayer;
	-(UIColor*)_batteryTextColor;
	-(void)setShowsPercentage:(BOOL)arg1;
	-(void)setFillLayer:(CALayer *)arg1;
	- (CGRect)_bodyRectForTraitCollection:(id)arg0;
	- (id)_batteryFillColor;
	- (void)_updateBatteryFillColor;
	- (void)_updatePercentage;
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
static double labelFontSize = 15;
static double stockLabelFontSize = 10;
static double labelY = 0;

extern NSString *const kCAFilterDestOut;

%group common

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
				if (style >= 4)
				orig.hidden = YES;
			return orig;
		}

	%end

%end

%group commonstyle

	%hook _UIBatteryView

		%property (nonatomic, retain) UILabel *sbPercentageLabel;
		%property (assign,nonatomic) BOOL isForStatusBar;
		%property (assign,nonatomic) BOOL isFetchingBatteryFillColor;
		%property (nonatomic, retain) UIColor *backupTextColor;

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

			if (style < 4 && self.percentageLabel)
				self.percentageLabel.font = [UIFont systemFontOfSize:stockLabelFontSize weight:UIFontWeightBold];		
		}

		-(void)_updateFillColor
		{
			%orig;
			if (self.isForStatusBar && style > 1)
			{
				UIColor *newBodyColor = [UIColor labelColor];

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

			if (style < 4 && self.percentageLabel)
				self.percentageLabel.font = [UIFont systemFontOfSize:stockLabelFontSize weight:UIFontWeightBold];		
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

		-(void)_updatePercentage
		{
			%orig;
			if (style < 4 && self.percentageLabel)
				self.percentageLabel.font = [UIFont systemFontOfSize:stockLabelFontSize weight:UIFontWeightBold];
		}

	%end

%end

%group style16

	%hook _UIBatteryView

		%property (assign,nonatomic) BOOL isForStatusBar;

		- (id)initWithFrame:(CGRect)arg1 {
			self = %orig;
			if (self) {
				self.isForStatusBar = NO;
			}
			return self;
		}

		- (id)_batteryTextColor {
			if (self.isForStatusBar) {
				if (self.saverModeActive)
					return [UIColor blackColor];
				else if (self.chargingState == 1)
					return [UIColor whiteColor];
				else
					return %orig;
			}
			return %orig;
		}	

		- (UIColor *)_batteryFillColor { // Return default or custom fill colors based on charging state

			if (!self.isForStatusBar)
				return %orig;

			UIColor *fillColor;

			if (!self.saverModeActive) { // Normal use
				if (self.chargingState == 1) { // Charging
					fillColor =  [UIColor systemGreenColor]; 
				} else if (self.lowBattery) {
					fillColor =  [UIColor systemRedColor];
				} else fillColor = [UIColor labelColor]; // Color of normal use (not charging & not in Low Power mode)
			} else { // Low Power, overrides custom charging color
				fillColor = [UIColor systemYellowColor];
			}

			if (self.chargePercent > 0.96)
				[self setPinColor:fillColor];
			else
				[self setPinColor:[[UIColor labelColor] colorWithAlphaComponent:0.4]];

			return fillColor;
		}

		- (void)setSaverModeActive:(BOOL)arg1 {
			%orig;

			if (self.isForStatusBar)
				[self _updatePercentage];
		}

		- (void)_updatePercentage {
			%orig;

			if (!self.isForStatusBar)
				return;

			self.percentageLabel.font = [UIFont systemFontOfSize:(self.chargePercent == 1.0 && stockLabelFontSize > 10) ? 10 : stockLabelFontSize weight:UIFontWeightHeavy]; // Set custom percentage font size
			self.percentageLabel.layer.allowsGroupBlending = YES;
			self.percentageLabel.layer.allowsGroupOpacity = YES;
			self.percentageLabel.layer.compositingFilter = ((self.chargingState != 1) && !self.saverModeActive) ? kCAFilterDestOut : nil; // Enable cutout effect on text when in transparent mode or default (when not charging)

			[self.percentageLabel sizeToFit];
			if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) { // Support RTL languages
				self.percentageLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
			}			
		}

		- (CGFloat)bodyColorAlpha {
			return self.isForStatusBar ? 1.0 : %orig; // Overrides default fill color alpha (normally 0.4)			
		}

		- (CAShapeLayer *)bodyShapeLayer {
			CAShapeLayer *bodyLayer = %orig;

			if (self.isForStatusBar)
				bodyLayer.fillColor = [[UIColor labelColor] colorWithAlphaComponent:0.4].CGColor; // Fill exisiting battery view completely

			return bodyLayer;
		}	

		+ (id)_pinBezierPathForSize:(struct CGSize )arg0 complex:(BOOL)arg1 {
			UIBezierPath *path = %orig;
			[path applyTransform:CGAffineTransformMakeTranslation(0.8, 0)]; // Shift pin 1 px, done because setting line interspace width to fill body adds border
			return path;
		}


		// -(void)setChargePercent:(double)arg1
		// {
		// 	arg1 = 0.90;
		// 	%orig;
		// }	

		- (void)_updateFillLayer {
			%orig;

			if (self.isForStatusBar)
				[self.fillLayer setCornerRadius:3.50]; // Set fill corner radius whenever layer updates
		}	

		// -(double)_insideCornerRadiusForTraitCollection:(id)arg1 {
		// 	if (!self.isForStatusBar)
		// 		return %orig;

		// 	return 3.0; // Slightly adjust corner radius for expanded height			
		// }			

		- (CGFloat)_outsideCornerRadiusForTraitCollection:(id)arg0 {			
			if (!self.isForStatusBar)
				return %orig;

			return 3.50; // Slightly adjust corner radius for expanded height
		}					

		- (CALayer *)fillLayer {
			CALayer *fill = %orig;

			if (self.isForStatusBar)
			{
				fill.maskedCorners = (self.chargePercent > 0.88) ? (kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner) : (kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner); // Rounded corners always on leading edge, flat on trailing until above 85% to match stock radius
				fill.bounds = CGRectMake(fill.bounds.origin.x, fill.bounds.origin.y - 0.6, fill.bounds.size.width , self.bounds.size.height+1.2);
			}

		 	return fill;
		}

		- (CGRect)_bodyRectForTraitCollection:(id)arg0 {
			CGRect bodyRect = %orig;
			// Resize view height to better replicate iOS 16
			return self.isForStatusBar ? CGRectMake(bodyRect.origin.x, bodyRect.origin.y - 0.6, bodyRect.size.width , bodyRect.size.height + 1.2) : bodyRect;	
		}

		- (CGFloat)_lineWidthAndInterspaceForTraitCollection:(id)arg0 {
			return self.isForStatusBar ? 0 : %orig; // Disable space between fill layer and border of body layer
		}

		- (BOOL)_shouldShowBolt {
			return self.isForStatusBar ? NO : %orig; // Disable interior bolt when charging
		}

		-(BOOL)showsInlineChargingIndicator
		{
			return self.isForStatusBar ? NO : %orig;
		}		

		- (BOOL)_currentlyShowsPercentage {
			return self.isForStatusBar ? YES : %orig;  // Always display battery percentage label
		}

	%end

%end

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void reloadSettings() {
		static CFStringRef prefsKey = CFSTR("com.p2kdev.simplebattery");
		CFPreferencesAppSynchronize(prefsKey);

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"style", prefsKey))) {
			style = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"style", prefsKey)) intValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"labelFontSize", prefsKey))) {
			labelFontSize = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"labelFontSize", prefsKey)) doubleValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"stockLabelFontSize", prefsKey))) {
			stockLabelFontSize = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"stockLabelFontSize", prefsKey)) doubleValue];
		}		

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"labelY", prefsKey))) {
			labelY = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"labelY", prefsKey)) doubleValue];
		}
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.p2kdev.simplebattery.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.p2kdev.simplebattery.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	%init(common);

	if (style == 5)
		%init(style16);
	else
		%init(commonstyle);
}
