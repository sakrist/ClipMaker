//
//  VBPhotoToVideo.h
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VBPhotoToVideo : NSObject

+ (NSString *) documentsDirectory;

+ (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path fps:(int)fps;

@end
