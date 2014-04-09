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

#import <ServiceManagement/ServiceManagement.h>


static NSString * const kUserDefaultsLoginAtStartKey    = @"StartAtLoginKey";
static NSString * const kParseShareTableName            = @"ShareTable";
static NSString * const kParseShareTableUserKey         = @"User";
static NSString * const kParseShareTableFileKey         = @"File";
static NSString * const kParseShareTableTypeKey         = @"Type";
static NSString * const kParseShareTableTitleKey        = @"Title";
static NSString * const kParseShareTableShortUrlKey     = @"ShortUrl";



@interface BNGMainViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView   *tableView;
@property (weak) IBOutlet NSTextField   *statusLabel;
@property (weak) IBOutlet NSButton      *addButton;
@property (strong) IBOutlet NSMenu      *preferenceMenu;
@property (strong) IBOutlet NSMenu      *addMenu;

@property (assign, nonatomic) BOOL isUploading;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) PFFile *uploadingFile;

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

    // set start at login value
    int startAtLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLoginAtStartKey] intValue];
    [(NSButton *)[self.preferenceMenu.itemArray objectAtIndex:0] setState:startAtLogin];
    
    // pop up menu
    NSPoint location = [sender convertPoint:NSMakePoint(10, NSMaxY(sender.frame)) toView:nil];
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


- (IBAction)addAction:(NSButton *)sender {
    if (self.isUploading) {
        
        [self cancelUpload];
        
    } else {
        // pop up menu
        NSPoint location = [sender convertPoint:NSMakePoint(10, NSMaxY(sender.frame)) toView:nil];
        NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                             location:location
                                        modifierFlags:NSLeftMouseDownMask
                                            timestamp:[[NSDate date] timeIntervalSince1970]
                                         windowNumber:[[sender window] windowNumber]
                                              context:[[sender window] graphicsContext]
                                          eventNumber:0
                                           clickCount:1
                                             pressure:1];
        
        [NSMenu popUpContextMenu:self.addMenu
                       withEvent:event
                         forView:sender];
    }
}



- (IBAction)itemImageAction:(id)sender {
    NSInteger row = [self.tableView rowForView:sender];
    PFObject *item = [self.items objectAtIndex:row];
    PFFile *file = item[kParseShareTableFileKey];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:file.url]];
}

- (IBAction)linkAction:(id)sender {
    NSInteger row = [self.tableView rowForView:sender];
    PFObject *item = [self.items objectAtIndex:row];
    [self copyFileLinkToPasteboard:item];
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
    NSButton *button = sender;
    if (button.state == NSOffState) { // ON
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.damarc.Helper", YES)) {
            button.state = NSOnState;
        }
    } else {
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.damarc.Helper", NO)) {
            button.state = NSOffState;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(button.state) forKey:kUserDefaultsLoginAtStartKey];
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


- (IBAction)captureScheenshotAction:(id)sender {
    // hide window
    [[BNGBarItemWindowController sharedController] hideWindow];
    
    // capture
    [self capture];
}


- (IBAction)shareFileAction:(id)sender {
    // hide window
    [[BNGBarItemWindowController sharedController] hideWindow];
    
    // open FileChooser
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    if ( [openPanel runModal] == NSOKButton )
    {
        NSURL *fileUrl = [[openPanel URLs] objectAtIndex:0];
        NSFileManager *fileManger = [NSFileManager defaultManager];
        BOOL isDir;
        if ([fileManger fileExistsAtPath:fileUrl.relativePath isDirectory:&isDir] && !isDir) {
            
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.relativePath error: NULL];
            int64_t result = [attrs fileSize];
            if (result < 10485760) {
                NSString *fileType = @"file";
                if ([[NSImage imageFileTypes] containsObject:[fileUrl pathExtension]]) {
                    fileType = @"image";
                }
                
                PFFile *file = [PFFile fileWithName:[fileUrl lastPathComponent] contentsAtPath:fileUrl.relativePath];
                [self uploadFile:file name:[fileUrl lastPathComponent] type:fileType];
            } else {
                [self updateStatus:@"Sorry, File is too Large (>10M)" isError:YES shouldHide:NO];
            }
            
        } else {
            [self updateStatus:@"Sorry, Directory is Not Allowed" isError:YES shouldHide:NO];
        }
    }
}


- (IBAction)shareTextFromPasteboard:(id)sender {
    NSData* data = [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypeString];
    if (data != nil) {
        NSString *fileName = [NSString stringWithFormat:@"PB%@", @((NSInteger)[[NSDate date] timeIntervalSince1970])];
        PFFile *file = [PFFile fileWithName:fileName data:data];
        [self uploadFile:file name:fileName type:@"file"];
    }
}


#pragma mark - utility

- (void)capture {
    @try {
        
        NSData* dataBefore = [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypePNG];
        
        NSTask* task = [[NSTask alloc] init];
        [task setArguments: [NSArray arrayWithObject: @"-ic"]];
        [task setLaunchPath: @"/usr/sbin/screencapture"];
        [task launch];
        [task waitUntilExit];
        
        NSData* data = [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypePNG];
        if (data && ![data isEqualToData:dataBefore]) {
            NSString *fileName = [NSString stringWithFormat:@"SC%@", @((NSInteger)[[NSDate date] timeIntervalSince1970])];
            PFFile *file = [PFFile fileWithName:fileName data:data];
            [self uploadFile:file name:fileName type:@"image"];
        }
    }
    @catch (NSException *exception) {
        
    }
}


