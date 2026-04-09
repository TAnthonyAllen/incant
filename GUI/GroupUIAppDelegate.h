//
//  GroupUIAppDelegate.h
//  GroupUI
//
//  Created by anthony on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GroupUIAppDelegate : NSObject <NSApplicationDelegate> {
    __unsafe_unretained NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
