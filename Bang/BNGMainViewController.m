//
//  BNGMainViewController.m
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "BNGMainViewController.h"
#import "BNGBarItemWindowController.h"
#import "BNGTableCell.h"

@interface BNGMainViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSButton *addButton;
@property (strong) IBOutlet NSMenu *preferenceMenu;

@property (assign, nonatomic) BOOL isUploading;
@property (strong, nonatomic) NSMutableArray *items;

@end


@implementation BNGMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        self.items = [NSMutableArray array];
        
        // Fetch Data
        [self fetchUserItems];
        
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
}


#pragma mark - Actions

- (IBAction)preferenceAction:(NSButton *)sender {
    NSPoint location = [sender convertPoint:NSMakePoint(10, NSMaxY(sender.frame)) fromView:nil];
    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                         location:location
                                    modifierFlags:NSLeftMouseDownMask
                                        timestamp:[[NSDate date] timeIntervalSince1970]
                                     windowNumber:[[sender window] windowNumber]
                                          context:[[sender window] graphicsContext]
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
    
    [NSMenu popUpContextMenu:self.preferenceMenu
                   withEvent:event
                     forView:sender];
}


- (IBAction)addAction:(id)sender {
    // hide window
    [[BNGBarItemWindowController sharedController] hideWindow];
    
    // capture
    [self capture];
}


- (IBAction)linkAction:(id)sender {
    NSInteger row = [self.tableView rowForView:sender];
    PFObject *item = [self.items objectAtIndex:row];
    PFFile *file = item[@"imageFile"];

    // copy url to pasteboard
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:self];
    if ([pboard setString:file.url forType:NSPasteboardTypeString]) {
        [self updateStatus:@"Copied to pasteboard!" shouldHide:YES];
    }
}


- (IBAction)deleteAction:(id)sender {
    NSInteger row = [self.tableView rowForView:sender];
    PFObject *item = [self.items objectAtIndex:row];
    [item deleteInBackground];
    
    // update the table view
    [self.tableView beginUpdates];
    [self.items removeObject:item];
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                          withAnimation:NSTableViewAnimationEffectFade];
    [self.tableView endUpdates];
}


#pragma mark - Menu Actions

- (IBAction)startAtLoginAction:(id)sender {
    
}

- (IBAction)signOutAction:(id)sender {

    // clear data
    [self.items removeAllObjects];
    [self.tableView reloadData];

    // log out
    [PFUser logOut];
    
    // change to login view
    [[BNGBarItemWindowController sharedController] changeToLoginViewController];
}

- (IBAction)quitAction:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}


#pragma mark - utility

- (void)capture {
    @try {
        
        NSTask* task = [[NSTask alloc] init];
        [task setArguments: [NSArray arrayWithObject: @"-ic"]];
        [task setLaunchPath: @"/usr/sbin/screencapture"];
        [task launch];
        [task waitUntilExit];
        
        NSData* data = [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypePNG];
        [self uploadData:data];
    }
    @catch (NSException *exception) {
        
    }
}


- (void)uploadData:(NSData *)data {
    
    if (data == nil) {
        return;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"SC%@", @((NSInteger)[[NSDate date] timeIntervalSince1970])];
    
    // Upload file first
    self.isUploading = YES;
    [self updateStatus:@"Uploading.." shouldHide:NO];

    PFFile *imageFile = [PFFile fileWithName:fileName data:data];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            // then save object
            [self updateStatus:@"Saving.." shouldHide:NO];

            PFObject *screenCapture = [PFObject objectWithClassName:@"UserFiles"];
            screenCapture[@"imageName"] = fileName;
            screenCapture[@"imageFile"] = imageFile;
            screenCapture[@"user"] = [PFUser currentUser];
            
            PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
            [acl setPublicReadAccess:YES];
            [screenCapture setACL:acl];
            
            [screenCapture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {

                if (succeeded) {
                    [self updateStatus:@"Done!" shouldHide:YES];
                } else {
                    [self updateStatus:[NSString stringWithFormat:@"Error:%@", error.userInfo] shouldHide:NO];
                }
                
                self.isUploading = NO;
                
                // change the status bar item color
                [[BNGBarItemWindowController sharedController] setStatusItemHighligted:YES];

                // update the table view
                [self.tableView beginUpdates];
                [self.items insertObject:screenCapture atIndex:0];
                [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                      withAnimation:NSTableViewAnimationSlideDown];
                [self.tableView endUpdates];
            }];
            
        } else {
            
            [self updateStatus:[NSString stringWithFormat:@"Error:%@", error.userInfo] shouldHide:NO];
            self.isUploading = NO;

        }
    } progressBlock:^(int percentDone) {
        [self updateStatus:[NSString stringWithFormat:@"Uploading (%d%%)", percentDone] shouldHide:NO];
    }];
}


- (void)fetchUserItems {
    PFQuery *query = [PFQuery queryWithClassName:@"UserFiles"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            
            [self.items addObjectsFromArray:objects];
            [self.tableView reloadData];
            
            NSLog(@"Fetch items : %ld", objects.count);
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}


- (void)setIsUploading:(BOOL)isUploading {
    _isUploading = isUploading;
    if (isUploading) {
        [self.addButton setEnabled:NO];
    } else {
        [self.addButton setEnabled:YES];
    }
}


- (void)updateStatus:(NSString *)string shouldHide:(BOOL)shouldHide {
    self.statusLabel.stringValue = string;
    
    // set @"" after 1 second
    if (shouldHide) {
        [[self.statusLabel class] cancelPreviousPerformRequestsWithTarget:self];
        [self.statusLabel performSelector:@selector(setStringValue:)
                               withObject:@""
                               afterDelay:2.0f];
    }
}


#pragma mark - TableView

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    BNGTableCell *cell = [tableView makeViewWithIdentifier:@"BNGTableCell" owner:self];
   
    PFObject *item = [self.items objectAtIndex:row];
    cell.nameLabel.stringValue = item[@"imageName"];
    cell.timeLabel.stringValue = [item.createdAt description];
    
    return cell;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.items.count;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 60.0f;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([self.tableView selectedRow] != -1) {
        PFObject *item = [self.items objectAtIndex:[self.tableView selectedRow]];
        PFFile *imageFile = item[@"imageFile"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:imageFile.url]];
    }
}

@end
