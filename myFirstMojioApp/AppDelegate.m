//
//  AppDelegate.m
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-01.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import "AppDelegate.h"
#import "MojioClient.h"
#import "MyFirstMojioAppManager.h"

NSString *const MOJIO_APP_ID = @"<YOUR_APP_ID>";
NSString *const REDIRECT_URL = @"<YOUR_APP_REDIRECT>://";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    MojioClient *mojioClient = [MojioClient client];
    [mojioClient initWithAppId:MOJIO_APP_ID andSecretKey:nil andRedirectUrlScheme:REDIRECT_URL]; //sandbox key

    //whether it should launch login window
    if ([[MojioClient client] isUserLoggedIn]) {
        [[MyFirstMojioAppManager instance] fetchMojiosWithCompletionBlock:nil];
        
        UIViewController *tripsViewController = [[UIStoryboard storyboardWithName:@"Trips" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"TripsViewController"];
        self.window.rootViewController = tripsViewController;
    }
    else {
        
        self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"LoginViewController"];
    }

    return YES;
}

-(BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    //Note: iOS SDK handle URL and trigger callback block defined while initiate the OAuth2 login process
    [[MojioClient client] handleOpenURL:url];
    return YES;
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
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
