//
//  ScreenCaptureMac.cpp
//  MACCapture
//
//  Created by pinky on 2020/5/18.
//  Copyright © 2020 pinky. All rights reserved.
//

#include "ScreenCaptureMac.hpp"
#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreImage/CoreImage.h>
#include <sstream>

Settings::Settings()
  :displayIndex(-1)
  ,pixel_format(-1)
  ,output_width(-1)
  ,output_height(-1)
{
}

//PixelBuffer::PixelBuffer()
//   :pixel_format(SC_NONE)
//   ,width(0)
//   ,height(0)
//   ,user(NULL)
// {
//   plane[0] = NULL;
//   plane[1] = NULL;
//   plane[2] = NULL;
//   stride[0] = 0;
//   stride[1] = 0;
//   stride[2] = 0;
//   nbytes[0] = 0;
//   nbytes[1] = 0;
//   nbytes[2] = 0;
// }
//
// PixelBuffer::~PixelBuffer() {
//   pixel_format = SC_NONE;
//   plane[0] = NULL;
//   plane[1] = NULL;
//   plane[2] = NULL;
//   stride[0] = 0;
//   stride[1] = 0;
//   stride[2] = 0;
//   nbytes[0] = 0;
//   nbytes[1] = 0;
//   nbytes[2] = 0;
//   user = NULL;
// }

//int PixelBuffer::init(int w, int h, int fmt) {
//
//  if (w <= 0) {
//    printf("Error: initializing a PixelBuffer with a width which is < 0. %d\n", w);
//    return -1;
//  }
//
//  if (h <= 0) {
//    printf("Error: initializing a PixelBuffer with a height which is < 0. %d\n", h);
//    return -2;
//  }
//
////  if (SC_BGRA == fmt) {
////    /* This may be overwritten by the capture driver. */
////    nbytes[0] = w * h * 4;
////  }
////  else {
//////    printf("Error: pixel buffer has no initialisation for the given format: %s\n", screencapture_pixelformat_to_string(fmt).c_str());
////    return -3;
////  }
//
//  width = w;
//  height = h;
//  pixel_format = fmt;
//
//  return 0;
//}

class MacDisplayConfig
{
public:
    CGDirectDisplayID m_id;
    // Bounds of the desktop excluding monitors with DPI settings different from
    // the main monitor. In Density-Independent Pixels (DIPs).
    CGRect bounds;
    // Same as bounds, but expressed in physical pixels.
    CGRect pixel_bounds;
    // Scale factor from DIPs to physical pixels.
    float dip_to_pixel_scale = 1.0f;
};

class MacDesktopConfig
{
public:
    
    static MacDesktopConfig GetCurrent();
    // Bounds of the desktop excluding monitors with DPI settings different from
    // the main monitor. In Density-Independent Pixels (DIPs).
    CGRect bounds;
    // Same as bounds, but expressed in physical pixels.
    CGRect pixel_bounds;
    // Scale factor from DIPs to physical pixels.
    float dip_to_pixel_scale = 1.0f;
    
    std::vector<MacDisplayConfig> displays;
};

MacDisplayConfig GetConfigurationForScreen(NSScreen* screen) {
  MacDisplayConfig display_config;

  // Fetch the NSScreenNumber, which is also the CGDirectDisplayID.
  NSDictionary* device_description = [screen deviceDescription];
  display_config.m_id = static_cast<CGDirectDisplayID>(
      [[device_description objectForKey:@"NSScreenNumber"] intValue]);

  // Determine the display's logical & physical dimensions.
  NSRect ns_bounds = [screen frame];
  display_config.bounds = CGRectMake( ns_bounds.origin.x, ns_bounds.origin.y, ns_bounds.size.width, ns_bounds.size.height );

  // If the host is running Mac OS X 10.7+ or later, query the scaling factor
  // between logical and physical (aka "backing") pixels, otherwise assume 1:1.
  if ([screen respondsToSelector:@selector(backingScaleFactor)] &&
      [screen respondsToSelector:@selector(convertRectToBacking:)]) {
    display_config.dip_to_pixel_scale = [screen backingScaleFactor];
    NSRect ns_pixel_bounds = [screen convertRectToBacking: ns_bounds];
    display_config.pixel_bounds = CGRectMake( ns_pixel_bounds.origin.x, ns_pixel_bounds.origin.y, ns_pixel_bounds.size.width, ns_pixel_bounds.size.height );;
  } else {
    display_config.pixel_bounds = display_config.bounds;
  }

  // Determine if the display is built-in or external.
    //todopinky
//  display_config.is_builtin = CGDisplayIsBuiltin(display_config.id);

  return display_config;
}

