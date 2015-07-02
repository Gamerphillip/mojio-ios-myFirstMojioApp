//
//  MFMUser.m
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-01.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import "MyFirstMojioAppManager.h"
#import "MojioClient.h"
#import "Mojio.h"
#import "Vehicle.h"
#import "User.h"

@interface MyFirstMojioAppManager(){

}

@property (nonatomic, strong) NSString *defaultVehicleId;
@property (nonatomic, strong) Vehicle *defaultVehicle;
@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) NSArray *allVehicleIds;
@property (nonatomic, strong) NSArray *allMojios;
@property (nonatomic, strong) NSArray *trips;

@end

@implementation MyFirstMojioAppManager

@synthesize userId = _userId, defaultVehicleId = _defaultVehicleId, numOfTrips = _numOfTrips;

+(MyFirstMojioAppManager *)instance
{
    static MyFirstMojioAppManager *_instance;
    static dispatch_once_t onceToken;
    
    if (!_instance) {
        dispatch_once(&onceToken, ^{
            _instance = [[MyFirstMojioAppManager alloc] init];
        });
    }
    return _instance;
    
}

-(NSString *)userId
{
    if (!_userId) {
        _userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserId"];
    }
    return _userId;
}

- (void)setUserId:(NSString *)userId
{
    _userId = userId;
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"UserId"];
}

-(NSString *)defaultVehicleId
{
    if (!_defaultVehicleId) {
        _defaultVehicleId = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultVehicleId"];
    }
    return _defaultVehicleId;
}

-(void)setDefaultVehicleId:(NSString *)defaultVehicleId
{
    _defaultVehicleId = defaultVehicleId;
    [[NSUserDefaults standardUserDefaults] setObject:defaultVehicleId forKey:@"DefaultVehicleId"];
}

-(NSInteger)numOfTrips
{
    if (!_trips) return 0;
    return _trips.count;
}

-(void) setMojios:(NSArray *)mojios withCompletionBlock:(completionBlockWithoutData)completion {
    NSMutableArray *allVehiclesId = [NSMutableArray array];
    
    for (NSInteger i = 0; i<[mojios count]; i++) {
        Mojio *mojio = [mojios objectAtIndex:i];
        NSString *vehicleId = [mojio VehicleId];
        if (vehicleId) {
            [allVehiclesId addObject:vehicleId];
        }
        
        if (!self.defaultVehicleId) {
            self.defaultVehicleId = vehicleId;
        }
        if (i == mojios.count - 1 ) {
            _allVehicleIds = allVehiclesId;
            _allMojios = mojios;
            
            if (completion) {
                completion();
            }
            
        }
    }
    
}

/**
 *  Prepare user info
 *  Note: UserId is a dependency for fetch Mojios while do OAuth2 login
 *
 *  @param completion completion block to do following action that depend on this. etc. fetch Mojios
 */
-(void)prepareUserInfo:(completionBlockWithoutData)completion
{
    if (!self.userId || [self.userId isEqualToString:@""]) {
        [[MojioClient client] getEntityWithPath:@"Users/Me" withQueryOptions:nil success:^(id responseObject) {
            //
            User *user = (User *)responseObject;
            self.userId = user._id;
            if (completion) completion();
        } failure:^(NSError *error) {
            //
            NSLog(@"Unable to load user info");
        }];
        return;
    }
    if (completion) completion();
}


-(void)fetchMojiosWithCompletionBlock:(completionBlockWithData)completion
{
    //UserId is required prior to retrieve Mojios for User
    [self prepareUserInfo:^{

        if (!self.allMojios) {
            [[MojioClient client] getEntityWithPath:[NSString stringWithFormat:@"Users/%@/Mojios", self.userId] withQueryOptions:nil success:^(id responseObject) {
                NSArray *mojios = (NSArray *)responseObject;
                
                [self setMojios:mojios withCompletionBlock:nil];
                
                if (completion)
                    completion(mojios);

            } failure:^(NSError *error) {
                NSLog(@"Could not download mojios");
            }];
        }
        else {
            if (completion)
                completion(self.allMojios);
        }
    }];
}

- (void)fetchTripsWithCompletionBlock:(completionBlockWithData)completion
{
    [[MojioClient client] getEntityWithPath:@"Trips" withQueryOptions:nil success:^(id responseObject) {
        
        _trips = responseObject;
        
        if (completion)
            completion(responseObject);
        
    } failure:^(NSError *error) {
        NSLog(@"Could not fetch trips");
    }];
}

-(void) downloadDefaultVehicleDataWithCompletionBlock : (completionBlockWithoutData)completion {
    
    if (!self.defaultVehicleId) {

        NSLog(@"There is no default vehicle at the moment");
        if (completion) {
            completion();
        }
        return;
    }
    
    [[MojioClient client] getEntityWithPath:[NSString stringWithFormat:@"Vehicles/%@", self.defaultVehicleId] withQueryOptions:nil success:^(id responseObject) {
        Vehicle *vehicle = (Vehicle *) responseObject;
        _defaultVehicle = vehicle;
        if (completion) {
            completion();
        }
        
    }failure:^(NSError *error) {
        if (completion) {
            completion();
        }
    }];
}


@end
