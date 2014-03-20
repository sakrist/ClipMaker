//
//  VBSettingViewController.h
//  Selfy
//
//  Created by Volodymyr Boichentsov on 16/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VBSettingViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *fpsLabel;

@property (nonatomic, weak) IBOutlet UISlider *sliderFps;
@property (nonatomic, weak) IBOutlet UISwitch *notificatioSwitch;

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

- (IBAction) openSource:(UIButton *)sender;

- (IBAction) changeFps:(UISlider*)sender;

- (IBAction) changeTime:(id)sender;

- (IBAction) enableNotification:(UISwitch*)sender;

@end
