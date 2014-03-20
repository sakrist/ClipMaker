//
//  UIPlaceHolderTextView.h
//  Selfy
//
//  Created by Volodymyr Boichentsov on 18/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end