//
//  StormModelViewController.m
//  Storm
//
//  Created by Jacob Farkas on 6/13/13.
//  Copyright (c) 2013 Jacob Farkas. All rights reserved.
//

#import "StormModelViewController.h"

@import CoreLocation;
@import Social;
@import Accounts;

@interface StormModelViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) CLRegion *wwdcRegion;
@property (nonatomic, strong) CLRegion *beerBashRegion;
@end

@implementation StormModelViewController

- (void)_startMonitoringLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            self.spinner.hidden = YES;
            self.icon.hidden = NO;
            self.statusText.text = @"Monitoring location";
        }];
    });
    
    [self.manager startMonitoringForRegion:self.wwdcRegion];
    [self.manager startMonitoringForRegion:self.beerBashRegion];
}

- (void)_notAuthorizedForLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            self.spinner.hidden = YES;
            self.icon.hidden = NO;
            self.statusText.text = @"Can't determine location";
        }];
    });
}

- (void)_checkLocationAuthorizationAndStartMonitoring {
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        [self _startMonitoringLocation];
    } else {
        [self _notAuthorizedForLocation];
    }
}

- (void)_checkAuthorizationAndStartMonitoring {
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [self _checkLocationAuthorizationAndStartMonitoring];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.25 animations:^{
                    self.spinner.hidden = YES;
                    self.icon.hidden = NO;
                    self.statusText.text = @"You didn't provide access to your Twitter account.";
                }];
            });
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.manager = [CLLocationManager new];
    self.manager.delegate = self;
    
    self.accountStore = [ACAccountStore new];
    
    CLLocationCoordinate2D wwdcLocation = {37.783197,-122.404089};
    self.wwdcRegion = [[CLCircularRegion alloc] initWithCenter:wwdcLocation radius:75.0 identifier:@"WWDC"];
    
    CLLocationCoordinate2D beerBashLocation = {37.784893,-122.402683};
    self.beerBashRegion = [[CLCircularRegion alloc] initWithCenter:beerBashLocation radius:50.0 identifier:@"the WWDC Beer Bash"];
    
    [self _checkAuthorizationAndStartMonitoring];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterType];
    if ([twitterAccounts count]) {
        ACAccount *twitterAccount = [twitterAccounts objectAtIndex:0];
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:
            @{
              @"status" : [NSString stringWithFormat:@"I just STORMED OUT of %@", region.identifier],
              @"lat" : [NSNumber numberWithDouble:self.manager.location.coordinate.latitude],
              @"long" : [NSNumber numberWithDouble:self.manager.location.coordinate.longitude],
              @"display_coordinates" : @"true"}];
        [request setAccount:twitterAccount];
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            // We don't need no stinking error handling
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"The location manager just shit itself: %@", error);
    [self _notAuthorizedForLocation];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Thefuck? Monitoring failed for %@ with error %@", region, error);
    [self _notAuthorizedForLocation];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring started for region %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorized) {
        [self _notAuthorizedForLocation];
    }
}

@end
