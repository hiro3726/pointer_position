//
//  main.m
//  pointer_position
//
//  Created by Hiro on 11/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Cocoa/Cocoa.h>

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef theEvent, void *refcon) {
    static float baseline = 0.0;
    static BOOL first = YES;
    
    CGPoint point = CGEventGetLocation(theEvent);
    switch(CGEventGetType(theEvent)) {
        case kCGEventLeftMouseDown:
            printf("%.0f%s", -(point.y - baseline), first ? "\t" : "\n");
            fflush(stdout);
            first = !first;
            break;
        case kCGEventOtherMouseDown:
            if (!first) {
                puts("");
                first = YES;
            }
            printf("baseline changed: %.0f -> %.0f\n", baseline, point.y);
            baseline = point.y;
            break;
        case kCGEventRightMouseDown:
            break;
    }
    //NSLog(@"Location? x= %f, y = %f", (float)point.x, (float)point.y);
    return theEvent;
}


int main (int argc, const char * argv[])
{

    @autoreleasepool {
        // insert code here...
        CFRunLoopSourceRef runLoopSource;
        
        //listen for touch events
        //this is officially unsupported/undocumented
        //but the NSEvent masks seem to map to the CGEvent types
        //for all other events, so it should work.
        CGEventMask eventMask = (
                                 (1 << kCGEventLeftMouseDown)      |
                                 (1 << kCGEventRightMouseDown)     |
                                 (1 << kCGEventOtherMouseDown)
                                 );
        
        // Keyboard event taps need Universal Access enabled, 
        // I'm not sure about multi-touch. If necessary, this code needs to 
        // be here to check whether we're allowed to attach an event tap
        if (!AXAPIEnabled()&&!AXIsProcessTrusted()) { 
            // error dialog here 
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Could not start event monitoring."];
            [alert setInformativeText:@"Please enable \"access for assistive devices\" in the Universal Access pane of System Preferences."];
            [alert runModal];
            goto out;
        } 
        
        
        //create the event tap
        CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap, //this intercepts events at the lowest level, where they enter the window server
                                    kCGHeadInsertEventTap, 
                                    kCGEventTapOptionDefault, 
                                    eventMask,
                                    myCGEventCallback, //this is the callback that we receive when the event fires
                                    nil); 
        
        // Create a run loop source.
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
        
        // Add to the current run loop.
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        
        // Enable the event tap.
        CGEventTapEnable(eventTap, true);
        CFRunLoopRun();
    }
    out:
    return 0;
}

