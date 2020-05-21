//
//  ViewController.m
//  MACCapture
//
//  Created by pinky on 2020/5/18.
//  Copyright © 2020 pinky. All rights reserved.
//

#import "ViewController.h"
#include "ScreenCaptureMac.hpp"

@interface ViewController()
{
    ScreenCaptureMac  capture;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    std::vector<Display*> displays;
    
    capture.prepare();
    capture.getDisplays( displays );
    capture.setExclusiveWindowID( 151 );
    
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

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    

    
    // Update the view, if already loaded.
}


@end
