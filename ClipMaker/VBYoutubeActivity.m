//
//  VBYoutubeActivity.m
//  Selfy
//
//  Created by Volodymyr Boichentsov on 18/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBYoutubeActivity.h"

@implementation VBYoutubeActivity

- (NSString *)activityType
{
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
	return @"YouTube";
}

- (UIImage *)activityImage
{
	return [UIImage imageNamed:@"Youtube_icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{

    BOOL can = NO;
    if ([activityItems count] > 0) {
        
        for (id object in activityItems) {
            if ([object isKindOfClass:[NSURL class]]) {
                NSString *ext = [((NSURL*)object) pathExtension];
                if ([ext isEqualToString:@"mov"] || [ext isEqualToString:@"mp4"]) {
                    can = YES;
                }
            }
        }
    
    }
    
	return can;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
//			_URL = activityItem;
		}
	}
}

- (void)performActivity
{
	BOOL completed = NO;
    
	[self activityDidFinish:completed];
}

@end
