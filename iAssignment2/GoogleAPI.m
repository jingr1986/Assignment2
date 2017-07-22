//
//  GoogleAPI.m
//  assignment2IPE
//
//  Created by Ryan Jing on 24/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "GTMOAuth2ViewControllerTouch.h"
#import "GoogleAPI.h"

static NSString *const kKeychainItemName = @"Google Calendar";
static NSString *const kClientID = @"925071003691-o1jipm92nd396i10eplfn64uhar1asp1.apps.googleusercontent.com";
static NSString *const kClientSecret = @"I93l8UkuCicHUW97LkhIR2ng";


@implementation GoogleAPI

// When the view loads, create necessary subviews, and initialize the Calendar service.
- (void)viewDidLoad {
    [super viewDidLoad];
}

// When the view appears, ensure that the Calendar service is authorized, and perform API calls.
- (void)viewDidAppear:(BOOL)animated {
//    NSString* val = @"";
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//
//    if (prefs) val = [prefs stringForKey:@"token"];
//    if (val == NULL) {
    [self presentViewController:[self createAuthController] animated:YES completion:nil];
//    }
//    else {
//        [self showAlert:@"Info" message:@"You have already logged in, fetching new events..."];
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    }
}

// Creates the auth controller for authorizing access to Google Calendar.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:@"https://www.googleapis.com/auth/calendar"
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
    }
    else {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:authResult.accessToken forKey: @"token"];
        //NSLog(authResult.accessToken);
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES]; 
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle:title
                                       message:message
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
    [alert show];
}

@end