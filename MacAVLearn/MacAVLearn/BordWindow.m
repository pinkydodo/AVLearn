//
//  BordWindow.m
//  MacAVLearn
//
//  Created by pinky on 2020/4/27.
//  Copyright © 2020 pinky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BordWindow.h"
#import "BordView.h"

@interface BordWindow()
{
    BordView* m_view;
}
@end

@implementation  BordWindow


-(id)init
{
    if( self = [super init])
    {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        self.ignoresMouseEvents = YES;
        [self setStyleMask:NSWindowStyleMaskBorderless];
    }
    
    m_view = [[BordView alloc] initWithFrame: NSMakeRect( 0, 0 , self.frame.size.width, self.frame.size.height )];
    [self.contentView addSubview: m_view];
    
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    [NSGraphicsContext saveGraphicsState];
//
//
//
//    NSRect rect = [self frame];
//    rect.origin.x = 0;
//    rect.origin.y = 0;
//
//       NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5 yRadius:5];
//
//       [path addClip];
//
//
//
//       [[NSColor controlColor] set];
//
//       NSRectFill(dirtyRect);
//
//
//
//       [NSGraphicsContext restoreGraphicsState];
//
//
//
//       [super drawRect:dirtyRect];
//
//}



-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{



    if (self = [super initWithContentRect: contentRect
                                styleMask: NSBorderlessWindowMask | NSResizableWindowMask //NSBorderlessWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
                                  backing: bufferingType
                                    defer: TRUE])
    {

        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        
        m_view = [[BordView alloc] initWithFrame: NSMakeRect( 0, 0 , self.frame.size.width, self.frame.size.height )];
        [self.contentView addSubview: m_view];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
        selector:@selector(windowDidResize:)
        name:NSWindowDidResizeNotification
        object:self];

    }
//
//    NSScreenSaverWindowLevel
//    NSWindowStyleMaskNonactivatingPanel

    return self;

}

- (void)windowDidResize:(NSNotification *)notification
{
    NSLog(@"Pinky:onResize:%f,%f", self.frame.size.width, self.frame.size.height);
    [m_view setFrame: NSMakeRect( 0, 0,  self.frame.size.width,  self.frame.size.height )];
    [m_view setNeedsDisplay: true ];
}

@end
