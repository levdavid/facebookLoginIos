//
//  ViewController.m
//  blentest
//
//  Created by Libraries on 9/26/14.
//  Copyright (c) 2014 blen.corp. All rights reserved.
//

#import "ViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>

// The Firebase you want to use for this app
// You must setup Simple Login for the various authentication providers in Forge
static NSString * const kFirebaseURL = @"https://<your-firebase>.firebaseio.com";

// The app ID you setup in the facebook developer console
static NSString * const kFacebookAppID = @"1506150202964831";




@interface ViewController ()

@property (nonatomic, strong) IBOutlet UIButton *facebookLoginButton;
@property (strong, nonatomic) IBOutlet UIButton *anonymousLoginButton;
@property (nonatomic, strong) IBOutlet UILabel *loginStatusLabel;
@property (nonatomic, strong) IBOutlet UIButton *logoutButton;



// A dialog that is displayed while logging in
@property (nonatomic, strong) UIAlertView *loginProgressAlert;

// The simpleLogin object that is used to authenticate against Firebase
@property (nonatomic, strong) FirebaseSimpleLogin *simpleLogin;


// The user currently authenticed with Firebase
@property (nonatomic, strong) FAUser *currentUser;



@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    
    self.loginStatusLabel.hidden = YES;
    self.loginStatusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.loginStatusLabel.numberOfLines = 0;
    self.logoutButton.hidden = YES;
    // map buttons to methods
    [self.facebookLoginButton addTarget:self
                                 action:@selector(facebookButtonPressed)
                       forControlEvents:UIControlEventTouchUpInside];
	// Do any additional setup after loading the view, typically from a nib.
    
    // create the simple login instance
    Firebase *firebase = [[Firebase alloc] initWithUrl:kFirebaseURL];
    self.simpleLogin = [[FirebaseSimpleLogin alloc] initWithRef:firebase];
}


- (void)updateUIAndSetCurrentUser:(FAUser *)currentUser
{
    // set the user
    self.currentUser = currentUser;
    if (currentUser == nil) {
        // The is no user authenticated, so show the login buttons and hide the logout button
        self.loginStatusLabel.hidden = YES;
        self.logoutButton.hidden = YES;
        self.facebookLoginButton.hidden = NO;
        self.anonymousLoginButton.hidden = NO;
    } else {
        // update the status label to show which user is logged in using which provider
        NSString *statusText;
        switch (currentUser.provider) {
            case FAProviderFacebook:
                statusText = [NSString stringWithFormat:@"Logged in as %@ (Facebook)",
                              currentUser.thirdPartyUserData[@"name"]];
                break;
            case FAProviderAnonymous:
                statusText = @"Logged in anonymously";
                break;
            default:
                statusText = [NSString stringWithFormat:@"Logged in with unknown provider"];
                break;
        }
        self.loginStatusLabel.text = statusText;
        self.loginStatusLabel.hidden = NO;
        // show the logout button
        self.logoutButton.hidden = NO;
        // hide the login button for now
        self.facebookLoginButton.hidden = YES;
        self.anonymousLoginButton.hidden = YES;
    }
}

- (void)logoutButtonPressed
{
    // logout of Firebase and set the current user to nil
    [self.simpleLogin logout];
    [self updateUIAndSetCurrentUser:nil];
}

- (void)showProgressAlert
{
    // show an alert notifying the user about logging in
    self.loginProgressAlert = [[UIAlertView alloc] initWithTitle:nil
                                                         message:@"Logging in..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [self.loginProgressAlert show];
}

- (void)showErrorAlertWithMessage:(NSString *)message
{
    // display an alert with the error message
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void(^)(NSError *, FAUser *))loginBlockForProviderName:(NSString *)providerName
{
    // this callback block can be used for every login method
    return ^(NSError *error, FAUser *user) {
        // make sure we are on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            // hide the login progress dialog
            [self.loginProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            self.loginProgressAlert = nil;
            if (error != nil) {
                // there was an error authenticating with Firebase
                NSLog(@"Error logging in to Firebase: %@", error);
                // display an alert showing the error message
                NSString *message = [NSString stringWithFormat:@"There was an error logging into Firebase using %@: %@",
                                     providerName,
                                     [error localizedDescription]];
                [self showErrorAlertWithMessage:message];
            } else {
                // all is fine, set the current user and update UI
                [self updateUIAndSetCurrentUser:user];
            }
        });
    };
}

/*****************************
 *          FACEBOOK         *
 *****************************/
- (void)facebookButtonPressed
{
    [self showProgressAlert];
    // login using Facebook
    [self.simpleLogin loginToFacebookAppWithId:kFacebookAppID
                                   permissions:@[@"email"]
                                      audience:ACFacebookAudienceOnlyMe
                           withCompletionBlock:[self loginBlockForProviderName:@"Facebook"]];
}

/*****************************
 *         ANONYMOUS         *
 *****************************/
- (void)anonymousButtonPressed
{
    [self showProgressAlert];
    [self.simpleLogin loginAnonymouslywithCompletionBlock:[self loginBlockForProviderName:@"Anonymous"]];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user
{
    NSLog(@"%@", user.name);
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    NSLog(@"You are logged in!:)");
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    NSLog(@"You are logged out! :( ");
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    NSString *alertMessage, *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error])
    {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
    }
    else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession)
    {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
    }
    else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled)
    {
        NSLog(@"user cancelled login");
        
    }
    else
    {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage)
    {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}
*/

@end
