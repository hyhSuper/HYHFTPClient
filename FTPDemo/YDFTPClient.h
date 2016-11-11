//
//  YDFTPClient.h
//  ComplexFTPClient
    //  This file is part of source code lessons that are related to the book
    //  Title: Professional IOS Programming
    //  Publisher: John Wiley & Sons Inc
    //  ISBN 978-1-118-66113-0
    //  Author: Peter van de Put
    //  Company: YourDeveloper Mobile Solutions
    //  Contact the author: www.yourdeveloper.net | info@yourdeveloper.net
    //  Copyright (c) 2013 with the author and publisher. All rights reserved.
    //

#import <Foundation/Foundation.h>
@protocol YDFTPClientDelegate <NSObject>

-(void)logginFailed;
-(void)loggedOn;
-(void)serverResponseReceived:(NSString *)lastResponseCode message:(NSString *)lastResponseMessage;
-(void)ftpError:(NSString *)err;

@end

@interface YDFTPClient : NSObject<NSStreamDelegate>
@property (nonatomic, strong) id<YDFTPClientDelegate> delegate;
@property (readonly) UInt64 numberOfBytesSent;
@property (readonly) UInt64 numberOfBytesReceived;

@property(nonatomic,strong)NSString *ipStr;
@property(nonatomic,strong)NSString *port;
@property(nonatomic,strong)NSString *userName;
@property(nonatomic,strong)NSString *psw;

+(id)shareClient;

- (void)requesList;
- (id)initClient;
- (void)sendRAWCommand:(NSString *)command;
- (void)connect;
- (void)disconnect;

@end

