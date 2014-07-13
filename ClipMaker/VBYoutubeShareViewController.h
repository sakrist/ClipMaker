//
//  VBYoutubeShareViewController.h
//  Selfy
//
//  Created by Volodymyr Boichentsov on 17/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VBYoutubeShareViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSString *filePath;



@end
