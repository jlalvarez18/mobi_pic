//
//  AppDelegate.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "AppDelegate.h"

#import <Dropbox/Dropbox.h>

#import "AuthViewController.h"

@interface AppDelegate ()

@property (nonatomic, readonly) AuthViewController *authController;

@end

@implementation AppDelegate

@synthesize authController = _authController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupDropboxManager];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        [self processDropboxAccount:account];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        });
        
        return YES;
    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    // if there is no linked account, present the auth controller
    if (!account) {
        UIViewController *rootController = self.window.rootViewController;
        
        [rootController presentViewController:self.authController animated:YES completion:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark Setup Methods

- (void)setupDropboxManager
{
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"1dvjlswwbr64rx0" secret:@"u4i7ermhrn0fczi"];
    [DBAccountManager setSharedManager:accountManager];
    
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    [self processDropboxAccount:account];
}

- (void)processDropboxAccount:(DBAccount *)account
{
    if (account) {
        DBFilesystem *fileSystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:fileSystem];
    }
}

#pragma mark -
#pragma mark Accessor Methods

- (AuthViewController *)authController
{
    if (_authController) {
        return _authController;
    }
    
    _authController = [[AuthViewController alloc] init];
    
    return _authController;
}

@end