void InvertRectYOrigin(const CGRect& bounds,
                       CGRect* rect) {
//  assert(bounds.top() == 0);
    *rect = CGRectMake( rect->origin.x, ( (bounds.origin.y + bounds.size.height) - (rect->origin.y + rect->size.height) ) ,  rect->size.width, rect->size.height);
    
    //bounds.bottom() - rect->bottom(),

}
//为了获取dip_to_pixel_scale
MacDesktopConfig MacDesktopConfig::GetCurrent()
{
    MacDesktopConfig desktop_config;
    NSArray* screens = [NSScreen screens];
    assert(screens);
    
    // Iterator over the monitors, adding the primary monitor and monitors whose
    // DPI match that of the primary monitor.
    for (NSUInteger i = 0; i < [screens count]; ++i) {
        MacDisplayConfig display_config = GetConfigurationForScreen([screens objectAtIndex: i]);

        if (i == 0)
            desktop_config.dip_to_pixel_scale = display_config.dip_to_pixel_scale;

          // Cocoa uses bottom-up coordinates, so if the caller wants top-down then
          // we need to invert the positions of secondary monitors relative to the
          // primary one (the primary monitor's position is (0,0) in both systems).
//          if (i > 0 && origin == TopLeftOrigin) {
        if( i> 0 )
        {
            InvertRectYOrigin(desktop_config.displays[0].bounds,
                              &display_config.bounds);
            // |display_bounds| is density dependent, so we need to convert the
            // primay monitor's position into the secondary monitor's density context.
            float scaling_factor = display_config.dip_to_pixel_scale /
                desktop_config.displays[0].dip_to_pixel_scale;
        CGRect primary_bounds = CGRectMake(desktop_config.displays[0].pixel_bounds.origin.x* scaling_factor,
                                               desktop_config.displays[0].pixel_bounds.origin.y * scaling_factor,
                                           desktop_config.displays[0].pixel_bounds.size.width * scaling_factor ,
                                           desktop_config.displays[0].pixel_bounds.size.height * scaling_factor );
            InvertRectYOrigin(primary_bounds, &display_config.pixel_bounds);
        }
        
        // Add the display to the configuration.
           desktop_config.displays.push_back(display_config);

           // Update the desktop bounds to account for this display, unless the current
           // display uses different DPI settings.
//           if (display_config.dip_to_pixel_scale == desktop_config.dip_to_pixel_scale) {
//             desktop_config.bounds.UnionWith(display_config.bounds);
//             desktop_config.pixel_bounds.UnionWith(display_config.pixel_bounds);
//           }
         }

         return desktop_config;
}

CIContext* context = nil;
ScreenCaptureMac::ScreenCaptureMac()
{
    dq = dispatch_queue_create("screen capture", DISPATCH_QUEUE_SERIAL);
    m_cb = this;
    m_bStarted = false;
    m_exclusiveWnd = 0;
    
    NSMutableDictionary *option = [[NSMutableDictionary alloc] init];
    [option setObject: [NSNull null] forKey: kCIContextWorkingColorSpace];
    [option setObject: @"NO" forKey: kCIContextUseSoftwareRenderer];
    context = [CIContext contextWithOptions:nil];
}
void ScreenCaptureMac::setFs( int fs )
{
    m_fs = fs;
}
void ScreenCaptureMac::setDisplayID( int displayID )
{
    m_displayID = displayID;
}

void ScreenCaptureMac::setCallback( IVideoCallback* callback )
{
    m_cb = callback;
}

