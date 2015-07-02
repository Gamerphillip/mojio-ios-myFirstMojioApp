//
//  LoginViewController.m
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-02.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import "LoginViewController.h"
#import "MojioClient.h"
#import "MyFirstMojioAppManager.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self updateLoginButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLoginButton
{
    [self.loginButton setTitle:[[MojioClient client] isUserLoggedIn]? @"Logout" : @"Login" forState:UIControlStateNormal];
}

- (IBAction)onLogin:(id)sender {
    
    if ([[MojioClient client] isUserLoggedIn]) {
        [[MojioClient client] logoutWithCompletionBlock:^{
            [self updateLoginButton];
        }];
    }
    else {
        [[MojioClient client] loginWithCompletionBlock:^{
            
            if ([[MojioClient client] isUserLoggedIn]) {
                [[MyFirstMojioAppManager instance] fetchMojiosWithCompletionBlock:nil];
                id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
                
                UIViewController *tripsViewController = [[UIStoryboard storyboardWithName:@"Trips" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"TripsViewController"];
                delegate.window.rootViewController = tripsViewController;
            }
        }];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
