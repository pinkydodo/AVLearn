//
//  ViewController.m
//  MacAVLearn
//
//  Created by pinky on 2020/4/26.
//  Copyright © 2020 pinky. All rights reserved.
//

#import "ViewController.h"

#include <string>
#include <vector>
#import <CoreGraphics/CGWindow.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

//#import <Cocoa/Cocoa.h>
//#import "NSScreen+BDUtilities.h"

#import "BordWindow.h"


extern "C" AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);
ViewController* this_ptr = NULL;
#define WINDOW_NAME   ((__bridge NSString*)kCGWindowName)
#define WINDOW_NUMBER ((__bridge NSString*)kCGWindowNumber)
#define OWNER_NAME    ((__bridge NSString*)kCGWindowOwnerName)
#define OWNER_PID     ((__bridge NSNumber*)kCGWindowOwnerPID)

struct CWindowInfo
{
    std::string m_windowName;
    std::string m_ownerName;
    int m_windowId;
    int m_ownerId;
    
};

static NSComparator win_info_cmp = ^(NSDictionary *o1, NSDictionary *o2)
{
    NSComparisonResult res = [o1[OWNER_NAME] compare:o2[OWNER_NAME]];
    if (res != NSOrderedSame)
        return res;

    res = [o1[OWNER_PID] compare:o2[OWNER_PID]];
    if (res != NSOrderedSame)
        return res;

    res = [o1[WINDOW_NAME] compare:o2[WINDOW_NAME]];
    if (res != NSOrderedSame)
        return res;

    return [o1[WINDOW_NUMBER] compare:o2[WINDOW_NUMBER]];
};

std::vector<CWindowInfo> getWindowsList()
{
    std::vector<CWindowInfo> winList;
//    kCGWindowListExcludeDesktopElements
    NSArray* arr = (__bridge NSArray*)CGWindowListCopyWindowInfo( kCGWindowListOptionAll  , kCGNullWindowID );
    
    NSArray* arrOrder = [arr sortedArrayUsingComparator:win_info_cmp];

    int index = 0;
    for( NSDictionary* dict in arrOrder )
    {
        NSString *owner = (NSString*)dict[OWNER_NAME];
        NSString *window  = (NSString*)dict[WINDOW_NAME];
        NSNumber *windowid    = (NSNumber*)dict[WINDOW_NUMBER];
        NSNumber *ownerid    = (NSNumber*)dict[OWNER_PID];
        
        CWindowInfo info;
        info.m_ownerName = owner.UTF8String;
//        info.m_windowName = window.UTF8String;
        info.m_windowId = [windowid intValue];
        info.m_ownerId = [ownerid intValue];
        NSLog(@"index:%d", index );
        for( NSString* key in dict )
        {
            NSLog(@"     %@   :%@", key , dict[key]);
        }
        index++;
        
    }
    NSLog(@"getwin count:%d", arrOrder.count);
    return winList;
}

@interface ViewController()
{
    BordWindow* m_bord;
    NSWindowController* m_bordWindowC;
    AXObserverRef m_observer_ref;
    
    AXUIElementRef m_appRef;
    AXUIElementRef m_windowRef;
    CGWindowID m_windowId;
    NSTimer* m_timer;
}

-(void)showBorder;
-(void)hideBorder:(BOOL) bReshow;
@end

