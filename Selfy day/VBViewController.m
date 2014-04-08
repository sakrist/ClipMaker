//
//  VBViewController.m
//  Selfy day
//
//  Created by Volodymyr Boichentsov on 14/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBViewController.h"
#import "VBSettingViewController.h"
#import "VBPhotoToVideo.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "VBLastVideoViewController.h"

#import "CTAssetsPickerController.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

//#import "VBYoutubeShareViewController.h"
//#import "VBYoutubeActivity.h"

#define VBselfyAlbum @"iSelfie Photo Album"

@interface VBViewController ()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup *selfyGroup;
@property (nonatomic, strong) CTAssetsViewController *vc;

@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic) int fps;

@property (nonatomic, copy) NSArray *assets;

@property (nonatomic, strong) NSArray *mainToolBarItems;
@property (nonatomic, strong) NSArray *mainToolBarItemsWithMovie;


@property (nonatomic, weak) ALAsset *firstAsset;
@property (nonatomic, weak) ALAsset *lastAsset;

@property (nonatomic) VBPhotoToVideo *photoToVideo;

@end

@implementation VBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _takePhoto.layer.borderColor = _takePhoto.tintColor.CGColor;
    _takePhoto.layer.borderWidth = 1.0;
    _takePhoto.layer.cornerRadius = 10;
    
    _fps = 25;
    self.navigationController.delegate = self;
    
    self.mainToolBarItems = [NSMutableArray arrayWithArray:self.toolbarItems];
    
    NSString *moviePath = [[VBPhotoToVideo documentsDirectory] stringByAppendingPathComponent:VB_MOVIE_FILENAME];
    if ([[NSFileManager defaultManager] fileExistsAtPath:moviePath] && !_mainToolBarItemsWithMovie) {
        
        UIBarButtonItem *lastMovieItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"VBMovie"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self action:@selector(lastMovie:)];
        
        NSMutableArray * array = [NSMutableArray arrayWithArray:self.toolbarItems];
        [array insertObject:lastMovieItem atIndex:5];
        [array insertObject:[array firstObject] atIndex:6];
        
        self.mainToolBarItemsWithMovie = array;
        self.toolbarItems = self.mainToolBarItemsWithMovie;
    }
    
    [self checkAlbumAvailability];
    
    [_selfyGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == self || _vc == viewController) {
        [self viewWillAppear:animated];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_mainToolBarItemsWithMovie && _mainToolBarItems) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME]]) {
            _vc.toolbarItems = _mainToolBarItemsWithMovie;
        } else {
            _vc.toolbarItems = _mainToolBarItems;
        }
    }
   
}

#pragma mark - show album

- (ALAssetsLibrary *) assetsLibrary {
    if (_assetsLibrary) {
        return _assetsLibrary;
    }
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    return _assetsLibrary;
}

- (void) checkAlbumAvailability {

    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Couldn't Access Photo Album"
                                                            message:@"Please go to Settings ⇨ Privacy ⇨ Photos to allow Selfy save photos to your library."
                                                           delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        
        [self.navigationController setToolbarHidden:YES animated:YES];
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
        ((CTAssetsPickerController*)self.navigationController).delegate = self;

        [self.navigationController setToolbarHidden:NO animated:NO];
        self.navigationController.toolbarItems = self.toolbarItems;
        
        [self.navigationController pushViewController:_vc animated:NO];
        _vc.navigationItem.hidesBackButton = YES;
        _vc.navigationItem.title = @"iSelfie";
        
        
        _vc.navigationItem.rightBarButtonItem = nil;
        _vc.collectionView.allowsMultipleSelection = NO;
        _vc.collectionView.allowsSelection = NO;
        [_vc setToolbarItems:self.toolbarItems];
    }
}


#pragma mark - create selfie video

- (IBAction) createSelfyVideo:(id)sender {
    
    
    _vc.navigationItem.prompt = @"Please select first photo of range.";
    _vc.collectionView.allowsSelection = YES;
    _vc.collectionView.allowsMultipleSelection = YES;
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(cancelSelection)];
    _vc.navigationItem.rightBarButtonItem = cancel;
    _vc.navigationItem.leftBarButtonItem = nil;
    
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                             style:UIBarButtonItemStylePlain target:self action:@selector(createVideo)];
    
    
    [_vc.navigationController setToolbarHidden:YES animated:YES];
    
    _vc.toolbarItems = @[[_mainToolBarItems objectAtIndex:0], item, [_mainToolBarItems objectAtIndex:0]];
    
}

