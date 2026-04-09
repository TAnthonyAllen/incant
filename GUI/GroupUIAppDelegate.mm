//
//  GroupUIAppDelegate.m
//  GroupUI
//
//  Created by anthony on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

class Bwana;
class Control;
class Groups;
class Delimited;
class Details;
class GroupItem;
class GroupRegistry;
class ParseXML;
class PLGitem;
class PLGparse;
class Stak;
class Tape;
class DoubleLink;
class DoubleLinkList;
#import <Cocoa/Cocoa.h>
#import "Layout.h"
#import "Actions.h"
#import "Bwana.h"
#import "Control.h"
#import "GroupUIAppDelegate.h"

@implementation GroupUIAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	Control::bwana->controller->start(window);
}

@end
