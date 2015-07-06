# mojio-ios-myFirstMojioApp

UNDER ACTIVE DEVELOPMENT
These instructions assume the usage of xcode 6.0+ and Podfile package manager

This project shows how to use the Mojio SDK to perform simple OAuth2 authentication to gain access to the Mojio Platform's core data, and demonstrated how to list user's trip and observe user's vehicle on map.

If you wish to download the full SDK source, please see [Visit our GitHub repo](https://github.com/mojio/mojio-ios-sdk).

###Mojio iOS SDK dependency###
1. AFNetworking, version > 2.5
2. JSONModel, "1.0.2"

###Running this project###
1. Fork / clone this repo
2. Open up AppDelegate.m and add your application's MOJIO_APP_ID and REDIRECT_URL.
3. Build the project and run on a device!

###How OAuth2 is done in this application ###
1. Your application need to include MojioClient.h where you need access Mojio SDK

2. In AppDelegate.m, add below code in "- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions" to initialize Mojio iOS SDK.
    MojioClient *mojioClient = [MojioClient client];
    [mojioClient initWithAppId:MOJIO_APP_ID andSecretKey:nil andRedirectUrlScheme:REDIRECT_URL];

3. In AppDelegate.m add below code in "-(BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url", this is to handle post-OAuth2 authentication callback.
    [[MojioClient client] handleOpenURL:url];

4. In your UIViewController, add a UIButton assume it would execute the login upon click, and add below code in response of the event:
    [[MojioClient client] loginWithCompletionBlock:^{
        //Post-OAuth2 authentication callback, etc. refresh login status.
    }];

###How to load user's trips###
Fetch user's trips by calling below code:
    [[MojioClient client] getEntityWithPath:@"Trips" withQueryOptions:@{@"limit" : @10, @"desc" : @YES} success:^(id responseObject) {
		//Array of Trip objects.        
        NSArray *trips = responseObject;
        
    } failure:^(NSError *error) {
        NSLog(@"Could not fetch trips");
    }];

###How to observe a vehicle on map###
1. Obtain userId by calling below code, userId is required for get user's Mojios
        [[MojioClient client] getEntityWithPath:@"Users/Me" withQueryOptions:nil success:^(id responseObject) {
            User *user = (User *)responseObject;
            self.userId = user._id;
        } failure:^(NSError *error) {
            NSLog(@"Unable to load user info");
        }];

2. Obtain user's Mojios by calling below method:
            [[MojioClient client] getEntityWithPath:[NSString stringWithFormat:@"Users/%@/Mojios", self.userId] withQueryOptions:nil success:^(id responseObject) {
                NSArray *mojios = (NSArray *)responseObject;
                //Process mojios to obtain user's default Vehicle Id
            } failure:^(NSError *error) {
                NSLog(@"Could not download mojios");
            }];


3. Obtain user's default Vehicle data which contains etc. vehcile's deo location data dn when it was last updated etc.
    [[MojioClient client] getEntityWithPath:[NSString stringWithFormat:@"Vehicles/%@", self.defaultVehicleId] withQueryOptions:nil success:^(id responseObject) {
        Vehicle *vehicle = (Vehicle *) responseObject;
        _defaultVehicle = vehicle;
    }failure:^(NSError *error) {
    	//NSLog(@"failed to download user's vehicle data");
    }];

4. Set up a observer on default vehicle to obtain real-time trip events
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

 5. Implement MojioClient delegate methods to receive and process real-time events
	
	#pragma mark - MojioClient Delegate methods
	-(void) receivedMessageFromMojio : (id) message
	{
		//Refer to Mojio iOS SDK documentation for message format.
	}

6. Last to remove observer by using observerId when exit the screen.

    if (self.vehicleObserverId) {
        [[MojioClient client] deleteObserverWithId:self.vehicleObserverId withCompletionBlock:^{
            self.vehicleObserverId = nil;
        } withFailure:^{
            NSLog(@"failed to remove observer");
        }];
    }
