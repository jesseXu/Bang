//
//  BNGBarItemController.m
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "BNGBarItemWindowController.h"
#import "BNGLoginViewController.h"
#import "BNGMainViewController.h"
#import "BNGStatusItem.h"

@interface BNGBarItemWindowController () <NSWindowDelegate>

@property (weak) IBOutlet NSView *container;
@property (weak) IBOutlet NSView *welcomeView;

@property (strong, nonatomic) NSStatusItem *barItem;
@property (strong, nonatomic) BNGStatusItem *statusBarItem;
@property (strong, nonatomic) BNGLoginViewController    *loginViewController;
@property (strong, nonatomic) BNGMainViewController     *mainViewController;


@end

@implementation BNGBarItemWindowController

+ (BNGBarItemWindowController *)sharedController {
    static BNGBarItemWindowController *_controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[BNGBarItemWindowController alloc] initWithWindowNibName:@"BNGBarItemWindowController"];
    });
    
    return _controller;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
        self.barItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        self.barItem.highlightMode = YES;
        
        BNGStatusItem *item = [[BNGStatusItem alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
        [item setTarget:self];
        [item setAction:@selector(itemDidClick:)];
        self.barItem.view = item;
        self.statusBarItem = item;
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSPanel *panel = (NSPanel *)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setDelegate:self];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
}


- (void)windowDidResignKey:(NSNotification *)notification {
    if ([self.window isVisible]) {
        [self hideWindow];
    }
}


#pragma mark - Actions

- (void)itemDidClick:(BNGStatusItem *)item {
    if ([self.window isVisible]) {
        [self hideWindow];
    } else {
        [self showWindow];
    }
    
    self.statusBarItem.highlighted = NO;
}


#pragma mark - Public Methord

- (void)changeToLoginViewController {
    if (self.loginViewController == nil) {
        self.loginViewController = [[BNGLoginViewController alloc] initWithNibName:@"BNGLoginViewController"
                                                                            bundle:nil];
    }

    NSRect windowFrame = self.window.frame;
    windowFrame.origin.y += NSHeight(windowFrame) - NSHeight(self.loginViewController.view.frame);
    windowFrame.size.height = NSHeight(self.loginViewController.view.frame) + 10;
    
    // need to add 10 points since it has an extra arrow
    windowFrame.origin.y -= 10;
    windowFrame.size.height += 10;
    
    [self.window setFrame:windowFrame display:YES];
    [self.welcomeView setHidden:YES];
    [self.container addSubview:self.loginViewController.view];
    
    // remove mainViewController
    if (self.mainViewController) {
        [self.mainViewController.view removeFromSuperview];
        self.mainViewController = nil;
    }
}


- (void)changeToMainViewController {
    if (self.mainViewController == nil) {
        self.mainViewController = [[BNGMainViewController alloc] initWithNibName:@"BNGMainViewController"
                                                                          bundle:nil];
    }
    
    NSRect windowFrame = self.window.frame;
    windowFrame.origin.y += NSHeight(windowFrame) - NSHeight(self.mainViewController.view.frame);
    windowFrame.size.height = NSHeight(self.mainViewController.view.frame);
    
    // need to add 10 points since it has an extra arrow
    windowFrame.origin.y -= 10;
    windowFrame.size.height += 10;
    
    [self.window setFrame:windowFrame display:YES];
    [self.welcomeView setHidden:YES];
    [self.container addSubview:self.mainViewController.view];
    
    // remove loginViewController
    if (self.loginViewController) {
        [self.loginViewController.view removeFromSuperview];
        self.loginViewController = nil;
    }
}


- (void)showWindow {
    NSRect itemFrame = self.barItem.view.window.frame;
    NSRect windowFrame = self.window.frame;
    windowFrame.origin.x = NSMidX(itemFrame) - NSWidth(windowFrame) / 2;
    windowFrame.origin.y = NSMinY(itemFrame) - NSHeight(windowFrame) - 2.0f;
    [self.window setFrame:windowFrame display:YES];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)hideWindow {
    [self.window orderOut:nil];
}


- (void)setStatusItemHighligted:(BOOL)highlighted {
    self.statusBarItem.highlighted = highlighted;
}


@end
