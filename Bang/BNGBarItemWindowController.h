//
//  BNGBarItemController.h
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BNGBarItemWindowController : NSWindowController

+ (BNGBarItemWindowController *)sharedController;

- (void)changeToLoginViewController;
- (void)changeToMainViewController;
- (void)showWindow;
- (void)hideWindow;

- (void)setStatusItemHighligted:(BOOL)highlighted;

@end
