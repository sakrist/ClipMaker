//
//  VBPhotoToVideo.h
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VBPhotoToVideo : NSObject

@property BOOL stopPhotoToVideo;
@property (nonatomic, retain) NSArray *arrayAssets;
@property (nonatomic, copy) void (^complitionBlock)(BOOL done);

+ (NSString *) documentsDirectory;

- (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path fps:(int)fps progressBlock:(void(^)(float progress))block;

- (void) writeAssetAt:(int)index;

- (void) finishing;

@end
