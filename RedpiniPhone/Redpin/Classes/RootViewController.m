//
//  RootViewController.m
//  Redpin
/**  This file is part of the Redpin project.
 * 
 *  Redpin is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  Redpin is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with Redpin. If not, see <http://www.gnu.org/licenses/>.
 *
 * © Copyright ETH Zurich, Luba Rogoleva, Pascal Brogle, Philipp Bolliger, 2010, ALL RIGHTS RESERVED.
 * 
 *  www.redpin.org
 */


#import "RootViewController.h"
#import "MapListTableViewController.h"
#import "EntityHome.h"
#import "Map.h"
#import "MapHome.h"
#import "Location.h"
#import "LocationHome.h"
#import "LocationMarker.h"
#import "Fingerprint.h"
#import "FingerprintHome.h"
#import "Measurement.h"
#import "MeasurementHome.h"
#import "WifiReading.h"
#import "WifiReadingHome.h"
#import "ServerResponse.h"
#import "ServerRequest.h"
#import "StateSaveManager.h"
#import "Sniffer.h"
#import "InternetConnectionManager.h"
#import "RedpinAppDelegate.h"
#import "ActivityIndicator.h"

@interface RootViewController()

- (void) setInternetMode;
- (void) internetConnectionChanged:(NSNotification *) note;
- (void) showPortrait;
- (void) showLandscape;
- (Fingerprint *) buildPosition:(Measurement *) m;
- (void) notifyStopIntervalScan;
@end


@implementation RootViewController

@synthesize addPositionButton, refreshPositionButton, activityIndicator, showListButton, searchButton, addMapButton, redpinLogoButton, 
			currentMap, currentLocation, showingLocation, mapViewController,
			mapListController, listController, backsideController, searchController;

NSString * const IntervalScanStopNotification = @"StopIntervalScan";

