//
//  NotificationService.m
//  KumulosNotificationServiceExtension
//
//  Created by Vladislav Voicehovics on 06/12/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "NotificationService.h"

@interface NotificationService ()

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
     [KumulosNotificationService didReceiveNotificationRequest:request withContentHandler: contentHandler];
}

@end
