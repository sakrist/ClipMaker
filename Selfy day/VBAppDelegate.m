//
//  VBAppDelegate.m
//  Selfy day
//
//  Created by Volodymyr Boichentsov on 14/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import "VBAppDelegate.h"

@implementation VBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    float fps = [[NSUserDefaults standardUserDefaults] floatForKey:@"fps"];
    if (fps <= 0 || fps > 30) {
        [[NSUserDefaults standardUserDefaults] setFloat:20 forKey:@"fps"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableNotify"]) {
        
       [[UIApplication sharedApplication] setScheduledLocalNotifications:nil];
        
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"date"];
        
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.repeatInterval = NSDayCalendarUnit;
        [notification setAlertBody:@"Take a photo."];
        [notification setFireDate:date];
        [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [Flurry startSession:FLURRY_APP_ID];
    
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    NSInteger runs = [[NSUserDefaults standardUserDefaults] integerForKey:@"runCount"];
    runs++;
    [[NSUserDefaults standardUserDefaults] setInteger:runs forKey:@"runCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    // Handle the notificaton when the app is running
    NSLog(@"Recieved Notification %@",notif);
    
    
    
}

@end
