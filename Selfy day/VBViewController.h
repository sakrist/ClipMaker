//
//  VBViewController.h
//  Selfy day
//
//  Created by Volodymyr Boichentsov on 14/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTAssetsPickerController.h"

@interface VBViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CTAssetsPickerControllerDelegate>


@property (nonatomic, weak) IBOutlet UIButton *takePhoto;

- (IBAction) settings:(id)sender;

- (IBAction) takePhoto:(id)sender;

@end
