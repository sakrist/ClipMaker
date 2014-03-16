//
//  VBPhotoToVideo.m
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBPhotoToVideo.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>



@implementation VBPhotoToVideo

+ (NSString *) documentsDirectory {
	static NSString* dPath = nil;
	
	if (!dPath) {
		dPath = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	}
	
	return dPath;
}

+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image orientation:(UIImageOrientation)orientation{
    
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    if (orientation == UIImageOrientationRight || orientation == UIImageOrientationLeft) {
        width = CGImageGetHeight(image);
        height = CGImageGetWidth(image);
    }
    
    CVPixelBufferCreate(kCFAllocatorDefault, width,
                        height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                 height, 8, 4*width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGContextSaveGState(context);
    
    
    if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, M_PI_2);
        CGContextTranslateCTM (context, 0, -width);
        
    } else if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, -M_PI_2); // for 90 degree rotation
        CGContextTranslateCTM (context, -height, 0);
        
    } else if (orientation == UIImageOrientationUp) {
        // NOTHING
    } else if (orientation == UIImageOrientationDown) {
        CGContextTranslateCTM (context, width, height);
        CGContextRotateCTM (context, -M_PI);
    }
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



+ (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path fps:(int)fps {
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
//    NSString *documents = [VBPhotoToVideo documentsDirectory];
    
    //NSLog(path);
//    NSString *filename = [documents stringByAppendingPathComponent:[array objectAtIndex:0]];
//    UIImage *first = [UIImage imageWithContentsOfFile:filename];
    
    ALAsset *asset = [array firstObject];
    
    UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];
    UIImage *first = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]
                                          scale:1.0
                                    orientation:orientation];

    
    CGSize frameSize = first.size;
    
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [videoWriter addInput:writerInput];
    
    // fixes all errors
    writerInput.expectsMediaDataInRealTime = YES;
    
    //Start a session:
    [videoWriter startWriting];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[first CGImage] orientation:orientation];
    
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (result == NO) //failes on 3GS, but works on iphone 4
        NSLog(@"failed to append buffer");
    
    if(buffer) {
        CVBufferRelease(buffer);
    }
    
    
    
//    int reverseSort = NO;
    
//    float delta = 1.0/[array count];
    
    
    int i = 0;
    for (ALAsset *asset in array)
    {
        
        
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            
            i++;
            CMTime frameTime = CMTimeMake(1, fps);
            CMTime lastTime = CMTimeMake(i, fps);
            CMTime presentTime = CMTimeAdd(lastTime, frameTime);
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            
            UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];

            
            
            // INSERT IMAGE FOR preview
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIImage *newImg = [UIImage imageWithContentsOfFile:filePath];
//                    [imgscreen setImage:newImg];
//                });
//            });
            
            buffer = [self pixelBufferFromCGImage:iref orientation:orientation];
            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (result == NO) //failes on 3GS, but works on iphone 4
            {
                NSLog(@"failed to append buffer");
                NSLog(@"The error is %@", [videoWriter error]);
            }
            
            if(buffer) {
                CVBufferRelease(buffer);
            }
            
            
        } else {
            NSLog(@"error");
            i--;
        }
//        [self performSelectorOnMainThread:@selector(addprogress) withObject:nil waitUntilDone:YES];
        
    }
    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
    }];
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);

    
    
}

@end
