//
//  BNGLoginViewController.m
//  Bang
//
//  Created by Jesse on 14-3-25.
//  Copyright (c) 2014年 Taobao. All rights reserved.
//

#import "BNGLoginViewController.h"
#import "BNGBarItemWindowController.h"

@interface BNGLoginViewController ()

@property (weak) IBOutlet NSTextField *emailTextField;
@property (weak) IBOutlet NSTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *statusLabel;

@end

@implementation BNGLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (IBAction)registerAction:(id)sender {
    
    NSString *username = self.emailTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.stringValue = username.length == 0 ? @"Invalid Email" : @"Invalid passowrd";
        return;
    }
    
    PFUser *user = [PFUser user];
    user.username = username;
    user.password = password;
    
    self.statusLabel.stringValue = @"...";
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Register OK!");
            self.statusLabel.stringValue = @"";

            [[BNGBarItemWindowController sharedController] changeToMainViewController];
            
        } else {
            
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"errorString %@", errorString);
            
            self.statusLabel.stringValue = errorString;
        }
    }];
}


- (IBAction)loginAction:(id)sender {
    NSString *username = self.emailTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.stringValue = username.length == 0 ? @"Invalid Email" : @"Invalid passowrd";
        return;
    }
    
    self.statusLabel.stringValue = @"Login...";
    
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        if (!error) {
            NSLog(@"Login OK!");
            self.statusLabel.stringValue = @"";

            [[BNGBarItemWindowController sharedController] changeToMainViewController];
        } else {
            
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"errorString %@", errorString);
            
            self.statusLabel.stringValue = errorString;
        }
    }];
}


#pragma mark -



@end
