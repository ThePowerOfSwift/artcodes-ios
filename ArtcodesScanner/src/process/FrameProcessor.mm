/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import "FrameProcessor.h"
#import "ImageProcessor.h"
#import "TileThreshold.h"
#import "MarkerDetector.h"
#import "MarkerEmbeddedChecksumDetector.h"
#import "MarkerAreaOrderDetector.h"
#import "MarkerEmbeddedChecksumAreaOrderDetector.h"
#import "ImageBuffers.h"
#import "RgbColourFilter.h"
#import "CmykColourFilter.h"

@interface FrameProcessor()

@property ImageBuffers* buffers;
@property DetectionSettings* settings;

@end

@implementation FrameProcessor

-(void) createPipeline:(NSArray *)pipeline andSettings:(DetectionSettings*) settings
{
	NSMutableArray<ImageProcessor>* newPipeline = [[NSMutableArray<ImageProcessor> alloc] init];
	
	// TODO: Replace this pipeline implementation with something like the Android implementation.
	for(NSString* processor in pipeline)
	{
		// Threshold methods:
		if ([processor isEqualToString:@"tile"])
		{
			[newPipeline addObject:[[TileThreshold alloc] initWithSettings:settings]];
		}
		
		// Detection methods:
		else if ([processor isEqualToString:@"detect"])
		{
			[newPipeline addObject:[[MarkerDetector alloc] initWithSettings:settings]];
		}
		else if ([processor isEqualToString:@"detectEmbedded"])
		{
			[newPipeline addObject:[[MarkerEmbeddedChecksumDetector alloc] initWithSettings:settings]];
		}
		else if ([processor isEqualToString:@"detectEmbeddedOrdered"])
		{
			[newPipeline addObject:[[MarkerEmbeddedChecksumAreaOrderDetector alloc] initWithSettings:settings]];
		}
		else if ([processor isEqualToString:@"detectOrdered"])
		{
			[newPipeline addObject:[[MarkerAreaOrderDetector alloc] initWithSettings:settings]];
		}
		
		// Greyscale methods:
		else if ([processor isEqualToString:@"intensity"])
		{
			// nothing
		}
		
		else if ([processor isEqualToString:@"redFilter"])
		{
			[newPipeline addObject:[[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Red]];
		}
		else if ([processor isEqualToString:@"greenFilter"])
		{
			[newPipeline addObject:[[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Green]];
		}
		else if ([processor isEqualToString:@"blueFilter"])
		{
			[newPipeline addObject:[[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Blue]];
		}
		
		else if ([processor isEqualToString:@"cyanKFilter"])
		{
			[newPipeline addObject:[[CmykColourFilter alloc] initWithSettings:settings andChannel:CMYKChannel_Cyan]];
		}
		else if ([processor isEqualToString:@"magentaKFilter"])
		{
			[newPipeline addObject:[[CmykColourFilter alloc] initWithSettings:settings andChannel:CMYKChannel_Magenta]];
		}
		else if ([processor isEqualToString:@"yellowKFilter"])
		{
			[newPipeline addObject:[[CmykColourFilter alloc] initWithSettings:settings andChannel:CMYKChannel_Yellow]];
		}
		else if ([processor isEqualToString:@"blackKFilter"])
		{
			[newPipeline addObject:[[CmykColourFilter alloc] initWithSettings:settings andChannel:CMYKChannel_Black]];
		}
		
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
															message:@"This experience may use features not available in this version of Artcodes or it might work fine. Check the AppStore for updates."
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		
	}
	
	if ([newPipeline count]==0)
	{
		// No pipeline supplied, use defaults:
		[newPipeline addObject:[[TileThreshold alloc] initWithSettings:settings]];
		[newPipeline addObject:[[MarkerDetector alloc] initWithSettings:settings]];
	}
	
	self.buffers = [[ImageBuffers alloc] init];
	
	self.pipeline = newPipeline;
	self.settings = settings;
}

-(void) captureOutput: ( AVCaptureOutput * ) captureOutput
	didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer
	fromConnection: ( AVCaptureConnection * ) connection
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	CVPixelBufferLockBaseAddress( imageBuffer, 0 );
	
	self.buffers.image = [self asMat:imageBuffer];
	[self rotate:self.buffers.image angle:90 flip:false];
	
	if(self.buffers.overlay.rows == 0)
	{
		self.buffers.overlay = cv::Mat(self.buffers.image.rows, self.buffers.image.cols, CV_8UC4);
	}
	
	for (id<ImageProcessor> imageProcessor in self.pipeline)
	{
		[imageProcessor process:self.buffers];
	}
	
	[self drawOverlay];
	
	//End processing
	CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
}

-(void)drawOverlay
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
	
	NSData *data = [NSData dataWithBytes:self.buffers.overlay.data length:self.buffers.overlay.elemSize()*self.buffers.overlay.total()];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
	CGImage* dstImage = CGImageCreate(self.buffers.overlay.cols, self.buffers.overlay.rows, 8, 8 * self.buffers.overlay.elemSize(), self.buffers.overlay.step, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.overlay!=nil)
		{
			self.overlay.contents = (__bridge id)dstImage;
		}
	
		CGDataProviderRelease(provider);
		CGImageRelease(dstImage);
		CGColorSpaceRelease(colorSpace);
	});
}

-(cv::Mat)asMat:(CVImageBufferRef) imageBuffer
{
	int format_opencv;
	int bufferWidth;
	int bufferHeight;
	size_t bytesPerRow;
    void *bufferAddress;
	OSType format = CVPixelBufferGetPixelFormatType(imageBuffer);
	if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
	{
		format_opencv = CV_8UC1;
		
		bufferAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
		bufferWidth = (int)CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
		bufferHeight = (int)CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
		bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
	}
	else
	{
		// expect kCVPixelFormatType_32BGRA
		format_opencv = CV_8UC4;
		
		bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer);
		bufferWidth = (int)CVPixelBufferGetWidth(imageBuffer);
		bufferHeight = (int)CVPixelBufferGetHeight(imageBuffer);
		bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	}
	
	cv::Mat screenImage = cv::Mat(cv::Size(bufferWidth, bufferHeight), format_opencv, bufferAddress, bytesPerRow);

	if(bufferHeight > bufferWidth)
	{
		return cv::Mat(screenImage, cv::Rect(0, (bufferHeight - bufferWidth) / 2, bufferWidth, bufferWidth));
	}
	else
	{
		return cv::Mat(screenImage, cv::Rect((bufferWidth - bufferHeight) / 2, 0, bufferHeight, bufferHeight));
	}
}

-(void) rotate:(cv::Mat) image angle:(int) angle flip:(bool) flip
{
	angle = ((angle / 90) % 4) * 90;
	
	//0 : flip vertical; 1 flip horizontal
	
	int flip_horizontal_or_vertical = angle > 0 ? 1 : 0;
	if (flip)
	{
		flip_horizontal_or_vertical = -1;
	}
	int number = abs(angle / 90);
	
	for (int i = 0; i != number; ++i)
	{
		cv::transpose(image, image);
		cv::flip(image, image, flip_horizontal_or_vertical);
	}
}

@end