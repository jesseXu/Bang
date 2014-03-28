//
//  AppDelegate.m
//  Helper
//
//  Created by Jesse on 14-3-28.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"com.damarc.Bang"]) {
            alreadyRunning = YES;
        }
    }
    
    if (!alreadyRunning) {
        NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
        for (int i = 0; i < 4; i ++) {
            mainBundlePath = [mainBundlePath stringByDeletingLastPathComponent];
        }
        
        [[NSWorkspace sharedWorkspace] launchApplication:mainBundlePath];
    }
    
    [NSApp terminate:nil];
}

@end
