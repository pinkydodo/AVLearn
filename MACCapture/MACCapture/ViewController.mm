//
//  ViewController.m
//  MACCapture
//
//  Created by pinky on 2020/5/18.
//  Copyright © 2020 pinky. All rights reserved.
//

#import "ViewController.h"
#include "ScreenCaptureMac.hpp"
#include <thread>

@interface ViewController()
{
    ScreenCaptureMac  capture;
    std::thread mythread;
}

@end

void fun( int a )
{
    for( int i = 0 ; i < a ; i++ )
    {
        printf("Hello world:%d\n",i);
    }
}

#include <stdlib.h>
#include <stdio.h>
void  DisplaysReconfiguredCallback(CGDirectDisplayID display,
CGDisplayChangeSummaryFlags flags, void * __nullable userInfo)
{
//    kCGDisplayBeginConfigurationFlag      = (1 << 0),
//    kCGDisplayMovedFlag                   = (1 << 1),
//    kCGDisplaySetMainFlag                 = (1 << 2),
//    kCGDisplaySetModeFlag                 = (1 << 3),
//    kCGDisplayAddFlag                     = (1 << 4),
//    kCGDisplayRemoveFlag                  = (1 << 5),
//    kCGDisplayEnabledFlag                 = (1 << 8),
//    kCGDisplayDisabledFlag                = (1 << 9),
//    kCGDisplayMirrorFlag                  = (1 << 10),
//    kCGDisplayUnMirrorFlag                = (1 << 11),
//    kCGDisplayDesktopShapeChangedFlag     = (1 << 12)
    

    NSLog(@"Reconfig:%o, dis:%d", flags, display );
    
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGError err = CGDisplayRegisterReconfigurationCallback(DisplaysReconfiguredCallback,  nil );
    
    return ;
    std::vector<Display*> displays;
    
    capture.prepare();
    capture.getDisplays( displays );
    capture.setExclusiveWindowID( 16473 );
    
    if( !displays.empty() )
    {
        Settings config;
        config.displayIndex = 0;
        config.output_width = 1080;
        config.output_height = 720;
        config.pixel_format = 0;
        capture.configure( config );
        
        capture.start();
    }
    
    mythread = std::thread( fun, 10 );
    

    // Do any additional setup after loading the view.
}



- (IBAction)moveWindow:(NSButton *)sender {
    //do something
//    [UIImage imageWithColor:[CIColor redColor] size: CGSizeMake( 400, 400 )];
    
//    CIFilter
//    [CIImage imageWithColor: [CIColor redColor]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    

    
    // Update the view, if already loaded.
}


@end
