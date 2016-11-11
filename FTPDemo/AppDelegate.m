//
//  AppDelegate.m
//  FTPDemo
//
//  Created by Allan on 16/11/7.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "AppDelegate.h"
#import "FileListViewController.h"
#import "UploadTableViewController.h"
#import "DownloadTableViewController.h"
#import "CreatDirViewController.h"
#import "FTPClientManager.h"



@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self configTableBar];
    [FTPClientManager shareManager];
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)configTableBar{
    
    UITabBarController *bar = [[UITabBarController alloc]init];
    
    FileListViewController *vc1 = [[FileListViewController alloc]init];
    UploadTableViewController *vc2 = [[UploadTableViewController alloc]init];
    DownloadTableViewController *vc3 = [[DownloadTableViewController alloc]init];
    CreatDirViewController *vc4 = [[CreatDirViewController alloc]init];
    
    UINavigationController *nav1 = [[UINavigationController alloc]initWithRootViewController:vc1];
    UINavigationController *nav2 = [[UINavigationController alloc]initWithRootViewController:vc2];
    UINavigationController *nav3 = [[UINavigationController alloc]initWithRootViewController:vc3];
    UINavigationController *nav4 = [[UINavigationController alloc]initWithRootViewController:vc4];
    [bar setViewControllers:@[nav1,nav2,nav3,nav4]];
    
    self.window.rootViewController =bar;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
