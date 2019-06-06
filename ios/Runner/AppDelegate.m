#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <KumulosSDK/KumulosSDK.h>
@import UserNotifications;
@import CoreLocation;

@interface AppDelegate () <UNUserNotificationCenterDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *lm;
@property (nonatomic, strong) FlutterMethodChannel *locationChannel;
@property (nonatomic, strong) FlutterMethodChannel *pushChannel;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Register the app delegate as the notification center handler
    [UNUserNotificationCenter.currentNotificationCenter setDelegate:self];

    // Kumulos SDK
    NSString* apiKey = [NSUserDefaults.standardUserDefaults objectForKey:@"K_API_KEY"];
    NSString* secretKey = [NSUserDefaults.standardUserDefaults objectForKey:@"K_SECRET_KEY"];

    if (apiKey != nil && secretKey != nil) {
        KSConfig* cfg = [KSConfig configWithAPIKey:apiKey andSecretKey:secretKey];
        [Kumulos initializeWithConfig:cfg];

        // Location
        [self setupLocationMonitoring];
    }

    // Flutter interop
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;

    FlutterMethodChannel* kumulosChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"com.kumulos.flutter"
                                            binaryMessenger:controller];

    __weak typeof(self) weakSelf = self;
    [kumulosChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if ([call.method isEqualToString:@"getInstallId"]) {
            result(Kumulos.installId);
        } else if ([call.method isEqualToString:@"init"]) {
            [weakSelf initSdkFromCall:call withResultHandler:result];
        } else if ([call.method isEqualToString:@"trackEvent"]) {
            [weakSelf trackEventFromCall:call withResultHandler:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    // Pairing
    FlutterMethodChannel* pairingChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"com.kumulos.companion.pairing"
                                            binaryMessenger:controller];

    [pairingChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if ([call.method isEqualToString:@"unpair"]) {
            [Kumulos.shared pushUnregister];

            if (CLLocationManager.significantLocationChangeMonitoringAvailable) {
                [weakSelf.lm stopMonitoringSignificantLocationChanges];
                weakSelf.lm = nil;
            }

            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"K_API_KEY"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"K_SECRET_KEY"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"locationSent"];

            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    //push
    self.pushChannel = [FlutterMethodChannel
                             methodChannelWithName:@"com.kumulos.companion.push"
                             binaryMessenger:controller];

    [self.pushChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if ([call.method isEqualToString:@"pushRegister"]) {
            [weakSelf pushRegisterFromCall:call withResultHandler:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    //location
    self.locationChannel = [FlutterMethodChannel
                             methodChannelWithName:@"com.kumulos.companion.location"
                             binaryMessenger:controller];

    [self.locationChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if ([call.method isEqualToString:@"requestLocation"]) {
            [weakSelf requestLocationUpdatesFromCall:call withResultHandler:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark - Push

- (void) pushRegisterFromCall:(FlutterMethodCall*)call withResultHandler:(FlutterResult)result {

    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 10) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge;
        __weak typeof(self) weakSelf = self;

        [center requestAuthorizationWithOptions:(options) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (weakSelf == nil){
                return;
            }

            if (granted && error == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication.sharedApplication registerForRemoteNotifications];
                });
            }
            else{
                [weakSelf.pushChannel invokeMethod:@"pushUnauthorized" arguments:nil];
            }
        }];
    }
    else if ((systemVersion < 10) || (systemVersion >= 8)) {
        UIUserNotificationType options = (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:options categories:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication registerUserNotificationSettings:mySettings];
        });
    }
    else {
        //not supported
    }

    result(nil);
}

//iOS 8-10
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    BOOL allowsSound = (notificationSettings.types & UIUserNotificationTypeSound) != 0;
    BOOL allowsBadge = (notificationSettings.types & UIUserNotificationTypeBadge) != 0;
    BOOL allowsAlert = (notificationSettings.types & UIUserNotificationTypeAlert) != 0;

    if (allowsSound && allowsAlert && allowsBadge){
        [application registerForRemoteNotifications];
    }
    else{
        [self.pushChannel invokeMethod:@"pushUnauthorized" arguments:nil];
    }
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Kumulos.shared pushRegisterWithDeviceToken:deviceToken];

    [self.pushChannel invokeMethod:@"pushRegistered" arguments:nil];
}

// iOS 7-9 handler for push notifications (bg + fg)
// iOS 10+ handler for background data pushes (content-available)
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateInactive) {
        [Kumulos.shared pushTrackOpenFromNotification:userInfo];
    }

    NSDictionary* alert = userInfo[@"aps"][@"alert"];
    NSString* title = @"";
    NSString* message = @"";
    if (alert != nil){
       title = alert[@"title"];
       message = alert[@"body"];
    }

    NSDictionary* map = @{ @"title" : title, @"message" : message};

    [self.pushChannel invokeMethod:@"pushReceived" arguments:map];

    // Handle opening URLs on notification taps
    NSURL* url = [NSURL URLWithString:userInfo[@"custom"][@"u"]];
    if (url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication openURL:url];
        });
    }

    completionHandler(UIBackgroundFetchResultNoData);
}