static void OnEventReceived(
    AXObserverRef observer_ref,
    AXUIElementRef element,
    CFStringRef notification,
    void *refcon) {
//  ViewController* this_ptr =
//      static_cast<ViewController*>(refcon);
//  [this_ptr EventReceived:element notification:notification];
    NSLog(@"receiveEvent:%@", notification );
    
//      [self AddNotification:NSAccessibilityMainWindowChangedNotification element:m_appRef];
//      [self AddNotification:NSAccessibilityFocusedWindowChangedNotification element:m_appRef];
//      [self AddNotification:NSAccessibilityApplicationActivatedNotification element:m_appRef];
//      [self AddNotification:NSAccessibilityApplicationDeactivatedNotification element:m_appRef];
//      [self AddNotification:NSAccessibilityApplicationHiddenNotification element:m_appRef];
//      [self AddNotification:NSAccessibilityApplicationShownNotification element:m_appRef];
//
//
//
//      [self AddNotification:NSAccessibilityWindowMovedNotification element:m_windowRef];
//      [self AddNotification:NSAccessibilityWindowResizedNotification element:m_windowRef];
//      [self AddNotification:NSAccessibilityWindowMiniaturizedNotification element:m_windowRef];
//      [self AddNotification:NSAccessibilityWindowDeminiaturizedNotification element:m_windowRef];
    
    NSString* note = (__bridge NSString *)notification;
    
    if(
       [note isEqualToString: NSAccessibilityWindowMiniaturizedNotification] ||
       [note isEqualToString: NSAccessibilityApplicationHiddenNotification] )
    {
        [this_ptr hideBorder:false];
    }
    else if([note isEqualToString: NSAccessibilityWindowMovedNotification] ||
    [note isEqualToString: NSAccessibilityWindowResizedNotification])
    {
        [this_ptr hideBorder:true ];

    }
    else if( [note isEqualToString: NSAccessibilityWindowDeminiaturizedNotification ] ||
            [note isEqualToString:NSAccessibilityApplicationActivatedNotification ] ||
            [note isEqualToString:NSAccessibilityApplicationDeactivatedNotification ]||
            [note isEqualToString:NSAccessibilityFocusedWindowChangedNotification ]||
            [note isEqualToString:NSAccessibilityApplicationShownNotification ]){
        [this_ptr showBorder];
    }
}



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    getWindowsList();
    // Do any additional setup after loading the view.
    this_ptr = self;
    
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
    
//    self window
}

- (int) getScreenHeight {

    NSArray *screenArray = [NSScreen screens];
    NSScreen *mainScreen = [NSScreen mainScreen];
    unsigned screenCount = [screenArray count];
    unsigned index  = 0;

    int screenHeight = 0;
    for (index; index < screenCount; index++)
    {
      NSScreen *screen = [screenArray objectAtIndex: index];
      NSRect screenRect = [screen visibleFrame];
      NSString *mString = ((mainScreen == screen) ? @"Main" : @"not-main");

//      NSLog(@"Screen #%d (%@) Frame: %@", index, mString, NSStringFromRect(screenRect));
        screenHeight = screenRect.size.height + screenRect.origin.y;
    }
    
    return screenHeight;
}

-(void)AddNotification:(NSString*)notification  element:(AXUIElementRef) element
{
    AXError err = AXObserverAddNotification( m_observer_ref, element, static_cast<CFStringRef>(notification), NULL);
    if( err != 0 )
    {
        NSLog(@"Err:%@", notification );
    }
}

-(void)EventReceived:(AXUIElementRef)element  notification:(NSString*)notification
{
    NSLog(@"receiveEvent:%@", notification);
}

-(void)showBorder
{
    if( m_bord == NULL )
    {
        return ;
    }
    AXValueRef position;
    CGPoint point;
    AXUIElementCopyAttributeValue(m_windowRef, kAXPositionAttribute, (CFTypeRef *)&position);
    AXValueGetValue(position, (AXValueType)kAXValueCGPointType, &point);

    NSLog(@"point=%f,%f", point.x,point.y);
    
    AXValueRef sizeRef;
    CGSize size;
    AXUIElementCopyAttributeValue(m_windowRef, kAXSizeAttribute, (CFTypeRef *)&sizeRef);
    AXValueGetValue(sizeRef, (AXValueType)kAXValueCGSizeType, &size);
    
    int screenHight = [self getScreenHeight] ;
    
    int border = 10;
    int y = point.y;
    int height =  size.height;
    if( y < border )
    {
        y = border;
        height -= ( border - y );
    }
    
    NSRect rect = NSMakeRect( point.x - border , screenHight - y - size.height + border, size.width + 2*border,  size.height + 2*border );
    
//    NSRect rect = NSMakeRect( 20, 20 ,1880, 935 );
    
    [m_bord orderWindow:NSWindowAbove
    relativeTo:(NSInteger)m_windowId];
    
    [m_bord setFrame: rect  display: true ];
    
    NSLog(@"Pinky,ori:,(%f, %f), size:(%f, %f )", point.x, point.y, size.width, size.height );
    NSLog(@"Pinky,set.frame,(%f, %f), size:(%f, %f )", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height );
    NSLog(@"Pinky,window.frame,(%f, %f), size:(%f, %f )", m_bord.frame.origin.x, m_bord.frame.origin.y, m_bord.frame.size.width, m_bord.frame.size.height );
    
    [m_bord setIsVisible: true ];
}

