//
//  VBSettingViewController.m
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBSettingViewController.h"

@interface VBSettingViewController ()

@end

@implementation VBSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"date"];
    if (date) {
        [_datePicker setDate:date];
    }
    
    [_notificatioSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"enableNotify"]];
    [_sliderFps setValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"fps"]];
    [_fpsLabel setText:[NSString stringWithFormat:@"Pictures per second: %d", (int)_sliderFps.value]];
    
    [_scrollView setContentSize:CGSizeMake(320, 800)];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.title = @"Settings";
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) openSource:(UIButton *)sender {
    NSString *zero = @"https://twitter.com/iSelfieApp";

    NSArray *array = @[zero];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[array objectAtIndex:sender.tag]]];
    
}

- (IBAction) changeFps:(UISlider*)sender {

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"fps"];
    
    [_fpsLabel setText:[NSString stringWithFormat:@"Pictures per second: %d", (int)sender.value]];
    
}

- (IBAction) changeTime:(UIDatePicker*)sender {
    
    [[NSUserDefaults standardUserDefaults] setObject:sender.date forKey:@"date"];
    [self enableNotification:_notificatioSwitch];
}

- (IBAction) enableNotification:(UISwitch*)sender {
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"enableNotify"];
    
    if (sender.isOn) {
        
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"date"];
        if (!date) {
            [[NSUserDefaults standardUserDefaults] setObject:_datePicker.date forKey:@"date"];
        }
        
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.repeatInterval = NSDayCalendarUnit;
        [notification setAlertBody:@"Take a photo."];
        [notification setFireDate:_datePicker.date];
        [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];

    } else {
        [[UIApplication sharedApplication] setScheduledLocalNotifications:nil];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
