//
//  BordView.m
//  MacAVLearn
//
//  Created by pinky on 2020/4/28.
//  Copyright © 2020 pinky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BordView.h"

@implementation BordView

-(id)init
{
    self = [super init];
    return self;
}
-(void)drawRect:(NSRect)dirtyRect
{

//    [NSGraphicsContext saveGraphicsState];
//    + (void)fillRect:(NSRect)rect;
//    + (void)strokeRect:(NSRect)rect;
//    + (void)clipRect:(NSRect)rect;
    NSRect rect = [self bounds];
    NSLog(@"Pinky, drawRect:(%f, %f)", rect.size.width, rect.size.height );
    //       NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:20 yRadius:20];
//    NSBezierPath *path = [NSBezierPath fillRect:rect];
//
//       [path addClip];
//       [[NSColor greenColor] set];
//        [NSBezierPath clipRect:rect];
//       NSRectFill(dirtyRect);
//       [NSGraphicsContext restoreGraphicsState];

    [[NSColor greenColor] set];
     NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    path.lineWidth = 10;
    [path stroke];

       [super drawRect:dirtyRect];
}

@end
