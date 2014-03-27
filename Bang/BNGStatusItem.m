//
//  BNGStatusItem.m
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "BNGStatusItem.h"

@implementation BNGStatusItem

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat offset = (NSWidth(self.bounds) - 20) / 2;
    NSRect iconFrame = NSMakeRect(offset, 0, 20, 20);

    if (self.highlighted) {
        NSImage *iconImage = [NSImage imageNamed:@"status-bar-red"];
        [iconImage drawInRect:iconFrame];
    } else {
        NSImage *iconImage = [NSImage imageNamed:@"status-bar"];
        [iconImage drawInRect:iconFrame];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

@end