// Called on iOS10 when your app is in the foreground to allow customizing the display of the notification
- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

    NSString* title = notification.request.content.title;
    NSString* message = notification.request.content.body;

    NSDictionary* map = @{ @"title" : title, @"message" : message};

    [self.pushChannel invokeMethod:@"pushReceived" arguments:map];

    completionHandler(UNNotificationPresentationOptionAlert);
}

// iOS10 handler for when a user taps a notification
- (void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary* userInfo = response.notification.request.content.userInfo;
    [Kumulos.shared pushTrackOpenFromNotification:userInfo];

    // Handle URL pushes
    NSURL* url = [NSURL URLWithString:userInfo[@"custom"][@"u"]];
    if (url) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
            /* noop */
        }];
    }

    completionHandler();
}

#pragma mark - Kumulos

- (void) initSdkFromCall:(FlutterMethodCall*)call withResultHandler:(FlutterResult)result {
    NSString* apiKey = call.arguments[0];
    NSString* secretKey = call.arguments[1];

    [NSUserDefaults.standardUserDefaults setObject:apiKey forKey:@"K_API_KEY"];
    [NSUserDefaults.standardUserDefaults setObject:secretKey forKey:@"K_SECRET_KEY"];

    KSConfig* cfg = [KSConfig configWithAPIKey:apiKey andSecretKey:secretKey];
    [Kumulos initializeWithConfig:cfg];

    result(nil);
}

- (void) trackEventFromCall:(FlutterMethodCall*)call withResultHandler:(FlutterResult)result {
    NSString* type = call.arguments[0];
    NSDictionary* props = call.arguments[1];
    NSNumber* immediateFlush = call.arguments[2];

    if ([props isKindOfClass:[NSNull class]]) {
        props = nil;
    }

    if (immediateFlush.intValue == 1) {
        [Kumulos.shared trackEventImmediately:type withProperties:props];
    } else {
        [Kumulos.shared trackEvent:type withProperties:props];
    }

    result(nil);
}

#pragma mark - Location handling

- (void) requestLocationUpdatesFromCall:(FlutterMethodCall*)call withResultHandler:(FlutterResult)result {
    [self setupLocationMonitoring];

    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"locationSent"];

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusNotDetermined == status) {
        [self.lm requestAlwaysAuthorization];
    }

    result(nil);
}

- (void) setupLocationMonitoring {
    self.lm = [CLLocationManager new];
    self.lm.allowsBackgroundLocationUpdates = YES;
    self.lm.pausesLocationUpdatesAutomatically = NO;
    [self.lm setDelegate:self];

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusAuthorizedAlways == status || kCLAuthorizationStatusAuthorizedWhenInUse == status) {
        [self startLocationMonitoring];
    }
}
- (void) startLocationMonitoring {
    if (CLLocationManager.significantLocationChangeMonitoringAvailable) {
        [self.lm startMonitoringSignificantLocationChanges];
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (kCLAuthorizationStatusAuthorizedAlways == status || kCLAuthorizationStatusAuthorizedWhenInUse == status) {
        [self startLocationMonitoring];
        [self.locationChannel invokeMethod:@"locationAuthorized" arguments:nil];

        if (self.lm.location != nil) {
            CLLocation* location = self.lm.location;
            [Kumulos.shared trackEventImmediately:@"companion.locationUpdated"
                                   withProperties:@{
                                                    @"lat": @(location.coordinate.latitude),
                                                    @"lng": @(location.coordinate.longitude)
                                                    }];
            [NSUserDefaults.standardUserDefaults setObject:@(1) forKey:@"locationSent"];
        }
    }
    else if (kCLAuthorizationStatusDenied == status) {
        [self.locationChannel invokeMethod:@"locationNotAuthorized" arguments:nil];
        if (CLLocationManager.significantLocationChangeMonitoringAvailable) {
            [self.lm stopMonitoringSignificantLocationChanges];
        }
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if ([NSUserDefaults.standardUserDefaults objectForKey:@"locationSent"] == nil && locations.count > 0) {
        [Kumulos.shared trackEventImmediately:@"companion.locationUpdated"
                    withProperties:@{
                                     @"lat": @(locations[0].coordinate.latitude),
                                     @"lng": @(locations[0].coordinate.longitude)
                                     }];
        [NSUserDefaults.standardUserDefaults setObject:@(1) forKey:@"locationSent"];
    }

    if (Kumulos.shared) {
        for (CLLocation* loc in locations) {
            [Kumulos.shared sendLocationUpdate:loc];
        }
    }
}

@end
