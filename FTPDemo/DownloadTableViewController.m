//
//  DownloadTableViewController.m
//  FTPDemo
//
//  Created by Allan on 16/11/9.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "DownloadTableViewController.h"
#import "FTPClientManager.h"
@interface DownloadTableViewController ()
@property (nonatomic,strong)NSArray *dataArray;
@end

@implementation DownloadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"下载列表";


}
-(void)viewWillAppear:(BOOL)animated{
    self.dataArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:FTPDownLoadDir error:nil];
    
    [self.tableView reloadData];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

     

    
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"download"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"download"];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    NSString *localString = [NSString stringWithFormat:@"%@/%@",FTPDownLoadDir, self.dataArray[indexPath.row]];
    NSString *remotePath = [NSString stringWithFormat:@"//Users/allan/Desktop/%@", self.dataArray[indexPath.row]];
    [[FTPClientManager shareManager]uploadFile:localString remoteDirectory:remotePath progress:^(NSInteger receviedByes, NSInteger totalByes) {
        WLLog(@"receviedByes = %ld",(long)receviedByes);
    } handleComplication:^(BOOL isSuccess) {
        
    }];
    
}


@end
