//
//  VehicleViewController.m
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-02.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import "VehicleViewController.h"
#import <MapKit/MapKit.h>
#import "MyFirstMojioAppManager.h"
#import "Vehicle.h"
#import "Observer.h"
#import "MojioClient.h"

@interface VehicleViewController ()<MKMapViewDelegate, MojioClientDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *vehicleAnnotation;
@property (nonatomic, strong) NSString *vehicleObserverId;
@property (nonatomic, strong) MojioClient *mojioClient;

@end

@implementation VehicleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mapView.delegate = self;
    self.mojioClient = [MojioClient client];
    self.mojioClient.mojioClientDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[MyFirstMojioAppManager instance] downloadDefaultVehicleDataWithCompletionBlock:^{
        //draw vehicle on map
        [self drawVehicleOnMap:nil];
        [self setupVehicleObserver];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.vehicleObserverId) {
        [[MojioClient client] deleteObserverWithId:self.vehicleObserverId withCompletionBlock:^{
            self.vehicleObserverId = nil;
        } withFailure:^{
            NSLog(@"failed to remove observer");
        }];
    }
}

/**
 *  Draw user's default Vehcile on map base on it's last location
 *  Note: it would remove existing annotations from map before add new one.
 *
 *  @param lastLocation Location object
 */
-(void)drawVehicleOnMap:(Location *)lastLocation
{
    Vehicle *vehicle = [MyFirstMojioAppManager instance].defaultVehicle;
    if (!lastLocation) lastLocation = vehicle.LastLocation;
    
    CLLocationCoordinate2D vehicleLocationCoord = CLLocationCoordinate2DMake(lastLocation.Lat, lastLocation.Lng);
    
    if (vehicleLocationCoord.latitude == 0 && vehicleLocationCoord.longitude == 0) {
        return;
    }
    
    // Set the region of the map
    MKCoordinateSpan mapViewSpan = MKCoordinateSpanMake(0.1, 0.1);
    MKCoordinateRegion mapRegion = MKCoordinateRegionMake(vehicleLocationCoord, mapViewSpan);

    [self.mapView setRegion:mapRegion];
    
    // Remove existing annotations before drawing the new vehicle pin
    
    [self.mapView removeAnnotations:[self.mapView annotations]];
    // Add annotation to the map
    self.vehicleAnnotation = [[MKPointAnnotation alloc] init];
    [self.vehicleAnnotation setCoordinate:vehicleLocationCoord];
    [self.vehicleAnnotation setTitle:vehicle.Name];
    
    [self.mapView addAnnotation:self.vehicleAnnotation];
}

/**
 *  Setup Vehicle Observer, to be removed when finish using it while exit.
 */
-(void) setupVehicleObserver {
    Vehicle *vehicle = [MyFirstMojioAppManager instance].defaultVehicle;

    Observer *vehicleObserver = [[Observer alloc] init];
    [vehicleObserver setName:@"Vehicle Observer"];
    [vehicleObserver setSubject:@"Vehicle"];
    [vehicleObserver setSubjectId:vehicle._id];
    [vehicleObserver setTransports:@"SignalR"];
    
    id vehicleJson = [vehicleObserver toJSONString];
    [[MojioClient client] createObserverWithBody:vehicleJson withCompletionBlock:^(id responseObject) {
        Observer *observer = (Observer *) responseObject;
        self.vehicleObserverId = [observer _id];
        [[MojioClient client] subscribeToObserverWithId:self.vehicleObserverId withCompletionBlock:nil];
        
    }withFailure:^{
        // do something
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MojioClient Delegate methods
-(void) receivedMessageFromMojio : (id) message
{
    if ([message isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)message;
        NSDictionary *dicLoc = (NSDictionary *)[dic valueForKey:@"LastLocation"];
        if (dicLoc) {
            double lat = [[dicLoc valueForKey:@"Lat"] doubleValue];
            double lon = [[dicLoc valueForKey:@"Lng"] doubleValue];
            [self drawVehicleOnMap:[[Location alloc] initWithLat:lat andLongitude:lon]];
        }
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