int ScreenCaptureMac::prepare( )
{
    //获取显示器列表
    CGDirectDisplayID display_ids[10];
    uint32_t found_displays = 0;
    
    CGError err = CGGetActiveDisplayList(10, display_ids, &found_displays );
    if( kCGErrorSuccess != err )
    {
        printf("Error: failed to retrieve a list of active displays \n");
        return -1;
    }
    
    if( 0 == found_displays )
    {
        printf("Error: we didn't find any active display.\n");
        return -2;
    }
    
    for( uint32_t i = 0 ; i < found_displays; ++i){
        Display* display = new Display();
        DisplayInfo* info = new  DisplayInfo();
        info->m_id = display_ids[i];
        std::stringstream ss;
        ss<<"Monitor "<<i;
        display->info = (void*)info;
        display->name= ss.str();
        printf("Monitor %d, id:%d\n", i , display_ids[i]);
        displays.push_back( display );
    }
    return 0;
}

int ScreenCaptureMac::shutdown()
{
    if( NULL != stream_ref )
    {
        CFRelease( stream_ref);
        stream_ref = NULL;
    }
    
    for( size_t i = 0 ; i < displays.size(); ++i)
    {
        DisplayInfo* info = static_cast<DisplayInfo*>(displays[i]->info);
        if( NULL == info ){
            printf("Error, failed to cast back DisplayInfo\n");
        }
        else{
            delete info;
        }
        delete displays[i];
    }
    displays.clear();
    return 0;
}

bool ScreenCaptureMac::isStarted()
{
    return m_bStarted;
}

CFArrayRef CreateWindowListWithExclusion( CGWindowID window_to_exclude);
CGRect GetExcludedWindowPixelBounds( CGWindowID window,  float dip_to_pixel_scale );
CGImageRef CreateExcludedWindowRegionImage(const CGRect& pixel_bounds,
float dip_to_pixel_scale,
                                           CFArrayRef window_list );

CGImageRef CreateExcludedWindowRegionImage( CGWindowID wnd )
{
    MacDesktopConfig config = MacDesktopConfig::GetCurrent();
    CGRect rect = GetExcludedWindowPixelBounds( wnd,  config.dip_to_pixel_scale );
    CFArrayRef window_list = CreateWindowListWithExclusion( wnd );
    //如果超出屏幕的部分，不要拷贝哟
    CGImageRef img = CreateExcludedWindowRegionImage( rect, config.dip_to_pixel_scale, window_list );
    return img;
}



