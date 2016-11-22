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

-(void)listDirectory:(NSString*)directory;

-(void)listDirectory:(NSString*)directory fileBlock:(void(^)(NSArray *fileList))blcok;


@end
