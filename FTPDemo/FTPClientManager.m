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

typedef void(^FileListBlock)(NSArray*fileList);
typedef void(^Complication)(BOOL isSuccess);
@interface FTPClientManager ()

@property(nonatomic,strong)FileListBlock   fileListBlock;
@property(nonatomic,copy)NSString *currentDirectory;
@property(nonatomic,copy)NSString *downloadFilePath;
@property(nonatomic,strong)Complication  downloadComplication;
@property(nonatomic,strong)Complication  uploadComplication;

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
    self.client.currentAction = FMCurrentActionFileList;
//    if ([self.client checkConnect]) {
//        [self.client sendRAWCommand:[NSString stringWithFormat:@"CWD %@",directory]];
//    }else{
//    }
    [self.client connect];

    self.fileListBlock = blcok;
}

-(void)deletFile:(NSString*)remoteFilePath
{
    self.client.currentAction = FMCurrentActionDeleteFile;
    self.client.deletRemotePath = remoteFilePath;
    [self.client connect];

}

-(void)createRemoteDirectory:(NSString*)directoryPath
{
    self.client.currentAction = FMCurrentActionCreateNewFolder;
    
    self.client.creatNewDirectoyPath = directoryPath;
    
    [self.client connect];

}



-(void)downloadfile:(NSString*)remotePath localPath:(NSString*)localPath progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication{
    
    self.client.currentAction = FMCurrentActionDownloadFile;
    self.downloadFilePath = remotePath;
    self.client.downloadLoaclPath = localPath;
    
    [self.client connect];
    
    self.client.downloadProgress  = progress;
    
    self.downloadComplication = complication;
    
//    self.
    
}

-(void)upload:(NSData*)data remoteDirectory:(NSString*)directory  progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication{
    
    self.client.currentAction = FMCurrentActionUploadFile;
    
    self.client.uploadRemotePath = directory;
    
    self.client.uploadData = data;
    
    self.client.uploadProgress = progress;
    
    self.uploadComplication = complication;

    [self.client connect];

}
-(void)uploadFile:(NSString*)localFilePath remoteDirectory:(NSString*)directory  progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication{
    self.client.currentAction = FMCurrentActionUploadFile;
    
    self.client.uploadRemotePath = directory;
    
    self.client.localFilePath = localFilePath;
    
    self.client.uploadProgress = progress;
    
    self.uploadComplication = complication;
    
    [self.client connect];

}


- (void)ftpUploadFinishedWithSuccess:(BOOL)success{
    if (success) {
        WLLog(@"ftpUploadFinishedWithSuccess");
    }else{
        
    }
    
    self.uploadComplication(success);
    [self.client disconnect];
}

- (void)ftpDownloadFinishedWithSuccess:(BOOL)success{
    WLLog(@"ftpDownloadFinishedWithSuccess");
    
    self.downloadComplication(success);
    
    [self.client disconnect];
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
    [self.client disconnect];

}

- (void)serverResponseReceived:(NSString *)lastResponseCode message:(NSString *)lastResponseMessage{
    
    WLLog(@"code = %@,message = %@",lastResponseCode,lastResponseMessage);
    if(self.client.currentAction == FMCurrentActionFileList){
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
    }else if(self.client.currentAction == FMCurrentActionDownloadFile){
        
        if ([lastResponseCode intValue] == 213) {
            
            
            
            
            
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
    
    if (self.client.currentAction == FMCurrentActionFileList) {
        if (self.currentDirectory.length) {
            [self.client sendRAWCommand:[NSString stringWithFormat:@"CWD %@",self.currentDirectory]];
        }else{
            [self.client sendRAWCommand:@"LIST"];
        }
    }else if(self.client.currentAction == FMCurrentActionDownloadFile){
        [self.client sendRAWCommand:[NSString stringWithFormat:@"RETR %@",self.downloadFilePath]];
    }else if (self.client.currentAction == FMCurrentActionUploadFile){
        
        [self.client sendRAWCommand:[NSString stringWithFormat:@"STOR %@",self.client.uploadRemotePath]];
        
    }else if(self.client.currentAction == FMCurrentActionCreateNewFolder){
        [self.client sendRAWCommand:[NSString stringWithFormat:@"MKD %@",self.client.creatNewDirectoyPath]];
        
    }else if(self.client.currentAction == FMCurrentActionDeleteFile){
        
        [self.client sendRAWCommand:[NSString stringWithFormat:@"DELE %@",self.client.deletRemotePath]];
        
        
    }
    
    
    
    
    
    
    
    
}


@end