int ScreenCaptureMac::configure( Settings setting)
{

    MacDesktopConfig config = MacDesktopConfig::GetCurrent();
    m_displayID = setting.displayIndex;
    DisplayInfo* info = static_cast<DisplayInfo*>(displays[setting.displayIndex]->info);
    if( NULL == info )
    {
        printf("Error, cast DisplayInfo\n");
        return -1;
    }
    
    if( NULL != stream_ref)
    {
        if( true == isStarted() )
        {
            if( 0 != stop())
            {
                printf("We're reconfiguring/setupping the display stream but we were captureing; stopping failed. Not supposed to happen; and you may leak memory here. We continue capturing though.\n");
            }
        }
        
        CFRelease( stream_ref );
        stream_ref = NULL;
    }
    
    uint32_t pixel_format = 'BGRA';
//    switch (settings.pixel_format) {
//         case SC_420F: {
//           pixel_format = '420f';
//           break;
//         }
//         case SC_420V: {
//           pixel_format = '420v';
//           break;
//         }
//         case SC_BGRA: {
//           pixel_format = 'BGRA';
//           break;
//         }
//         case SC_L10R: {
//           pixel_format = 'l10r';
//           break;
//         }
//         default: {
//           printf("Error: unsupported pixel format; cannot configure display stream.\n");
//           return -2;
//         }
//    }
    
    /* @todo > WE DON'T WANT TO MAKE THIS THE RESPONSIBILITY OF AN IMPLEMENTATION! */
//    pixel_buffer.user = user;

    
    
    void* keys[2];
    void* values[2];
    
    CFDictionaryRef opts;
    keys[0] = (void*) kCGDisplayStreamShowCursor;
    values[0] = (void*) kCFBooleanTrue;
    opts = CFDictionaryCreate(kCFAllocatorDefault, (const void **) keys, (const void **) values, 1, NULL, NULL);
 
//    int outWidth = config.displays[ m_displayID ].pixel_bounds.size.width;
//    int outHeight = config.displays[ m_displayID ].pixel_bounds.size.height;
    
    int outWidth = config.displays[ m_displayID ].bounds.size.width;
    int outHeight = config.displays[ m_displayID ].bounds.size.height;
    
    //kCGDisplayStreamMinimumFrameTime
//    CGWindowListCreateImageFromArray
//    /*!
//     @function CGDisplayStreamCreateWithDispatchQueue
//     @abstract Creates a new CGDisplayStream intended to be serviced by a block handler
//     @discussion This function creates a new CGDisplayStream that is to be used to get a stream of frame updates
//     from a particular display.
//     @param display The CGDirectDisplayID to use as the source for generated frames
//     @param outputWidth The output width (in pixels, not points) of the frames to be generated.  Must not be zero.
//     @param outputHeight The output height (in pixels, not points) of the frames to be generated.  Must not be zero.
//     @param pixelFormat The desired CoreVideo/CoreMedia-style pixel format of the output IOSurfaces
//     @param properties Any optional properties of the CGDisplayStream
//     @param queue The dispatch_queue_t that will be used to invoke the callback handler.
//     @param handler A block that will be called for frame deliver.
//     @result The new CGDisplayStream object.
//    */
//    CG_EXTERN CGDisplayStreamRef __nullable CGDisplayStreamCreateWithDispatchQueue(CGDirectDisplayID display,
//        size_t outputWidth, size_t outputHeight, int32_t pixelFormat, CFDictionaryRef __nullable properties,
//        dispatch_queue_t  queue, CGDisplayStreamFrameAvailableHandler __nullable handler)
//        CG_AVAILABLE_STARTING(10.8);
    stream_ref = CGDisplayStreamCreateWithDispatchQueue( info->m_id,
                                                        outWidth,
                                                        outHeight,
                                                        pixel_format,
                                                        (__bridge CFDictionaryRef)(@{(__bridge NSString *)kCGDisplayStreamShowCursor : @YES,
                                                        (__bridge NSString*)kCGDisplayStreamMinimumFrameTime: @(1.0f/25.0f)}),
                                                        dq,
                                                        ^(CGDisplayStreamFrameStatus status,    /* kCGDisplayStreamFrameComplete, *FrameIdle, *FrameBlank, *Stopped */
                                                        uint64_t time,                        /* Mach absolute time when the event occurred. */
                                                        IOSurfaceRef frame,                   /* opaque pixel buffer, can be backed by GL, CL, etc.. This may be NULL in some cases. See the docs if you want to keep access to this. */
                                                        CGDisplayStreamUpdateRef ref)
                                                        {
        if( kCGDisplayStreamFrameStatusFrameComplete == status
        && NULL != frame )
        {
            
            m_cb->onFrame( (void*)frame );
//            IOSurfaceLock( frame, kIOSurfaceLockReadOnly, NULL );
//            size_t plane_count = IOSurfaceGetPlaneCount( frame );
//
////            UICreateCG
//            if( 2 == plane_count )
//            {
//                pixel_buffer.plane[0] = (uint8_t*)IOSurfaceGetBaseAddressOfPlane(frame, 0);
//                pixel_buffer.stride[0] = IOSurfaceGetBytesPerRowOfPlane(frame, 0);
//                pixel_buffer.plane[1] = (uint8_t*)IOSurfaceGetBaseAddressOfPlane(frame, 1);
//                pixel_buffer.stride[1] = IOSurfaceGetBytesPerRowOfPlane(frame, 1);
//
//            }
//            else if( 0 == plane_count )
//            {
//                pixel_buffer.plane[0] = (uint8_t*)IOSurfaceGetBaseAddress(frame);
//                pixel_buffer.stride[0] = IOSurfaceGetBytesPerRow(frame);
//
//
//                CIImage* img = [[CIImage alloc] initWithIOSurface:frame];
//
//
//            }
//
//            {
//                //测试帧率
//                static int frameCount = 0;
//                static double startDate = [[NSDate date] timeIntervalSince1970] * 1000;
//                double nowData = [[NSDate date] timeIntervalSince1970] * 1000;
//                frameCount++;
//                if (nowData -  startDate >= 1000) {
//                    printf("captureing.....fps:%d\n", frameCount);
//                    frameCount = 0;
//                    startDate = nowData;
//                }
//            }
//
//            if( m_cb )
//            {
//                m_cb->onFrame(pixel_buffer);
//            }
//
//            IOSurfaceUnlock(frame, kIOSurfaceLockReadOnly, NULL);
        }
        
    }
    );
    
    if( NULL == stream_ref )
    {
        printf("Error: create failed\n");
        return -4;
    }
    
    return 0;
    
}
                                                        
