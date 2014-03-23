//
//  VBLastVideoViewController.m
//  iSelfie
//
//  Created by Volodymyr Boichentsov on 22/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBLastVideoViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VBPhotoToVideo.h"

@interface VBLastVideoViewController ()

@end

@implementation VBLastVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (IBAction) addAudioTrack:(id)sender {
    
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    picker.delegate						= self;
    picker.allowsPickingMultipleItems	= NO;
    picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    
    MPMediaItem *item = [[mediaItemCollection items] lastObject];
    NSURL *audioURL = [[item valueForProperty:MPMediaItemPropertyAssetURL] copy];
    
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        [VBPhotoToVideo addAudio:audioURL toVideo:VB_MOVIE_FILENAME];
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [mediaPicker dismissViewControllerAnimated:YES completion:^{}];
}


- (IBAction) playVideo:(id)sender {

}

- (IBAction) shareVideo:(UIButton*)sender {

    NSString *moviePath;
    
    if (sender.tag == 0) {
        NSString *outputFileName = [NSString stringWithFormat:@"output_%@", VB_MOVIE_FILENAME];
        moviePath = [VBPhotoToVideo documentsPath:outputFileName];
    } else {
        moviePath = [VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME];
    }
    
    
    NSArray * activityItems = @[@"My iSelfie video. #selfie #iselfie @iSelfieApp", [NSURL fileURLWithPath:moviePath]];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                           applicationActivities:nil];
    
    [activity setCompletionHandler:^(NSString *activityType, BOOL completed) {
    }];
    
    [self presentViewController:activity animated:YES completion:nil];
}





- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
