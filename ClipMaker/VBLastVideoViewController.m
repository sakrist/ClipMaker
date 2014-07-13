//
//  VBLastVideoViewController.m
//  ClipMaker
//
//  Created by Volodymyr Boichentsov on 22/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBLastVideoViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VBPhotoToVideo.h"

@interface VBLastVideoViewController () <MPMediaPickerControllerDelegate>


@property MPMoviePlayerController *playerController;
@property NSURL *audioURL;
@property UIButton *playButton;

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
    picker.prompt						= NSLocalizedString (@"Select song for video", "Prompt in media item picker");
    [self presentViewController:picker animated:YES completion:^{
    }];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    MPMediaItem *item = [[mediaItemCollection items] lastObject];
    self.audioURL = [[item valueForProperty:MPMediaItemPropertyAssetURL] copy];
    
    
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        [self addAudio];
    }];
    
}

- (void) addAudio {
    [VBPhotoToVideo addAudio:_audioURL toVideo:VB_MOVIE_FILENAME complition:^{
    }];
    UIViewController *c = [self.navigationController.viewControllers objectAtIndex:0];
    [c performSelector:@selector(relastVideo)];
}


- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [mediaPicker dismissViewControllerAnimated:YES completion:^{}];
}


- (IBAction) shareVideo:(UIButton*)sender {

    NSString *moviePath;
    
    if (sender.tag == 0) {
        NSString *outputFileName = [NSString stringWithFormat:@"output_%@", VB_MOVIE_FILENAME];
        moviePath = [VBPhotoToVideo documentsPath:outputFileName];
    } else {
        moviePath = [VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME];
    }
    
    
    NSArray * activityItems = @[@"Check out my video %@. Which I made with this app https://appsto.re/i6gY9tV", [NSURL fileURLWithPath:moviePath]];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                           applicationActivities:nil];
    
    [activity setCompletionHandler:^(NSString *activityType, BOOL completed) {
    }];
    
    [self presentViewController:activity animated:YES completion:nil];
}


- (void) createVideoPlayer {
//    [_playerController setContentURL:nil];
//    [_playerController.view removeFromSuperview];
//    self.playerController = nil;
    
    NSURL *movie = [NSURL fileURLWithPath:[VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME]];
    if (_playerController) {
        [_playerController setContentURL:movie];
    } else {
        self.playerController = [[MPMoviePlayerController alloc] initWithContentURL:movie];
        [_playerController.view setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, 320, 300)];
        [_playerController setControlStyle:MPMovieControlStyleNone];
        [_playerController.backgroundView setBackgroundColor:[UIColor clearColor]];
        [_playerController.view setBackgroundColor:[UIColor clearColor]];
        [self.videoView addSubview:_playerController.view];
        [_videoView setFrame:_playerController.view.frame];
        [_playerController setShouldAutoplay:NO];
        [_playerController prepareToPlay];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged)
                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        
        int size = 70;
        
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
        [_playButton setFrame:CGRectMake(125, 120, size, size)];
        [_playButton setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
        [_playButton setTitleColor:[UIColor colorWithRed:0 green:0.49 blue:0.98 alpha:1] forState:UIControlStateNormal];
        _playButton.layer.cornerRadius = size/2;
        [_playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
        
        [_playerController.view addSubview:_playButton];
    }
    
}

- (void) playVideo:(UIButton*)sender {
    [_playButton setHidden:YES];
    [_playerController play];
}

- (void) playbackStateChanged {
    if (_playerController.playbackState == MPMoviePlaybackStatePaused) {
        [_playButton setHidden:NO];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  3;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = @"";
    cell.textLabel.textColor = [UIColor colorWithRed:0 green:0.49 blue:0.98 alpha:1];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Add Audio to Video";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Share Video";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Delete Video";
        cell.textLabel.textColor = [UIColor redColor];
    }

    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        [self addAudioTrack:nil];
    } else if (indexPath.row == 1) {
        [self shareVideo:nil];
    } else if (indexPath.row == 2) {
//        cell.textLabel.text = @"Delete Video";
        [[NSFileManager defaultManager] removeItemAtPath:[VBPhotoToVideo documentsPath:VB_MOVIE_FILENAME] error:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad {

    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self createVideoPlayer];


}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