int ScreenCaptureMac::getDisplays(std::vector<Display*>& result)
{
    result = displays;
    return 0;
        
}

void ScreenCaptureMac::setExclusiveWindowID( int wid )
{
    m_exclusiveWnd = wid;
}
int ScreenCaptureMac::start()
{
//    CGImageRef img = CreateExcludedWindowRegionImage( m_exclusiveWnd );
//    return 0;
    CGError err = CGDisplayStreamStart( stream_ref );
    
    if( kCGErrorSuccess != err )
    {
        printf("Error: failed to start\n");
        return -1;
    }
    m_bStarted = true;
    return 0;
}

int ScreenCaptureMac::stop()
{
    CGError err = CGDisplayStreamStop(stream_ref);
    
    if (kCGErrorSuccess != err) {
      printf("Error: failed to stop the display stream capturer. CGDisplayStreamStart failed: %d .\n", err);
      return -1;
    }
    m_bStarted = false;
    return 0;
}


int GetWindowId(CFDictionaryRef window) {
  CFNumberRef window_id = reinterpret_cast<CFNumberRef>(
      CFDictionaryGetValue(window, kCGWindowNumber));
  if (!window_id) {
    return 0;
  }

  // Note: WindowId is 64-bit on 64-bit system, but CGWindowID is always 32-bit.
  // CFNumberGetValue() fills only top 32 bits, so we should use CGWindowID to
  // receive the window id.
  CGWindowID id;
  if (!CFNumberGetValue(window_id, kCFNumberIntType, &id)) {
    return 0;
  }

  return id;
}

CFArrayRef CreateWindowListWithExclusion( CGWindowID window_to_exclude)
{
    if( !window_to_exclude )
    {
        return nullptr;
    }
    
    CFArrayRef all_windows =
    CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    if( !all_windows ) return nullptr;
    
    CFMutableArrayRef returned_array = CFArrayCreateMutable( nullptr,  CFArrayGetCount( all_windows), nullptr);
    
    bool bfound = false;
    for( CFIndex i = 0 ; i < CFArrayGetCount( all_windows); ++i )
    {
        CFDictionaryRef window = reinterpret_cast<CFDictionaryRef>(CFArrayGetValueAtIndex(all_windows, i));
        CGWindowID wid = GetWindowId(window);
        if (wid == window_to_exclude) {
          bfound = true;
          continue;
        }
        CFArrayAppendValue(returned_array, reinterpret_cast<void*>(wid));
    }
    
    CFRelease( all_windows );
    //没找到，那么就不用找他的画面了，所以返回空
    if(!bfound )
    {
        CFRelease( returned_array );
        return nullptr;
    }
    return returned_array;
}

CGRect ScaleAndRoundCGRect(const CGRect& rect, float scale) {

  return CGRectMake(static_cast<int>(floor(rect.origin.x * scale)),
                               static_cast<int>(floor(rect.origin.y * scale)),
                               static_cast<int>(ceil( rect.size.width * scale)),
                               static_cast<int>(ceil( rect.size.height * scale)));
}

