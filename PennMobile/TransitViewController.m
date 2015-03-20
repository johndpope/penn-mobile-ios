//
//  TransitViewController.m
//  PennMobile
//
//  Created by Sacha Best on 9/30/14.
//  Copyright (c) 2014 PennLabs. All rights reserved.
//

#import "TransitViewController.h"

@interface TransitViewController ()

@end

@implementation TransitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    if(IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        [locationManager requestWhenInUseAuthorization];
    }
    _mapView.showsUserLocation = YES;
    [_mapView setMapType:MKMapTypeStandard];
    [_mapView setZoomEnabled:YES];
    [_mapView setScrollEnabled:YES];
    _labelEnd.superview.hidden = YES;
    _labelDestination.hidden = YES;
    // Do any additional setup after loading the view.
}
- (void)viewDidAppear:(BOOL)animated {
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    shouldCenter = YES;
    [locationManager startUpdatingLocation];
    [self centerMapOnLocation];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - PennUber API

- (void)queryHandler:(CLLocationCoordinate2D)start destination:(CLLocationCoordinate2D)end {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSDictionary *fromAPI;
        @try {
            fromAPI = [self queryAPI:locationManager.location.coordinate destination:end];
        } @catch (NSException *e) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Route Found" message:@"We couldn't find a route for you using Penn Transit services." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [alert show];
            });
            return;
        }
        [self parseData:fromAPI];
    });
}
-(NSDictionary *)queryAPI:(CLLocationCoordinate2D)start destination:(CLLocationCoordinate2D)end
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@latFrom=%f&latTo=%f&lonFrom=%f&lonTo=%f", SERVER_ROOT, TRANSIT_PATH, start.latitude, start.longitude, end.latitude, end.longitude ]];
    NSData *result = [NSData dataWithContentsOfURL:url];
    if (![self confirmConnection:result]) {
        return nil;
    }
    NSError *error;
    if (!result) {
        //CLS_LOG(@"Data parameter was nil for query..returning null");
        return nil;
    }
    NSDictionary *returned = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableLeaves error:&error];
    if (error || returned[@"Error"]) {
        [NSException raise:@"JSON parse error" format:@"%@", error];
    }
    return returned;
}

- (BOOL)confirmConnection:(NSData *)data {
    if (!data) {
        UIAlertView *new = [[UIAlertView alloc] initWithTitle:@"Couldn't Connect to API" message:@"We couldn't connect to Penn's API. Please try again later. :(" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [new show];
        return false;
    }
    return true;
}

- (void)parseData:(NSDictionary *)fromAPI {
    CLLocationCoordinate2D end, from;
    double endLat, endLon, fromLat, fromLon;
    @try {
        endLat = [(NSString *) (fromAPI[@"toStop"][@"latitude"]) doubleValue];
        endLon = [(NSString *) (fromAPI[@"toStop"][@"longitude"]) doubleValue];
        fromLat = [(NSString *) (fromAPI[@"fromStop"][@"latitude"]) doubleValue];
        fromLon = [(NSString *) (fromAPI[@"fromStop"][@"longitude"]) doubleValue];
    }
    @catch (NSException *exception) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Routing Unavailable." message:@"There was a problem routing to your destination. Please try again. Error: Invalid coordinates from Labs API." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        return;
    }
    end = CLLocationCoordinate2DMake(endLat, endLon);
    from = CLLocationCoordinate2DMake(fromLat, fromLon);
    @try {
        NSArray *busRoute = [self calculateRoutesFrom:from to:end];
        MKPolyline *busLine = [MKPolyline polylineWithCoordinates:(__bridge CLLocationCoordinate2D *)(busRoute) count:busRoute.count];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView addAnnotation:busLine];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self displayRouteUI:fromAPI];
        });
    }
    @catch (NSException *exception) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Routing Unavailable." message:@"There was a problem routing to your destination. Please try again. Error: Invalid route from Google Maps API." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        return;
    }
}

- (void)displayRouteUI:(NSDictionary *)fromAPI {
    _labelDestination.text = ((id<MKAnnotation>)_mapView.selectedAnnotations[0]).title;
    double walkEnd  = [(NSString *) (fromAPI[@"fromStop"][@"walkingDistanceAfter"]) doubleValue];
    double walkStart  = [(NSString *) (fromAPI[@"fromStop"][@"walkingDistanceBefore"]) doubleValue];
    _labelWalkEnd.text = [NSString stringWithFormat:@" then walk %fmi ", walkEnd];
    _labelWalkStart.text = [NSString stringWithFormat:@" then walk %fmi ", walkStart];
    _labelRouteName.text = fromAPI[@"route"];
    _labelStart.text = fromAPI[@"fromStop"][@"BusStopName"];
    _labelEnd.text = fromAPI[@"toStop"][@"BusStopName"];
    _labelEnd.superview.hidden = NO;
}

#pragma mark - Google Maps Polyline Finder

