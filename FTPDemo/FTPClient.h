//
//  FTPManager.h
//  FTPDemo
//
//  Created by Allan on 16/11/7.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CFNetwork/CFNetwork.h>
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

- (id)initWithServer:(NSString *)server user:(NSString *)username password:(NSString *)pass port:(NSString*)port;

-(void)disconnect;

-(void)connect;

-(void)sendRAWCommand:(NSString *)command;

-(void)sendChangeWorkDirectory:(NSString*)directory;

-(BOOL)checkConnect;

@end

