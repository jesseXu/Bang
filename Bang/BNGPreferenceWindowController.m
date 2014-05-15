//
//  PreferenceWindowController.m
//  Bang
//
//  Created by Jesse on 14-5-13.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "BNGPreferenceWindowController.h"

@interface BNGPreferenceWindowController ()

@end

@implementation BNGPreferenceWindowController

+ (BNGPreferenceWindowController *)sharedController {
    static BNGPreferenceWindowController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[BNGPreferenceWindowController alloc] initWithWindowNibName:@"BNGPreferenceWindowController"];
    });
    
    return controller;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}




@end