// Returns the bounds of |window| in physical pixels, enlarged by a small amount
// on four edges to take account of the border/shadow effects.
CGRect GetExcludedWindowPixelBounds( CGWindowID window,  float dip_to_pixel_scale )
{
    // The amount of pixels to add to the actual window bounds to take into
    // account of the border/shadow effects.
    static const int kBorderEffectSize = 20;
    
    CGRect rect;
    CGWindowID ids[1];
    ids[0] = window;
    
    CFArrayRef window_id_array =
        CFArrayCreate(nullptr, reinterpret_cast<const void**>(&ids), 1, nullptr);
    CFArrayRef window_array = CGWindowListCreateDescriptionFromArray(window_id_array);
    
    if (CFArrayGetCount(window_array) > 0) {
      CFDictionaryRef window =
          reinterpret_cast<CFDictionaryRef>(CFArrayGetValueAtIndex(window_array, 0));
      CFDictionaryRef bounds_ref =
          reinterpret_cast<CFDictionaryRef>(CFDictionaryGetValue(window, kCGWindowBounds));
      CGRectMakeWithDictionaryRepresentation(bounds_ref, &rect);
    }
    CFRelease(window_id_array);
    CFRelease(window_array);
    
    rect.origin.x -= kBorderEffectSize;
    rect.origin.y -= kBorderEffectSize;
    rect.size.width += kBorderEffectSize * 2;
    rect.size.height += kBorderEffectSize * 2;
    
    // |rect| is in DIP, so convert to physical pixels.
    return ScaleAndRoundCGRect(rect, dip_to_pixel_scale);
}

CGRect intersectRect( CGRect rect1, CGRect rect2 )
{
    CGFloat left, top, right , bottom;
    left = std::max( rect1.origin.x, rect2.origin.x);
    top = std::max( rect1.origin.y, rect2.origin.y );
    right = std::min( rect1.origin.x + rect1.size.width,  rect2.origin.x+ rect2.size.width );
    bottom = std::min( rect1.origin.y + rect1.size.height,  rect2.origin.y+ rect2.size.height);
    
    return CGRectMake( left , top,  right - left ,  bottom - top );
}
CGImageRef CreateExcludedWindowRegionImage(const CGRect& pixel_bounds,
                                           float dip_to_pixel_scale,
                                           CFArrayRef window_list )
{
    CGRect window_bounds;
    
    // The origin is in DIP while the size is in physical pixels. That's what
    // CGWindowListCreateImageFromArray expects.
    
    window_bounds.origin.x = pixel_bounds.origin.x / dip_to_pixel_scale;
    window_bounds.origin.y = pixel_bounds.origin.y / dip_to_pixel_scale;
    window_bounds.size.width = pixel_bounds.size.width / dip_to_pixel_scale ;
    window_bounds.size.height = pixel_bounds.size.height / dip_to_pixel_scale;
    
    return CGWindowListCreateImageFromArray(window_bounds, window_list, kCGWindowImageDefault | kCGWindowImageNominalResolution );
}

// Copy pixels in the |rect| from |src_place| to |dest_plane|. |rect| should be
// relative to the origin of |src_plane| and |dest_plane|.
void CopyRect(const uint8_t* src_plane,
              int src_plane_stride,
              uint8_t* dest_plane,
              int dest_plane_stride,
              int bytes_per_pixel,
              const CGRect& rect) {
  // Get the address of the starting point.
    const int src_y_offset = src_plane_stride * rect.origin.y;
    const int dest_y_offset = dest_plane_stride * rect.origin.y;
    const int x_offset = bytes_per_pixel * rect.origin.x;
    src_plane += src_y_offset + x_offset;
    dest_plane += dest_y_offset + x_offset;

  // Copy pixels in the rectangle line by line.
    const int bytes_per_line = bytes_per_pixel * rect.size.width;
    const int height = rect.size.height;
    for (int i = 0; i < height; ++i) {
        memcpy(dest_plane, src_plane, bytes_per_line);
        src_plane += src_plane_stride;
        dest_plane += dest_plane_stride;
    }
}


