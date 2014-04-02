//
//  BNGMainViewController.h
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BNGMainViewController : NSViewController

- (BOOL)uploadFile:(PFFile *)file
              name:(NSString *)fileName
              type:(NSString *)fileType;

@end
