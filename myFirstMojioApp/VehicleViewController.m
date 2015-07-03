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
#import "CrumbPath.h"
#import "CrumbPathRenderer.h"

@interface VehicleViewController ()<MKMapViewDelegate, MojioClientDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *vehicleAnnotation;
@property (nonatomic, strong) NSString *vehicleObserverId;
@property (nonatomic, strong) MojioClient *mojioClient;

@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathRenderer *crumbPathRenderer;

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
    MKCoordinateRegion region = [self coordinateRegionWithCenter:vehicleLocationCoord approximateRadiusInMeters:2500];
    [self.mapView setRegion:region animated:YES];

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

- (MKCoordinateRegion)coordinateRegionWithCenter:(CLLocationCoordinate2D)centerCoordinate approximateRadiusInMeters:(CLLocationDistance)radiusInMeters
{
    // Multiplying by MKMapPointsPerMeterAtLatitude at the center is only approximate, since latitude isn't fixed
    //
    double radiusInMapPoints = radiusInMeters*MKMapPointsPerMeterAtLatitude(centerCoordinate.latitude);
    MKMapSize radiusSquared = {radiusInMapPoints,radiusInMapPoints};
    
    MKMapPoint regionOrigin = MKMapPointForCoordinate(centerCoordinate);
    MKMapRect regionRect = (MKMapRect){regionOrigin, radiusSquared}; //origin is the top-left corner
    
    regionRect = MKMapRectOffset(regionRect, -radiusInMapPoints/2, -radiusInMapPoints/2);
    
    // clamp the rect to be within the world
    regionRect = MKMapRectIntersection(regionRect, MKMapRectWorld);
    
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(regionRect);
    return region;
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
            
            // we are not using deferred location updates, so always use the latest location
            CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            
            if (self.crumbs == nil)
            {
                // This is the first time we're getting a location update, so create
                // the CrumbPath and add it to the map.
                //
                _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
                [self.mapView addOverlay:self.crumbs level:MKOverlayLevelAboveRoads];
                
                // on the first location update only, zoom map to user location
//                CLLocationCoordinate2D newCoordinate = newLocation.coordinate;
                
                // default -boundingMapRect size is 1km^2 centered on coord
//                MKCoordinateRegion region = [self coordinateRegionWithCenter:newCoordinate approximateRadiusInMeters:2500];
//                
//                [self.mapView setRegion:region animated:YES];
            }
            else
            {
                // This is a subsequent location update.
                //
                // If the crumbs MKOverlay model object determines that the current location has moved
                // far enough from the previous location, use the returned updateRect to redraw just
                // the changed area.
                //
                // note: cell-based devices will locate you using the triangulation of the cell towers.
                // so you may experience spikes in location data (in small time intervals)
                // due to cell tower triangulation.
                //
                BOOL boundingMapRectChanged = NO;
                MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate boundingMapRectChanged:&boundingMapRectChanged];
                if (boundingMapRectChanged)
                {
                    // MKMapView expects an overlay's boundingMapRect to never change (it's a readonly @property).
                    // So for the MapView to recognize the overlay's size has changed, we remove it, then add it again.
                    [self.mapView removeOverlays:self.mapView.overlays];
                    _crumbPathRenderer = nil;
                    [self.mapView addOverlay:self.crumbs level:MKOverlayLevelAboveRoads];
                    
                    MKMapRect r = self.crumbs.boundingMapRect;
                    MKMapPoint pts[] = {
                        MKMapPointMake(MKMapRectGetMinX(r), MKMapRectGetMinY(r)),
                        MKMapPointMake(MKMapRectGetMinX(r), MKMapRectGetMaxY(r)),
                        MKMapPointMake(MKMapRectGetMaxX(r), MKMapRectGetMaxY(r)),
                        MKMapPointMake(MKMapRectGetMaxX(r), MKMapRectGetMinY(r)),
                    };
                    NSUInteger count = sizeof(pts) / sizeof(pts[0]);
                    MKPolygon *boundingMapRectOverlay = [MKPolygon polygonWithPoints:pts count:count];
                    [self.mapView addOverlay:boundingMapRectOverlay level:MKOverlayLevelAboveRoads];
                }
                else if (!MKMapRectIsNull(updateRect))
                {
                    // There is a non null update rect.
                    // Compute the currently visible map zoom scale
                    MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
                    // Find out the line width at this zoom scale and outset the updateRect by that amount
                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                    // Ask the overlay view to update just the changed area.
                    [self.crumbPathRenderer setNeedsDisplayInMapRect:updateRect];
                }
            }
            
        }
    }
    
}

#pragma mark - MapKit

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    MKOverlayRenderer *renderer = nil;
    
    if ([overlay isKindOfClass:[CrumbPath class]])
    {
        if (self.crumbPathRenderer == nil)
        {
            _crumbPathRenderer = [[CrumbPathRenderer alloc] initWithOverlay:overlay];
        }
        renderer = self.crumbPathRenderer;
    }
    
    return renderer;
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