void ScreenCaptureMac::onFrame( void* buffer )
{
    IOSurfaceRef frame = (IOSurfaceRef)buffer;
    
    const uint8_t* display_base_address = 0;
    int src_bytes_per_row = 0;
    
    float dip_to_pixel_scale  = 1;
    
    CGImageRef excluded_image = nil;
    CIImage* result_img = nil;
    
    CIImage* screen_img = [[CIImage alloc] initWithIOSurface:frame ];
    CGRect displayRect;
    CGRect rect;
    CFArrayRef window_list = nil;
    MacDesktopConfig config;
    CGWindowID wnd = m_exclusiveWnd;
    CGFloat width = 0;
    CGFloat height = 0 ;
    if( wnd != 0 )
    {
        config = MacDesktopConfig::GetCurrent();
        dip_to_pixel_scale = config.displays[ m_displayID ].dip_to_pixel_scale;
        displayRect = config.displays[ m_displayID ].pixel_bounds;
        rect = GetExcludedWindowPixelBounds( wnd,  dip_to_pixel_scale  );
        rect = intersectRect( rect, displayRect );
        window_list = CreateWindowListWithExclusion( wnd );
        //如果超出屏幕的部分，不要拷贝哟
        excluded_image = CreateExcludedWindowRegionImage( rect, dip_to_pixel_scale, window_list );
    }
        
    if( excluded_image == nil  )
    {
        IOSurfaceLock( frame, kIOSurfaceLockReadOnly, NULL );
        result_img = [[CIImage alloc] initWithIOSurface: frame ];
        width = IOSurfaceGetWidth( frame );
        height = IOSurfaceGetHeight( frame );
        IOSurfaceUnlock(frame, kIOSurfaceLockReadOnly, NULL);
    }
    else{
        IOSurfaceLock( frame, kIOSurfaceLockReadOnly, NULL );
        uint8* plane= (uint8_t*)IOSurfaceGetBaseAddress(frame);
        int stride = IOSurfaceGetBytesPerRow(frame);
        int size = IOSurfaceGetAllocSize( frame );
        width = IOSurfaceGetWidth( frame );
        height = IOSurfaceGetHeight( frame );

        NSData* data = [[NSData alloc] initWithBytes:plane length:size ];
        IOSurfaceUnlock(frame, kIOSurfaceLockReadOnly, NULL);
        

        
        //找出window相对于display的坐标
        CGRect rectRelativeToDisplay = rect;
        rect.origin.x -= displayRect.origin.x;
        rect.origin.y -= displayRect.origin.y;
        
        rectRelativeToDisplay.origin.x /= dip_to_pixel_scale;
        rectRelativeToDisplay.origin.y /= dip_to_pixel_scale;
        rectRelativeToDisplay.size.width /= dip_to_pixel_scale;
        rectRelativeToDisplay.size.height /= dip_to_pixel_scale;
        

        
        CGDataProviderRef provider = CGImageGetDataProvider(excluded_image);
        CFDataRef excluded_image_data =  CGDataProviderCopyData(provider);
        display_base_address = CFDataGetBytePtr(excluded_image_data);
        src_bytes_per_row = CGImageGetBytesPerRow(excluded_image);
        
        //获取的图片可能小于坐标size
        int imgWidth = CGImageGetWidth(excluded_image);
        int imgHeight = CGImageGetHeight(excluded_image);
        
        CGRect rect_to_copy = CGRectMake(0,0, imgWidth, imgHeight );
        
        if( CGImageGetBitsPerPixel( excluded_image)/8 == 4 )
         {
             uint8_t* begin = (uint8_t*)[data bytes];

             int bytePerPix = 4;
             uint8_t* destStartPos = begin +
             int(rectRelativeToDisplay.origin.y * stride)+ int(rectRelativeToDisplay.origin.x) * bytePerPix;
             //进行拷贝啦
             CopyRect( display_base_address,
                      src_bytes_per_row,
                      destStartPos,
                      stride,
                      bytePerPix,//DesktopFrame::kBytesPerPixel,
                      rect_to_copy
                      );
         }
        
        result_img = [[CIImage alloc] initWithBitmapData:data
        bytesPerRow:stride
               size: CGSizeMake( width, height )
             format:kCIFormatBGRA8
         colorSpace:CGColorSpaceCreateDeviceRGB()];
    }
    
    const void *keys[] = {
        kCVPixelBufferMetalCompatibilityKey,
        kCVPixelBufferIOSurfacePropertiesKey,
        kCVPixelBufferBytesPerRowAlignmentKey,
    };
    const void *values[] = {
        (__bridge const void *)([NSNumber numberWithBool:YES]),
        (__bridge const void *)(@{}),
        (__bridge const void *)(@(32)),
    };
    // 创建pixelbuffer属性
    CFDictionaryRef optionsDictionary = CFDictionaryCreate(NULL, keys, values, 3, NULL, NULL);
    CVPixelBufferRef newPixcelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height , kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, optionsDictionary, &newPixcelBuffer);

    [context render:result_img toCVPixelBuffer:newPixcelBuffer];
    printf("\n");
}