- (void) createVideo {
    
    UIProgressView *progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 290, 40)];
    [progressBar setProgressViewStyle:UIProgressViewStyleBar];
    UIBarButtonItem *itemProgress = [[UIBarButtonItem alloc] initWithCustomView:progressBar];
    
    _vc.toolbarItems = @[itemProgress];
    
    
    _fps = (int)[[NSUserDefaults standardUserDefaults] floatForKey:@"fps"];
    
    NSArray *items = [_vc.collectionView indexPathsForSelectedItems];
    NSInteger min = [_selfyGroup numberOfAssets];
    NSInteger max = 0;
    for (NSIndexPath *path in items) {
        NSInteger v = [path indexAtPosition:1];
        min = MIN(v, min);
        max = MAX(v, max);
    }
    
    
    NSMutableArray * images = [[NSMutableArray alloc] init];
    [_selfyGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        // Checking if group isn't empty
        if (! result) return;
        
        if (index >= min  && index <= max) {
            [images addObject:result];
        }
    }];

    NSString *path = [VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME];

    if (_photoToVideo == nil) {
        _photoToVideo = [[VBPhotoToVideo alloc] init];
    }
    
    __weak VBPhotoToVideo *b_photoToVideo = _photoToVideo;
    __weak UIProgressView *b_progressBar = progressBar;
    __weak VBViewController *b_controller = self;
    
    [_photoToVideo writeImagesAsMovie:images toPath:path fps:_fps progressBlock:^(float progress) {
        [b_progressBar setProgress:progress];
    }];
    
    [_photoToVideo setComplitionBlock:^(BOOL done) {
        if (done) {
            [b_controller cancelSelection];
            [b_controller lastMovie:nil];
        } else {
            [b_controller cancelSelection];
            [[[UIAlertView alloc] initWithTitle:nil message:@"Error while creating video, please try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }];
    
    NSOperationQueue *que = [[NSOperationQueue alloc] init];
    [que setMaxConcurrentOperationCount:1];
    
    
    NSMutableArray *arrayOperations = [NSMutableArray array];
    for (int i = 0, len = (int)[images count]; i < len; i++) {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            [b_photoToVideo writeAssetAt:i];
        }];
        [arrayOperations addObject:op];
    }
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [b_photoToVideo finishing];
        b_controller.photoToVideo = nil;
    }];
    [arrayOperations addObject:op];
    
    [que addOperations:arrayOperations waitUntilFinished:NO];
    
}

- (void) cancelSelection {
    _photoToVideo.stopPhotoToVideo = YES;
    
    _vc.navigationItem.prompt = nil;
    _vc.navigationItem.rightBarButtonItem = nil;
    _vc.collectionView.allowsSelection = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME]]) {
        _vc.toolbarItems = _mainToolBarItemsWithMovie;
    } else {
        _vc.toolbarItems = _mainToolBarItems;
    }
    
    _firstAsset = nil;
    _lastAsset = nil;
    if (_vc.navigationController.toolbarHidden) {
        [_vc.navigationController setToolbarHidden:NO animated:YES];
    }
}




#pragma mark -  CTAssetsPickerControllerDelegate

- (void) assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(ALAsset *)asset {
    if (_firstAsset == nil) {
        _firstAsset = asset;
        _vc.navigationItem.prompt = @"Please select last photo of range.";
    } else if (_lastAsset == nil) {
        _lastAsset = asset;
        _vc.navigationItem.prompt = nil;
        [_vc.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void) assetsPickerController:(CTAssetsPickerController *)picker didDeselectAsset:(ALAsset *)asset {
    if (asset == _firstAsset) {
        _firstAsset = nil;
        _vc.navigationItem.prompt = @"Please select first photo of range.";
    } else if (asset == _lastAsset) {
        _lastAsset = nil;
        _vc.navigationItem.prompt = @"Please select last photo of range.";
        [_vc.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {}

#pragma mark - Last Video

- (void) lastMovie:(id)sender {
    NSLog(@"push");

    VBLastVideoViewController *controller = [[VBLastVideoViewController alloc] initWithNibName:@"VBLastVideoViewController"
                                                                                        bundle:nil];
    controller.title = @"Created Video";
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (void) relastVideo {
    [self.navigationController popViewControllerAnimated:NO];
    VBLastVideoViewController *controller = [[VBLastVideoViewController alloc] initWithNibName:@"VBLastVideoViewController"
                                                                                        bundle:nil];
    controller.title = @"Created Video";
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:NO];
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"frontCamera"]) {
        picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
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
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    picker.delegate = nil;
    picker          = nil;
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
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
//            NSLog(@"*** URL %@ | %@ || type: %@ ***", assetURL, [assetURL absoluteString], [assetURL class]);
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

#pragma mark -

- (void) didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