-(void)hideBorder:(BOOL) bReshow
{
    if( m_bord )
    {
        [m_bord setIsVisible: false ];
        
        
        if( m_timer )
        {
            [m_timer invalidate];
        }
        if( bReshow )
        {
            m_timer = [NSTimer timerWithTimeInterval:0.2 repeats:false block:^(NSTimer * _Nonnull timer) {
                [self showBorder];
            }];
            
             [[NSRunLoop currentRunLoop] addTimer:m_timer forMode:NSDefaultRunLoopMode];
        }

    }
}

-(void)putWindowFront
{
    AXError err;
    err = AXUIElementSetAttributeValue(m_windowRef, kAXMainAttribute, kCFBooleanTrue);
      err = AXUIElementSetAttributeValue(m_windowRef, kAXFocusedApplicationAttribute, kCFBooleanTrue);
      err = AXUIElementSetAttributeValue(m_windowRef, kAXFocusedAttribute, kCFBooleanTrue);
      err = AXUIElementSetAttributeValue(m_appRef, kAXFocusedWindowAttribute, kCFBooleanTrue);
      err = AXUIElementSetAttributeValue(m_appRef, kAXFrontmostAttribute, kCFBooleanTrue);
      err = AXUIElementSetAttributeValue(m_windowRef, kAXFocusedAttribute, kCFBooleanTrue );
    
}

- (IBAction)moveWindow:(NSButton *)sender {
    NSLog(@"move Window");
    int ownerId    = 97358;
//    kCGWindowSharingState
    if( m_appRef == NULL )
    {
        m_appRef = AXUIElementCreateApplication(ownerId);
        NSLog(@"Pinky,appRef = %@",m_appRef);
        
        CFArrayRef windowList;
        AXError err = AXUIElementCopyAttributeValue(m_appRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
        NSLog(@"WindowList = %@", windowList);
        if ((!windowList) || CFArrayGetCount(windowList)<1)
            return;
        
        // get just the first window for now
        m_windowRef = (AXUIElementRef) CFArrayGetValueAtIndex( windowList, 0);
        NSLog(@"Pinky windowRef = %@",m_windowRef);

        _AXUIElementGetWindow( m_windowRef, &m_windowId );
        NSLog(@"put front window:%d", (int)m_windowId );
        
        err = AXObserverCreate( ownerId, OnEventReceived, &m_observer_ref );
        CFRunLoopAddSource(
        [[NSRunLoop currentRunLoop] getCFRunLoop],
        AXObserverGetRunLoopSource(m_observer_ref),
        kCFRunLoopDefaultMode);
        
//      m_bordWindowC = [[NSWindowController alloc]initWithWindowNibName:@"BordWindow"];
//      m_bord = (BordWindow*)m_bordWindowC.window;
        
            m_bord =  [[BordWindow alloc ] initWithContentRect:NSMakeRect(0,0,100,100) styleMask:(NSUInteger)NSResizableWindowMask backing:(NSBackingStoreType)NSBackingStoreRetained defer:(BOOL)true];
            m_bordWindowC = [[NSWindowController alloc]initWithWindow:m_bord];
    
      [m_bordWindowC showWindow:nil];
        
          [self AddNotification:NSAccessibilityMainWindowChangedNotification element:m_appRef];
          [self AddNotification:NSAccessibilityFocusedWindowChangedNotification element:m_appRef];
          [self AddNotification:NSAccessibilityApplicationActivatedNotification element:m_appRef];
          [self AddNotification:NSAccessibilityApplicationDeactivatedNotification element:m_appRef];
          [self AddNotification:NSAccessibilityApplicationHiddenNotification element:m_appRef];
          [self AddNotification:NSAccessibilityApplicationShownNotification element:m_appRef];
        
          

          [self AddNotification:NSAccessibilityWindowMovedNotification element:m_windowRef];
          [self AddNotification:NSAccessibilityWindowResizedNotification element:m_windowRef];
          [self AddNotification:NSAccessibilityWindowMiniaturizedNotification element:m_windowRef];
          [self AddNotification:NSAccessibilityWindowDeminiaturizedNotification element:m_windowRef];
        
//        [m_bord setBackgroundColor: NSColor.greenColor];
    }
    

    

    
  
   
    
    
//    [self putWindowFront];
    [self showBorder];

//    AXObserverAddNotification()

//    [m_bord showWindow: self];
//    [m_bord ]
}



- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
