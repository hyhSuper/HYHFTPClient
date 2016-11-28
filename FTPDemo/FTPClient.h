//
//  FTPManager.h
//  FTPDemo
//
//  Created by Allan on 16/11/7.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CFNetwork/CFNetwork.h>

typedef enum {
    FMCurrentActionUploadFile    = 1,             //上传
    FMCurrentActionCreateNewFolder,        //创建文件夹
    FMCurrentActionFileList,               //文件列表
    FMCurrentActionDownloadFile,           //下载
    FMCurrentActionDeleteFile,             //删除
    FMCurrentActionSOCKET,
    MCurrentActionNone
} FMCurrentAction;

typedef  void(^Progress)(NSInteger receviedByes,NSInteger totalByes);

@class FTPClient;

@protocol FTPManagerDelegate <NSObject>

- (void)ftpUploadFinishedWithSuccess:(BOOL)success;

- (void)ftpDownloadFinishedWithSuccess:(BOOL)success;

- (void)directoryListingFinishedWithSuccess:(NSArray *)arr;

- (void)dataStreamBuildSucess:(FTPClient*)client;

- (void)ftpError:(NSString *)err;

- (void)serverResponseReceived:(NSString *)lastResponseCode message:(NSString *)lastResponseMessage;

- (void)ftpDataTransferComplete;


- (void)logginFailed;

- (void)loggedOn;


@end

@interface FTPClient : NSObject<NSStreamDelegate>

@property (nonatomic, assign) id<FTPManagerDelegate>       delegate;

@property (nonatomic, assign) int lastResponseInt;

@property (nonatomic, strong, readwrite) NSMutableArray *  listEntries;

@property (nonatomic, assign)FMCurrentAction currentAction;

@property (nonatomic,  copy)NSString *downloadLoaclPath;
@property (nonatomic,  copy)NSString *uploadRemotePath;
@property (nonatomic,  copy)NSString *creatNewDirectoyPath;
@property (nonatomic,  copy)NSString *deletRemotePath;

@property (nonatomic,strong)NSData   *uploadData;

@property (nonatomic,  copy)NSString *localFilePath;

@property (nonatomic,strong)Progress downloadProgress;

@property (nonatomic,strong)Progress uploadProgress;


- (id)initWithServer:(NSString *)server user:(NSString *)username password:(NSString *)pass port:(NSString*)port;

-(void)disconnect;

-(void)connect;

-(void)sendRAWCommand:(NSString *)command;

-(void)sendChangeWorkDirectory:(NSString*)directory;

-(BOOL)checkConnect;

@end