- (void)viewDidLoad {
    
	
	if(!restoredState) {
		restoredState = YES;
		[[StateSaveManager sharedStateSaveManagerWithRootViewController:self] restoreState];
	}
	
	if(!currentMap) {
		self.title = @"Map";
	}	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged:) name:InternetConnectionManagerUpdateNotification object:nil];
		
	[super viewDidLoad];

}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:InternetConnectionManagerUpdateNotification object:nil];
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {
	[mapViewController viewWillAppear:animated];
    [super viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
	[mapViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Support all orientations except upside down
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) showPortrait {
	[UIView beginAnimations:nil context:nil]; 
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut]; 
	[UIView setAnimationDuration:0.7]; 
	[self.navigationController setNavigationBarHidden:NO];
	[self.navigationController setToolbarHidden:NO];
	
	[UIView commitAnimations];
}

- (void) showLandscape {
		
	[self.navigationController setNavigationBarHidden:YES];		
	[self.navigationController setToolbarHidden:YES];	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
	switch (interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			[self showPortrait];
						
			break;
		case UIInterfaceOrientationLandscapeLeft:
			[self showLandscape];
			
		case UIInterfaceOrientationLandscapeRight:
			[self showLandscape];
			
		default:
			break;
	}
		
}




#pragma mark -
#pragma mark View Controllers

- (void) initListController {
	if(self.listController == nil) {
		ListTableViewController *view = [[ListTableViewController alloc] initWithNibName:@"ListTableViewController" bundle: nil];
		[self setListController:view];
		[view release];
	}
	
}


- (void) initSearchController {
	if(self.searchController == nil) {
		SearchTableViewController *view = [[SearchTableViewController alloc] initWithNibName:@"SearchTableViewController" bundle: nil];
		[self setSearchController:view];
		[view release];
	}
	
}

- (void) initBacksideController {
	if(self.backsideController == nil) {
		BacksideViewController *view = [[BacksideViewController alloc] initWithNibName:@"BacksideViewController" bundle: nil];
		[view setRootViewController:self];
		[self setBacksideController:view];
		[view release];
	}
	
}


#pragma mark -
#pragma mark Button Actions


- (IBAction) addPosition:(id)sender {
	[self notifyStopIntervalScan];
	if(locateInProgress) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sniffer busy" message:@"At the moment, the sniffer is trying to locate you. Please wait until the sniffer has finished." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	NSLog(@"addPosition");
	
	[[ActivityIndicator sharedActivityIndicator] showWithText:@"Taking measurement..."];
	
	Sniffer *sniffer = [[Sniffer alloc] initWithDelegate:self];
	if(sniffer) {
		[sniffer performScan];
	} else {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"WiFi Scanner" message:@"Whooops. WiFi Scanner can't be initialized" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[view show];
		[view release];
		[self.activityIndicator stopAnimating];
	}	
	
	[[EntityHome sharedEntityHome] saveContext];
}	



- (IBAction) showList:(id)sender {
	[self notifyStopIntervalScan];
	NSLog(@"showList");
	[self initListController];
	[self.navigationController pushViewController:self.listController animated:YES];
}


- (IBAction) addMap:(id)sender {	
	NSLog(@"addMap");	
	
	AddMapViewController *view = [[AddMapViewController alloc] initWithNibName:@"AddMapViewController" bundle: nil];	
	[self.navigationController pushViewController:view animated:YES];
	[view release];
		
}

- (IBAction) search:(id)sender {
	NSLog(@"search");
	
	[self initSearchController];
	[self.navigationController pushViewController:self.searchController animated:YES];
	
	
}
	
- (IBAction) refreshPosition:(id)sender {
	[self notifyStopIntervalScan];
	
	NSLog(@"refreshPosition");
	
	locateInProgress = YES;
	
	if([self.activityIndicator isAnimating]) {
		return;
	}
	[self.refreshPositionButton setEnabled:NO];
	[self.activityIndicator startAnimating];
	
	Sniffer *sniffer = [[Sniffer alloc] initWithDelegate:self];
	if(sniffer) {
		[sniffer performScan];
	} else {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"WiFi Scanner" message:@"Whooops. WiFi Scanner can't be initialized" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[view show];
		[view release];
		[self.activityIndicator stopAnimating];
	}	
	
}

- (IBAction) flipBackside:(id)sender {
	NSLog(@"Show Credits");
	[self initBacksideController];
	
	UIView *viewContainer = [self navigationController].view;
		
	// Setup Flip-Animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0f];
	
	[UIView setAnimationTransition:(backsideVisible ? UIViewAnimationTransitionFlipFromLeft :  UIViewAnimationTransitionFlipFromRight)
						   forView:viewContainer cache:YES];
	
	[viewContainer addSubview:self.backsideController.view];
	
	// Execute Flip	
	if (!backsideVisible) {
		[viewContainer addSubview:self.backsideController.view];
	}
	else {
		[self.backsideController.view removeFromSuperview]; 
	}
	
	backsideVisible = !backsideVisible;
	
	[UIView commitAnimations];
}


#pragma mark -
#pragma mark IntervalScannerDelegate

- (void) scanner:(IntervalScanner *)scanner finishScan:(int) count {
	[scanner release];
}

- (void) notifyStopIntervalScan {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSLog(@"Sending stop interval scan notification");
	[nc postNotificationName:IntervalScanStopNotification object:self];
}

#pragma mark -
#pragma mark SnifferDelegate

- (void) sniffer:(Sniffer *)aSniffer didScan:(Measurement *) measurement {
	snifferMovementWasShown = NO;
	
	if(locateInProgress) {
		[aSniffer retrieveLocationForMeasurement:measurement];
	} else {
		Fingerprint *fp = [self buildPosition: measurement];
		IntervalScanner *scanner = [[IntervalScanner alloc] initWithLocation:fp.location Delegate:self];
		if(scanner) {
			[scanner startScan];
		}
		[aSniffer release];

	}
	[measurement release];
}

- (void) sniffer:(Sniffer *)aSniffer estimatedLocation:(Location *)curLocation {
	[self.activityIndicator stopAnimating];
	[self.refreshPositionButton setEnabled:YES];
	if(curLocation) {
		[self setCurrentLocation:curLocation];
	} else {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Locator" message:@"Server could not locate your position. Please try again" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[view show];
		[view release];
	}
	[aSniffer release];
	
	locateInProgress = NO;
}

- (void) sniffer:(Sniffer *)aSniffer detectedContinuingMovement:(NSUInteger) numberOfSeconds  {
	if(!snifferMovementWasShown) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"WiFI Scanner" message:@"The scanner detected some continuing movement. Please try to keep the phone still while scanning" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		snifferMovementWasShown = YES;
	}
	
}

