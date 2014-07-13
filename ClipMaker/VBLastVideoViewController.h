//
//  VBLastVideoViewController.h
//  ClipMaker
//
//  Created by Volodymyr Boichentsov on 22/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VBLastVideoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak) IBOutlet UITableView *tableView;
@property (weak) IBOutlet UIView *videoView;

@end
