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

typedef enum {
    FMCurrentActionUploadFile    = 1,             //上传
    FMCurrentActionCreateNewFolder,        //创建文件夹
    FMCurrentActionFileList,               //文件列表
    FMCurrentActionDownloadFile,           //下载
    FMCurrentActionSOCKET,
    MCurrentActionNone
} FMCurrentAction;


typedef void(^FileListBlock)(NSArray*fileList);

@interface FTPClientManager ()

@property(nonatomic,assign)FMCurrentAction currentAction;
@property(nonatomic,strong)FileListBlock   fileListBlock;
@property(nonatomic,copy)NSString *currentDirectory;
@end

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
    }
    return self;
}

-(void)listDirectory:(NSString*)directory fileBlock:(void(^)(NSArray *fileList))blcok
{
    self.currentDirectory = directory;
    self.currentAction = FMCurrentActionFileList;
//    if ([self.client checkConnect]) {
//        [self.client sendRAWCommand:[NSString stringWithFormat:@"CWD %@",directory]];
//    }else{
//    }
    [self.client connect];

    self.fileListBlock = blcok;
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
    self.fileListBlock(fileArray);
    
}



- (void)ftpError:(NSString *)err{
    WLLog(@"错误原因：%@",err);
    
}

- (void)serverResponseReceived:(NSString *)lastResponseCode message:(NSString *)lastResponseMessage{
    
    WLLog(@"code = %@,message = %@",lastResponseCode,lastResponseMessage);
    if(self.currentAction == FMCurrentActionFileList){
        if([lastResponseCode intValue] == 257){//当前工作目录
            
            if (self.currentDirectory.length) {
                [self.client sendRAWCommand:[NSString stringWithFormat:@"CWD %@",self.currentDirectory]];
            }else{
                NSArray*stringArray =   [lastResponseMessage componentsSeparatedByString:@" "];
                NSString *directory = stringArray[1];
                directory = [directory substringWithRange:NSMakeRange(1,directory.length-2)];
                self.workingDirectory = directory;
                [self.client sendRAWCommand:@"LIST"];
                WLLog(@"substre = %@",directory);
            }
        }else if([lastResponseCode integerValue] == 250){
             [self.client sendRAWCommand:@"LIST"];
        }
    }
    
    
}

- (void)logginFailed{
    WLLog(@"登录失败");
}

- (void)loggedOn{
//    [self.client sendRAWCommand:@"PWD"];
    WLLog(@"登录成功");
}

- (void)dataStreamBuildSucess:(FTPClient*)client{
    
    if (self.currentAction == FMCurrentActionFileList) {
        
//        [self.client sendRAWCommand:@"LIST"];

        
        if (self.currentDirectory.length) {
            [self.client sendRAWCommand:[NSString stringWithFormat:@"CWD %@",self.currentDirectory]];
        }else{
            [self.client sendRAWCommand:@"PWD"];
        }
    }
    
    
    
    
//    if(!self.currentDirectory || self.currentDirectory.length<=0){
//        [self.client sendRAWCommand:@"PWD"];
//    }else{
//        [self.client sendChangeWorkDirectory:self.currentDirectory];
//    }
    
    
    
    
    
}


@end
