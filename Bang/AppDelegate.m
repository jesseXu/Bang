//
//  AppDelegate.m
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "AppDelegate.h"
#import "BNGBarItemWindowController.h"

/*
 * You need to parse.com to create an App
 * then get the ApplicationId and ClientKey
 */

//#define kParseApplicationId @"YOUR_APPLICATION_ID"
//#define kParseClientKey     @"YOUR_CLIENT_KEY"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // set up Parse
    [Parse setApplicationId:kParseApplicationId
                  clientKey:kParseClientKey];
    // Parse Tracking
    [PFAnalytics trackAppOpenedWithLaunchOptions:aNotification.userInfo];
    
    // set up status bar item
    [BNGBarItemWindowController sharedController];
    
    if ([PFUser currentUser] == nil) {
        [[BNGBarItemWindowController sharedController] changeToLoginViewController];
    } else {
        [[BNGBarItemWindowController sharedController] changeToMainViewController];
    }
}


@end
