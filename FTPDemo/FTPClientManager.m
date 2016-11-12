//
//  FTPClientManager.m
//  FTPDemo
//
//  Created by Allan on 16/11/10.
//  Copyright © 2016年 Allan. All rights reserved.
//
#define kFTPServer @"192.168.11.109"
#define kFTPPort @"21"
#define kFTPUsername @"Allan"
#define kFTPpassword @"1"


#import "FTPClientManager.h"

@implementation FTPClientManager
+(instancetype)shareManager{
    static FTPClientManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager==nil) {
            manager = [[self alloc]init];
        }
    });
    return manager;
}
-(id)init{
    self = [super init];
    if (self) {
        self.client = [[FTPClient alloc]initWithServer:kFTPServer user:kFTPUsername password:kFTPpassword port:kFTPPort];
        self.client.delegate = (id<FTPManagerDelegate>)self;
        [self.client connect];
    }
    return self;
}
-(void)listRootDirectoy{
    [self.client connect];
}

-(void)listDirectory:(NSString*)directory{
     self.currentDirectory = directory;
    [self.client connect];
}


- (void)ftpUploadFinishedWithSuccess:(BOOL)success{
    
}

- (void)ftpDownloadFinishedWithSuccess:(BOOL)success{
    
}

- (void)directoryListingFinishedWithSuccess:(NSArray *)arr{
    
//    WLLog(@"文件列表arr.cout = %@",arr);
    NSMutableArray *fileArray =[NSMutableArray array];
    for (int i = 0 ; i<arr.count; i++) {
        FileModel *file = [[FileModel alloc]initWith:arr[i]];
        [fileArray addObject:file];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFileListDirectoryNotification object:nil userInfo:@{FileList:fileArray}];
    
}

- (void)ftpError:(NSString *)err{
    WLLog(@"错误原因：%@",err);

}

- (void)serverResponseReceived:(NSString *)lastResponseCode message:(NSString *)lastResponseMessage{
    
    WLLog(@"code = %@,message = %@",lastResponseCode,lastResponseMessage);
    if ([lastResponseMessage containsString:@"CWD"]) {
        [self.client sendRAWCommand:@"LIST"];
    }else if([lastResponseCode containsString:@"257"]){//根目录
        NSArray*stringArray =   [lastResponseMessage componentsSeparatedByString:@" "];
        NSString *directory = stringArray[1];
        self.currentDirectory = [directory substringWithRange:NSMakeRange(1,directory.length-2)];
        [self.client sendRAWCommand:@"LIST"];
        WLLog(@"substre = %@",self.currentDirectory);
    }
    
}

- (void)logginFailed{
    WLLog(@"登录失败");
}

- (void)loggedOn{
    WLLog(@"登录成功");
}

- (void)dataStreamBuildSucess:(FTPClient*)client{
    if(!self.currentDirectory || self.currentDirectory.length<=0){
        [self.client sendRAWCommand:@"PWD"];
    }else{
        [self.client sendChangeWorkDirectory:self.currentDirectory];
    }
}


@end
