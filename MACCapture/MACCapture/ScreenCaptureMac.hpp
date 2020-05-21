//
//  ScreenCaptureMac.hpp
//  MACCapture
//
//  Created by pinky on 2020/5/18.
//  Copyright © 2020 pinky. All rights reserved.
//

#ifndef ScreenCaptureMac_hpp
#define ScreenCaptureMac_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include <CoreGraphics/CGDisplayStream.h>

#define SC_NONE 0

/* Pixel Formats */
#define SC_420V 1                                                /* 2-plane "video" range YCbCr 4:2:0 */
#define SC_420F 2                                                /* 2-plane "full" range YCbCr 4:2:0 */
#define SC_BGRA 3                                                /* Packed Little Endian ARGB8888 */
#define SC_L10R 4                                                /* Packet Little Endian ARGB2101010 */

class Settings{
public:
    Settings();
public:
    int displayIndex;
    
    int pixel_format;
    int output_width;
    int output_height;
};

struct DisplayInfo{
    CGDirectDisplayID m_id;
};
struct Display{
    std::string name;
    void* info;
};

class  IVideoCallback
{
public:
//    virtual void onFrame( char* data,  int size, int width, int height ,int fmt, long long  timestamp) = 0 ;
    virtual void onFrame( void* buffer ) = 0 ;
};

class ScreenCaptureMac : public IVideoCallback
{
public:
    ScreenCaptureMac();
    void setFs( int fs );
    void setDisplayID( int displayID );
    
    void setCallback( IVideoCallback* callback );
    
    int prepare();
    int shutdown();
    
    int configure( Settings setting );
    
    int start();
    int stop();
    
    bool isStarted();
    
    int getDisplays(std::vector<Display*>& result);
    
    void onFrame( void* buffer );
    
    void setExclusiveWindowID( int wid );
    
    
    
private:
    int m_fs;
    int m_displayID;
    int m_pixel_format;
    IVideoCallback* m_cb;
    CGDisplayStreamRef stream_ref;
    dispatch_queue_t dq;
    std::vector<Display*> displays;
    bool m_bStarted;
    
    int m_exclusiveWnd;
};

#endif /* ScreenCaptureMac_hpp */
