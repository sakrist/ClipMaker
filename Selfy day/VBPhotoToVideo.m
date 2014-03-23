//
//  VBPhotoToVideo.m
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBPhotoToVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface VBPhotoToVideo () {
    float _deltaProgress;
    int _time;
    int _deltaTime;
    int _currentIndex;
    CGSize frameSize;
}

@property (nonatomic, retain) AVAssetWriter *videoWriter;
@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, retain) AVAssetWriterInput *writerInput;

@property (nonatomic, copy) void (^progressBlock)(float progress);


@end


@implementation VBPhotoToVideo

+ (NSString *) documentsDirectory {
	static NSString* dPath = nil;
	
	if (!dPath) {
		dPath = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	}
	
	return dPath;
}

+ (NSString *) documentsPath:(NSString*)filename {
    return [[VBPhotoToVideo documentsDirectory] stringByAppendingPathComponent:filename];
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




+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image orientation:(UIImageOrientation)orientation  preferSize:(CGSize)pSize{
    
    @autoreleasepool {
        
        
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
        

    if (pSize.width != width && pSize.height != height) {
        width = pSize.width;
        height = pSize.height;
    }
        
    
    CVPixelBufferCreate(kCFAllocatorDefault, width,
                        height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height,
                                                 8, 4*width, rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
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
    
    if (orientation == UIImageOrientationRight || orientation == UIImageOrientationLeft) {
        int t = width;
        width = height;
        height = t;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        
        return pxbuffer;
    }
}



- (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path fps:(int)fps progressBlock:(void(^)(float progress))block {
    
    self.progressBlock = block;
    self.arrayAssets = [NSArray arrayWithArray:array];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    ALAsset *asset = [_arrayAssets firstObject];
    
    UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];
    UIImage *first = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]
                                          scale:1.0
                                    orientation:orientation];

    
    frameSize = first.size;
    
//    3264x2448
//    1920x1080
//    1280x960
    
    if (orientation == UIImageOrientationRight) {
        if (frameSize.height > 1280) {
            frameSize.height = 1280;
            frameSize.width = 960;
        }
    }
        
    if (frameSize.width > 1280) {
        frameSize.width = 1280;
        frameSize.height = 960;
    }
   
    
    NSError *error = nil;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:
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
    
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [_videoWriter addInput:_writerInput];
    
    // fixes all errors
    _writerInput.expectsMediaDataInRealTime = YES;
    
    // Start a session:
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    if (_adaptor.assetWriterInput.readyForMoreMediaData) {
        
        CVPixelBufferRef buffer = [VBPhotoToVideo pixelBufferFromCGImage:[first CGImage] orientation:orientation preferSize:frameSize];
        BOOL result = [_adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
        
        if (result == NO) { //failes on 3GS, but works on iphone 4
            NSLog(@"failed to append buffer");
        }
        
        if(buffer) {
            CVBufferRelease(buffer);
        }
    }
    
    
    _deltaProgress = 1.0/[_arrayAssets count];
    _time = 0;
    _deltaTime = 25/fps;
    
}

- (void) writeAssetAt:(int)index {

    ALAsset *asset = [_arrayAssets objectAtIndex:index];
    _currentIndex = index;
    if (_stopPhotoToVideo) {
        return;
    }
    
    CMTime frameTime = CMTimeMake(_deltaTime, 25);
    CMTime lastTime = CMTimeMake(_time, 25);
    CMTime presentTime = CMTimeAdd(lastTime, frameTime);
    _time += _deltaTime;
    
    if ([self appendAsset:asset time:presentTime size:frameSize]) {
        __weak VBPhotoToVideo *bself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [bself performBlock];
        });
    } else {
        _stopPhotoToVideo = YES;
    }
}

- (void) performBlock {
    _progressBlock(_deltaProgress*_currentIndex);
}


- (BOOL) appendAsset:(ALAsset*)asset time:(CMTime)presentTime size:(CGSize)size {
    if (_adaptor.assetWriterInput.readyForMoreMediaData) {
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        
        
        UIImageOrientation orientation = (UIImageOrientation)[[asset valueForProperty:@"ALAssetPropertyOrientation"] intValue];
        
        CVPixelBufferRef buffer = [VBPhotoToVideo pixelBufferFromCGImage:iref orientation:orientation preferSize:size];
        BOOL result = [_adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
        
        
        if (result == NO) //failes on 3GS, but works on iphone 4
        {
            NSLog(@"failed to append buffer");
            NSLog(@"The error is %@", [_videoWriter error]);
        }
        
        if(buffer) {
            CVBufferRelease(buffer);
        }
        
        return YES;
    } else {
        NSLog(@"not ready append");
        return NO;
    }
}

- (void) finishing {
    
    NSLog(@"finishing");
    
    //Finish the session:
    [_writerInput markAsFinished];
    
    
    [_videoWriter endSessionAtSourceTime:CMTimeMake(_time, 25)];
    [_videoWriter finishWritingWithCompletionHandler:^{

    }];
    
    CVPixelBufferPoolRelease(self.adaptor.pixelBufferPool);
    self.videoWriter = nil;
    self.adaptor = nil;
    self.arrayAssets = nil;
    self.writerInput = nil;
    
    __weak VBPhotoToVideo *bself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [bself performComplition];
    });

}

- (void) performComplition {
    if (_complitionBlock) {
        _complitionBlock(!_stopPhotoToVideo);
        _complitionBlock = nil;
    }
}


#pragma mark - add audio

//- (void) addAudio:(NSString*)audioFilename toVideo:(NSString*)videoFilename {

+ (void) addAudio:(NSURL*)audioURL toVideo:(NSString*)videoFilename {
        
    
    
//    NSURL *audioURL = [NSURL fileURLWithPath:[VBPhotoToVideo documentsPath:audioFilename]];
    NSURL *videoURL = [NSURL fileURLWithPath:[VBPhotoToVideo documentsPath:videoFilename]];
    
    NSString *outputFileName = [NSString stringWithFormat:@"output_%@", videoFilename];
    NSString *outputFilePath = [VBPhotoToVideo documentsPath:outputFileName];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    CMTime nextClipStartTime = kCMTimeZero;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:videoTimeRange
                                   ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:nextClipStartTime
                                     error:nil];
    
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionAudioTrack insertTimeRange:audioTimeRange
                                   ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                    atTime:nextClipStartTime
                                     error:nil];
    
    
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                         presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = @"public.mpeg-4";
    assetExport.outputURL = outputFileUrl;
    
    [assetExport exportAsynchronouslyWithCompletionHandler: ^(void) {

    }];
}




@end
