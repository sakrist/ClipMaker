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


+ (void) detectForFaces:(CGImageRef)facePicture orientation:(UIImageOrientation)orientation {
    
    
    CIImage* image = [CIImage imageWithCGImage:facePicture];

    CIContext *context = [CIContext contextWithOptions:nil];                    // 1
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };      // 2
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];                    // 3
    
    int exifOrientation;
    switch (orientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }

    
    opts = @{ CIDetectorImageOrientation :[NSNumber numberWithInt:exifOrientation
                                           ] };

    NSArray *features = [detector featuresInImage:image options:opts];
    
    
    if ([features count] > 0) {
        CIFaceFeature *face = [features lastObject];
        NSLog(@"%@", NSStringFromCGRect(face.bounds));
    }
    
}




+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image orientation:(UIImageOrientation)orientation{
    
    
//    [self detectForFaces:image orientation:orientation];

    
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



- (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path fps:(int)fps progressBlock:(void(^)(float progress))block {
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    ALAsset *asset = [array firstObject];
    
    UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];
    UIImage *first = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]
                                          scale:1.0
                                    orientation:orientation];

    
    CGSize frameSize = first.size;
    
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4
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
    
    CVPixelBufferRef buffer = [VBPhotoToVideo pixelBufferFromCGImage:[first CGImage] orientation:orientation];
    
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (result == NO) { //failes on 3GS, but works on iphone 4
        NSLog(@"failed to append buffer");
    }
    
    if(buffer) {
        CVBufferRelease(buffer);
    }
    
    
    float delta = 1.0/[array count];
    
    
    int i = 0;
    for (ALAsset *asset in array)
    {
        
        if (_stopPhotoToVideo) {
            return;
        }
        
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            
            
            int s = 25/fps;
            
            CMTime frameTime = CMTimeMake(s, 25);
            CMTime lastTime = CMTimeMake(i, 25);
            
            i += s;
            
            CMTime presentTime = CMTimeAdd(lastTime, frameTime);
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            
            CGFloat width = CGImageGetWidth(iref);
            CGFloat height = CGImageGetHeight(iref);

            BOOL recreate = NO;
            CGContextRef bitmap = NULL;
            if (frameSize.width != height && frameSize.height != width) {
                
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                bitmap = CGBitmapContextCreate(NULL, frameSize.width, frameSize.height, 8, 4 * frameSize.width, colorSpace, kCGImageAlphaPremultipliedFirst);
                CGContextDrawImage(bitmap, CGRectMake(0, 0, frameSize.width, frameSize.height), iref);
                iref = CGBitmapContextCreateImage(bitmap);
                recreate = YES;
            }
            
            
            UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];

            buffer = [VBPhotoToVideo pixelBufferFromCGImage:iref orientation:orientation];
            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (recreate) {
                CGContextRelease(bitmap);
                CGImageRelease(iref);

            }
            
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(delta*i);
        });
        
    }
    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
    }];
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);

    
    
}

@end