- (BOOL)uploadFile:(PFFile *)file
              name:(NSString *)fileName
              type:(NSString *)fileType{
    
    if (self.isUploading) {
        return NO;
    }
    
    // Upload file first
    self.isUploading = YES;
    [self updateStatus:@"Uploading.." isError:NO shouldHide:NO];

    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            // then save object
            [self updateStatus:@"Saving.." isError:NO shouldHide:NO];

            PFObject *sharedItem = [PFObject objectWithClassName:kParseShareTableName];
            sharedItem[kParseShareTableTitleKey] = fileName;
            sharedItem[kParseShareTableFileKey] = file;
            sharedItem[kParseShareTableTypeKey] = fileType;
            sharedItem[kParseShareTableUserKey] = [PFUser currentUser];
            
            PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
            [acl setPublicReadAccess:YES];
            [sharedItem setACL:acl];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                // convert file url to tiny url
                NSString *urlString = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", [file url]];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                         cachePolicy:NSURLCacheStorageAllowed
                                                     timeoutInterval:5];
                NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:nil
                                                                 error:nil];
                if (data) {
                    NSString *tinyUrlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    sharedItem[kParseShareTableShortUrlKey] = tinyUrlString;
                }
                
                // save sharedItem
                NSError *error = nil;
                BOOL succeeded = [sharedItem save:&error];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (succeeded) {
                        [self updateStatus:@"Done!" isError:NO shouldHide:YES];
                        
                        // update the table view
                        [self.tableView beginUpdates];
                        [self.items insertObject:sharedItem atIndex:0];
                        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                              withAnimation:NSTableViewAnimationSlideDown];
                        [self.tableView endUpdates];
                        
                        // copy link
                        [self copyFileLinkToPasteboard:sharedItem];
                        
                        // send notification
                        NSUserNotification *notification = [[NSUserNotification alloc] init];
                        notification.title = @"Link Copied";
                        notification.informativeText = fileName;
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
                        
                    } else {
                        [self updateStatus:[NSString stringWithFormat:@"Error:%@", error.userInfo]
                                   isError:YES
                                shouldHide:NO];
                    }
                    
                    self.isUploading = NO;
                });
            });
            
        } else {
            [self updateStatus:[NSString stringWithFormat:@"Error:%@", error.userInfo]
                       isError:YES
                    shouldHide:NO];
            self.isUploading = NO;

        }
    } progressBlock:^(int percentDone) {
        [self updateStatus:[NSString stringWithFormat:@"Uploading (%d%%)", percentDone] isError:NO shouldHide:NO];
    }];
    
    self.uploadingFile = file;
    return YES;
}


- (void)cancelUpload {
    [self.uploadingFile cancel];
    self.uploadingFile = nil;
    self.isUploading = NO;
    
    [self updateStatus:@"Cancaled" isError:NO shouldHide:YES];
}


- (void)fetchUserItems {
    PFQuery *query = [PFQuery queryWithClassName:kParseShareTableName];
    [query whereKey:kParseShareTableUserKey equalTo:[PFUser currentUser]];
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
        [self.addButton.animator setFrameCenterRotation:45.0f];
    } else {
        [self.addButton.animator setFrameCenterRotation:0.0f];
    }
}


- (void)updateStatus:(NSString *)string
             isError:(BOOL)isError
          shouldHide:(BOOL)shouldHide {
    
    self.statusLabel.stringValue = string;
    
    // set @"" after 1 second
    if (shouldHide) {
        [[self.statusLabel class] cancelPreviousPerformRequestsWithTarget:self];
        [self.statusLabel performSelector:@selector(setStringValue:)
                               withObject:@""
                               afterDelay:2.0f];
    }
    
    if (isError) {
        // highlight status bar icon
        [[BNGBarItemWindowController sharedController] setStatusItemHighligted:YES];
    }
}


//TODO: not good now
- (NSString *)formattedDataStringFromNSDate:(NSDate *)date {
    static NSString * month[] = {@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"};
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSMinuteCalendarUnit|NSHourCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit
                                               fromDate:date];

    return [NSString stringWithFormat:@"%ld:%ld   %@ %ld", components.hour, components.minute, month[components.month - 1], components.day];
}


- (void)copyFileLinkToPasteboard:(PFObject *)item {
    NSString *fileUrl = item[kParseShareTableShortUrlKey];
    if (fileUrl == nil) {
        PFFile *file = item[kParseShareTableFileKey];
        fileUrl = file.url;
    }
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:self];
    if ([pboard setString:fileUrl forType:NSPasteboardTypeString]) {
        [self updateStatus:@"Copied to pasteboard!" isError:NO shouldHide:YES];
    }
}


#pragma mark - TableView

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    BNGTableCell *cell = [tableView makeViewWithIdentifier:@"BNGTableCell" owner:self];
   
    PFObject *item = [self.items objectAtIndex:row];
    cell.nameLabel.stringValue = item[kParseShareTableTitleKey];
    cell.nameLabel.toolTip = item[kParseShareTableTitleKey];
    cell.timeLabel.stringValue = [self formattedDataStringFromNSDate:item.createdAt];
    if ([item[kParseShareTableTypeKey] isEqualToString:@"image"]) {
        [cell.imageButton setImage:[NSImage imageNamed:@"type-img"]];
    } else {
        [cell.imageButton setImage:[NSImage imageNamed:@"type-file"]];
    }
    

    return cell;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.items.count;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 60.0f;
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
