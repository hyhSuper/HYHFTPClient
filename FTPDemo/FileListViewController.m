//
//  FileListViewController.m
//  FTPDemo
//
//  Created by Allan on 16/11/7.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "FileListViewController.h"
#import "FTPClientManager.h"

@interface FileListViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)UITextField *urlText;
@property(nonatomic,strong)NSArray *dataArray;
@end

@implementation FileListViewController

-(instancetype)initWithDirectory:(NSString*)directory{
    self = [super init];
    if (self) {
        [[FTPClientManager shareManager] listDirectory:directory];
    }
    return self;
}
-(id)init{
    self = [super init];
    if (self) {
        [[FTPClientManager shareManager] listDirectory:nil];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"文件列表";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    
    self.urlText = [[UITextField alloc]initWithFrame:CGRectMake(10, 10, 394, 40)];
    
    [self.urlText setBorderStyle:UITextBorderStyleRoundedRect];
    
    UIView *bgview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    [bgview addSubview:self.urlText];
    
    self.tableView.tableHeaderView = bgview;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fileList:) name:kFileListDirectoryNotification object:nil];
    
    
    
//    self.dataArray = @[@"listFile",@"upload",@"download",@"creatDir"];
}

-(void)fileList:(NSNotification*)notification{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataArray = [notification.userInfo objectForKey:FileList];
        [self.tableView reloadData];
    });
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark-UITableViewDataSoure
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    FileModel *fileModel = self.dataArray[indexPath.row];
    cell.textLabel.text = fileModel.kName;
    return cell;
}

#pragma mark-UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView  deselectRowAtIndexPath:indexPath animated:YES];
    //发送ftp请求
//    [[YDFTPClient shareClient] sendRAWCommand:self.urlText.text];
    
    FileModel *fileModel = self.dataArray[indexPath.row];
    if (fileModel.isDirectory) {
        NSString *directory = [[FTPClientManager shareManager].currentDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",fileModel.kName]];
        FileListViewController *vc = [[FileListViewController alloc]initWithDirectory:directory];
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"删除");
        }];

        
        UIAlertAction *downlAction= [UIAlertAction actionWithTitle:@"下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"下载");
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];

        [alertController addAction:cancelAction];
        [alertController addAction:downlAction];
        [alertController addAction:deleteAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(UITableView*)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
