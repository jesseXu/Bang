//
//  BNGTableCell.h
//  Bang
//
//  Created by Jesse on 14-3-26.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BNGTableCell : NSTableCellView

@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSButton *imageButton;

@end
