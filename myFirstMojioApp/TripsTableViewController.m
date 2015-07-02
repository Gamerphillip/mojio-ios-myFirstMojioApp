//
//  TripTableViewController.m
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-02.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import "TripsTableViewController.h"
#import "TripTableViewCell.h"
#import "MyFirstMojioAppManager.h"

@interface TripsTableViewController ()

@end

@implementation TripsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //fetch user's trips log and refresh the tableview upon response
    [[MyFirstMojioAppManager instance] fetchTripsWithCompletionBlock:^(NSArray *trips) {
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [[MyFirstMojioAppManager instance] numOfTrips] > 0? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[MyFirstMojioAppManager instance] numOfTrips];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TripTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tripcell" forIndexPath:indexPath];
    
    // Configurate Trip cell, customize UI base on the data, geocoding is required if want to show details like address
    cell.txtView.text = [NSString stringWithFormat:@"Trip %ld", (long)indexPath.row];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