// taken from https://github.com/kadirpekel/MapWithRoutes/blob/master/Classes/MapView.m
// LOL
-(NSArray*) calculateRoutesFrom:(CLLocationCoordinate2D) f to: (CLLocationCoordinate2D) t {
    NSString* saddr = [NSString stringWithFormat:@"%f,%f", f.latitude, f.longitude];
    NSString* daddr = [NSString stringWithFormat:@"%f,%f", t.latitude, t.longitude];
    
    NSString* apiUrlStr = [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@", saddr, daddr];
    NSURL* apiUrl = [NSURL URLWithString:apiUrlStr];
    NSLog(@"api url: %@", apiUrl);
    NSError *error;
    NSString *apiResponse = [NSString stringWithContentsOfURL:apiUrl encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [NSException raise:@"Error in point parsing." format:@""];
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"points:\\\"([^\\\"]*)\\\"" options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:apiResponse options:0 range:NSMakeRange(0, [apiResponse length])];
    NSString *encodedPoints = [apiResponse substringWithRange:[match rangeAtIndex:1]];
    return [self decodePolyLine:[encodedPoints mutableCopy]];
}

// taken from https://github.com/kadirpekel/MapWithRoutes/blob/master/Classes/MapView.m
// LOL
-(NSMutableArray *)decodePolyLine:(NSMutableString *)encoded {
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    while (index < len) {
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        printf("[%f,", [latitude doubleValue]);
        printf("%f]", [longitude doubleValue]);
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:loc];
    }
    return array;
}

#pragma mark - Searching and Plotting

- (void)plotResults {
    [_mapView removeAnnotations:_mapView.annotations];
    MKPointAnnotation *temp;
    if (results.count > 0) {
        for (long i = results.count - 1; i >= 0; i--) {
            temp = [[MKPointAnnotation alloc] init];
            temp.coordinate = ((MKMapItem *) results[i]).placemark.coordinate;
            temp.title = ((MKMapItem *) results[i]).name;
            // these values were originally store in a local hashmap but wasn't worth it
            [_mapView addAnnotation:temp];
        }
        [_mapView selectAnnotation:temp animated:YES];
    }
    
}

/**
 * The majority of this code is from Apple's samples. Just a heads up
 **/
- (void)search:(NSString *)query {
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = locationManager.location.coordinate.latitude;
    newRegion.center.longitude = locationManager.location.coordinate.longitude;
    
    // setup the area spanned by the map region:
    // we use the delta values to indicate the desired zoom level of the map,
    //      (smaller delta values corresponding to a higher zoom level)
    //
    newRegion.span.latitudeDelta = 0.112872;
    newRegion.span.longitudeDelta = 0.109863;
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    
    request.naturalLanguageQuery = query;
    request.region = newRegion;
    
    MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error) {
        if (error != nil) {
            NSString *errorStr = [[error userInfo] valueForKey:NSLocalizedDescriptionKey];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not find any results."
                                                            message:errorStr
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else {
            results = [response mapItems];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self plotResults];
            // used for later when setting the map's region in "prepareForSegue"
            _boundingRegion = response.boundingRegion;
        }
        //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    };
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    [_searchBar resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [localSearch startWithCompletionHandler:completionHandler];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotation.title];
    if (!annotationView && ![annotation isKindOfClass:[MKUserLocation class] ]) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotation.title];
    }
    if ([annotationView isKindOfClass:[MKPinAnnotationView class]]) {
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    CLLocationCoordinate2D dest = view.annotation.coordinate;
    [self queryHandler:locationManager.location.coordinate destination:dest];
}
#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self search:searchBar.text];
    shouldCenter = NO;
}

#pragma mark - CLLocationManager

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (shouldCenter) {
        //[self centerMapOnLocation];
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }
}

- (void)centerMapOnLocation {
    //View Area
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = locationManager.location.coordinate.latitude;
    region.center.longitude = locationManager.location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [_mapView setRegion:region animated:YES];
}

#pragma mark - Navigation
/**
 * This fragment is repeated across the app, still don't know the best way to refactor
 **/
- (IBAction)menuButton:(id)sender {
    if ([SlideOutMenuViewController instance].menuOut) {
        // this is a workaround as the normal returnToView selector causes a fault
        // the memory for hte instance is locked unless the view controller is passed in a segue
        // this is for security reasons.
        [[SlideOutMenuViewController instance] performSegueWithIdentifier:@"Transit" sender:self];
    } else {
        [self performSegueWithIdentifier:@"menu" sender:self];
    }
}
- (void)handleRollBack:(UIStoryboardSegue *)segue {
    if ([segue.destinationViewController isKindOfClass:[SlideOutMenuViewController class]]) {
        SlideOutMenuViewController *menu = segue.destinationViewController;
        cancelTouches = [[UITapGestureRecognizer alloc] initWithTarget:menu action:@selector(returnToView:)];
        cancelTouches.cancelsTouchesInView = YES;
        cancelTouches.numberOfTapsRequired = 1;
        cancelTouches.numberOfTouchesRequired = 1;
        if (self.view.gestureRecognizers.count > 0) {
            // there is a keybaord dismiss tap recognizer present
            // ((UIGestureRecognizer *) view.gestureRecognizers[0]).enabled = NO;
        }
        float width = [[UIScreen mainScreen] bounds].size.width;
        float height = [[UIScreen mainScreen] bounds].size.height;
        UIView *grayCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        [grayCover setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
        [grayCover addGestureRecognizer:cancelTouches];
        [UIView transitionWithView:self.view duration:1
                           options:UIViewAnimationOptionShowHideTransitionViews
                        animations:^ { [self.view addSubview:grayCover]; }
                        completion:nil];
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    [self handleRollBack:segue];
}


@end
