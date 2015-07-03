//
//  MFMUser.h
//  myFirstMojioApp
//
//  Created by Ye Ma on 2015-07-01.
//  Copyright (c) 2015 Ye Ma. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Vehicle;

typedef void(^completionBlockWithData)(NSArray *);
typedef void(^completionBlockWithoutData)(void);

@interface MyFirstMojioAppManager : NSObject

@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *defaultVehicleId;
@property (nonatomic, readonly) Vehicle *defaultVehicle;
@property (nonatomic, assign, readonly) NSInteger numOfTrips;
@property (nonatomic, readonly) NSArray *trips;
//@property (nonatomic, readonly) NSArray *vehicles;

+(MyFirstMojioAppManager *)instance;
-(void)fetchMojiosWithCompletionBlock:(completionBlockWithData)completion;
-(void)fetchTripsWithCompletionBlock:(completionBlockWithData)completion;
-(void)downloadDefaultVehicleDataWithCompletionBlock : (completionBlockWithoutData)completion;
@end