- (Fingerprint *) buildPosition:(Measurement *) m {
	[[ActivityIndicator sharedActivityIndicator] hide];
	Fingerprint *fp = [[FingerprintHome newObjectInContext] retain];
	Location *loc = [[LocationHome newObjectInContext] retain];
	
	for(WifiReading *r in m.wifiReadings) {
		[WifiReadingHome insertObjectInContext:r];
	}
	[MeasurementHome insertObjectInContext:m];
	
	[mapViewController addEmptyMarkerWithLocation:loc];
	
	[fp setLocation:loc];
	[fp setMeasurement:m];
	
	[[EntityHome sharedEntityHome] saveContext];
	
	//[m release];
	//[loc release];
	//[fp autorelease];
	return fp;
}

#pragma mark -

- (void) setCurrentMap:(Map *) map {
	NSLog(@"setCurrentMap");

	if (map != currentMap) {
		[currentMap release];
		currentMap = [map retain];
		
		if([[InternetConnectionManager sharedInternetConnectionManager] onlineMode]) {
			[self.addPositionButton setEnabled:YES];
		}
		self.title = map.mapName;
		
	}
	
	if(currentLocation) {
		[mapViewController removeLocation:currentLocation];
		[currentLocation release];
		currentLocation = nil;
		
	}
	
	[mapViewController setMap:currentMap];
}



- (void) setCurrentLocation:(Location *) loc animated:(BOOL) animated{
	if (loc != currentLocation) {
		[currentLocation release];
		currentLocation = [loc retain];
		
		if (loc.map != currentMap) {
			[currentMap release];
			currentMap = [loc.map retain];
			if([[InternetConnectionManager sharedInternetConnectionManager] onlineMode]) {
				[self.addPositionButton setEnabled:YES];
			}
			self.title = currentMap.mapName;
		}		
		[self.mapViewController setCurrentLocation:loc animated:animated];			
	} else {
		[self.mapViewController scrollToMarker:self.mapViewController.currentLocationMarker animated:YES];
	}
	
}

- (void) setCurrentLocation:(Location *) loc {
	[self setCurrentLocation:loc animated:YES];
}


- (void) showLocation:(Location *) loc {
	[self showLocation:loc animated:YES];
}

- (void) showLocation:(Location *) loc animated:(BOOL) animated {
	
	if (loc != showingLocation) {
		[showingLocation release];
		showingLocation = [loc retain];
		
		if (loc.map != currentMap) {
			[currentMap release];
			currentMap = [loc.map retain];
			[self.addPositionButton setEnabled:YES];
			self.title = currentMap.mapName;
		}
				
		[self.mapViewController setLocation:loc animated:animated];		
	}
	
}

#pragma mark -
#pragma mark Internet Connection Mode



- (void) setInternetMode {
	BOOL online = [[InternetConnectionManager sharedInternetConnectionManager] onlineMode];
	
	[self.addMapButton setEnabled:online];	
	
	if(!online || currentMap) {
		[self.addPositionButton setEnabled:online];	
	}
	[self.refreshPositionButton setEnabled:online];
	
}

- (void) internetConnectionChanged:(NSNotification *) note {
	
	[self setInternetMode];
}

#pragma mark -
#pragma mark Memory
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {

	[addPositionButton release];
	[refreshPositionButton release];
	[searchButton release];
	[addMapButton release];
	
	[currentMap release];
	[currentLocation release];
	[mapViewController release];
	[mapListController release];
	
    [super dealloc];
}


@end

