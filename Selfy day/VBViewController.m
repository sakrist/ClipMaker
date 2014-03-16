//
//  VBViewController.m
//  Selfy day
//
//  Created by Volodymyr Boichentsov on 14/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "VBViewController.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CTAssetsPickerController.h"

#import "VBSettingViewController.h"

#define VBselfyAlbum @"Selfy Photo Album"

@interface VBViewController ()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup *selfyGroup;
@property (nonatomic, strong) CTAssetsViewController *vc;

@property (nonatomic, copy) NSArray *assets;

@property (nonatomic, strong) NSArray *mainToolBarItems;

@end

@implementation VBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _takePhoto.layer.borderColor = _takePhoto.tintColor.CGColor;
    _takePhoto.layer.borderWidth = 1.0;
    _takePhoto.layer.cornerRadius = 10;
    
    self.mainToolBarItems = self.toolbarItems;
    
    [self checkAlbumAvailability];
    
    [_selfyGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
}

- (void) checkAlbumAvailability {

    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Couldn't Access Photo Album"
                                                            message:@"Please go to Settings ⇨ Privacy ⇨ Photos to allow Selfy save photos to your library."
                                                           delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
    };
    
    __block BOOL albumWasFound = NO;
    
    __weak VBViewController *weakSelf = self;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        // Compare the names of the albums
        if ([VBselfyAlbum compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            // Target album is found
            albumWasFound = YES;
            weakSelf.selfyGroup = group;
            // Album was found, bail out of the method
            *stop = YES;
        }
        
        if (group == nil && !albumWasFound) {
            // Photo albums are over, target album does not exist, thus create it
            
                [self.assetsLibrary addAssetsGroupAlbumWithName:VBselfyAlbum
                                      resultBlock:^(ALAssetsGroup *createdGroup) {
                                      
                                      
                                          [weakSelf showAlbum];
                                      
                                      }
                                     failureBlock:failureBlock];
            // Should be the last iteration anyway, but just in case
            *stop = YES;
        } else {
            [weakSelf showAlbum];
        }
    };
    
    // Search all photo albums in the library
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:enumerationBlock
                      failureBlock:failureBlock];

}

- (void) showAlbum {
    if (!self.assets) {
        self.assets = [[NSMutableArray alloc] init];
    }
    
    if (!_vc && _selfyGroup) {
        self.vc = [[CTAssetsViewController alloc] init];
        self.vc.assetsGroup = _selfyGroup;
//        ((CTAssetsPickerController*)self.navigationController).delegate = self;

        [self.navigationController setToolbarHidden:NO animated:NO];
        self.navigationController.toolbarItems = self.toolbarItems;
        
        [self.navigationController pushViewController:_vc animated:NO];
        _vc.navigationItem.hidesBackButton = YES;
        _vc.navigationItem.title = @"Selfy";
        
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:nil];
        
        _vc.navigationItem.leftBarButtonItem = add;
        _vc.navigationItem.rightBarButtonItem = nil;
        _vc.collectionView.allowsMultipleSelection = NO;
        _vc.collectionView.allowsSelection = NO;
        [_vc setToolbarItems:self.toolbarItems];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ALAssetsLibrary *)assetsLibrary
{
    if (_assetsLibrary) {
        return _assetsLibrary;
    }
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    return _assetsLibrary;
}

#pragma mark - Settings

- (IBAction) settings:(id)sender {
    VBSettingViewController *settingsController = [[VBSettingViewController alloc] initWithNibName:@"VBSettingViewController" bundle:nil];
        [settingsController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:settingsController animated:YES];
}


#pragma mark - take photo

// Take photo
- (IBAction) takePhoto:(id)sender {
    
    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[[UIAlertView alloc] initWithTitle:@"Camera Unavailable"
                                    message:@"Sorry, camera unavailable for the current device."
                                   delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:nil, nil] show];
        return;
    }
    
    // Generate picker
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    // Displays a control that allows the user to choose picture or
    //   movie capture, if both are available:
    //picker.mediaTypes =
    //  [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    // Hides the controls for moving & scaling pictures, or for
    //   trimming movies. To instead show the controls, use YES.
    picker.allowsEditing = NO;
    picker.delegate      = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerController Delegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    picker.delegate = nil;
    picker          = nil;
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Dismiss image picker view
    [self imagePickerControllerDidCancel:picker];
    
    // Manage the media (photo)
    NSString * mediaType = info[UIImagePickerControllerMediaType];
    // Handle a still image capture
    CFStringRef mediaTypeRef = (__bridge CFStringRef)mediaType;
    if (CFStringCompare(mediaTypeRef,
                        kUTTypeImage,
                        kCFCompareCaseInsensitive) != kCFCompareEqualTo)
    {
        CFRelease(mediaTypeRef);
        return;
    }
    CFRelease(mediaTypeRef);
    
    // Manage tasks in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage * imageToSave = nil;
        UIImage * editedImage = (UIImage *)info[UIImagePickerControllerEditedImage];
        if (editedImage) imageToSave = editedImage;
        else imageToSave = (UIImage *)info[UIImagePickerControllerOriginalImage];
        
        UIImage * finalImageToSave = nil;
        /* Modify image's size before save it to photos album
         *
         *  CGSize sizeToSave = CGSizeMake(imageToSave.size.width, imageToSave.size.height);
         *  UIGraphicsBeginImageContextWithOptions(sizeToSave, NO, 0.f);
         *  [imageToSave drawInRect:CGRectMake(0.f, 0.f, sizeToSave.width, sizeToSave.height)];
         *  finalImageToSave = UIGraphicsGetImageFromCurrentImageContext();
         *  UIGraphicsEndImageContext();
         */
        finalImageToSave = imageToSave;
        
        // The completion block to be executed after image taking action process done
        void (^completion)(NSURL *, NSError *) = ^(NSURL *assetURL, NSError *error) {
            if (error) NSLog(@"!!!ERROR,  write the image data to the assets library (camera roll): %@",
                             [error description]);
            NSLog(@"*** URL %@ | %@ || type: %@ ***", assetURL, [assetURL absoluteString], [assetURL class]);
//            // Add new item to |photos_| & table view appropriately
//            NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.photos.count
//                                                         inSection:0];
//            [self.photos addObject:[assetURL absoluteString]];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.tableView insertRowsAtIndexPaths:@[indexPath]
//                                      withRowAnimation:UITableViewRowAnimationFade];
//            });
        };
        
        void (^failure)(NSError *) = ^(NSError *error) {
            if (error == nil) return;
            NSLog(@"!!!ERROR, failed to add the asset to the custom photo album: %@", [error description]);
        };
        
        // Save image to custom photo album
        // The lifetimes of objects you get back from a library instance are tied to
        //   the lifetime of the library instance.
        [self.assetsLibrary saveImage:finalImageToSave
                              toAlbum:VBselfyAlbum
                           completion:completion
                              failure:failure];
    });
}



@end
