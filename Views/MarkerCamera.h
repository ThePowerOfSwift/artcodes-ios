//
//  ACCamera.h
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import "ExperienceManager.h"
#import "ACODESCameraSettings.h"

@protocol MarkerFoundDelegate;
@class Experience;

@interface MarkerCamera : NSObject<CvVideoCameraDelegate>

@property NSString* mode;
@property (weak) ExperienceManager* experienceManager;

// Keep a strong reference to the camera settings as it will be distroyed and recreated when a new settings file is downloaded (which we replace this reference with when [self start] is called)
@property (strong) ACODESCameraSettings* cameraSettings;

// Mutex
@property bool newFrameAvaliable;
@property bool processingImage1;
@property NSLock *frameLock;

@property NSLock *detectingLock;

@property bool singleThread;
@property bool fullSizeViewFinder;
@property bool raisedTopBorder;


@property bool firstFrame;

- (void) stop;
- (void) start:(UIImageView*)imageView;
- (void)flip:(UIImageView*)imageView;

- (void) processFrame;

@end