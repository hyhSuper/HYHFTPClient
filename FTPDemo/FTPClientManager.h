//
//  FTPClientManager.h
//  FTPDemo
//
//  Created by Allan on 16/11/10.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTPClient.h"
#import "FileModel.h"

#define kFileListDirectoryNotification  @"kFileListDirectoryNotification"
#define FileList  @"filelist"


@interface FTPClientManager : NSObject
@property(nonatomic,strong)FTPClient *client;
@property(nonatomic,strong)NSString *workingDirectory;

+(instancetype)shareManager;

//-(void)listRootDirectoy;

//-(void)requestDiretory:(NSString*)directory;

//-(void)listDirectory:(NSString*)directory;
//文件列表
-(void)listDirectory:(NSString*)directory fileBlock:(void(^)(NSArray *fileList))blcok;

//下载
-(void)downloadfile:(NSString*)remotePath localPath:(NSString*)localPath progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication;

//上传
-(void)upload:(NSData*)data remoteDirectory:(NSString*)directory  progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication;

//
-(void)uploadFile:(NSString*)localFilePath remoteDirectory:(NSString*)directory  progress:(Progress)progress handleComplication:(void(^)(BOOL isSuccess))complication;



@end
