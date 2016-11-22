//
//  FTPConnect.m
//  FTPDemo
//
//  Created by Allan on 16/11/17.
//  Copyright © 2016年 Allan. All rights reserved.
//
#define FTPLIB_BUFSIZ 8192
#define RESPONSE_BUFSIZ 1024
#define TMP_BUFSIZ 1024
#define ACCEPT_TIMEOUT 30

#import "FTPCommond.h"
#import "FTPDataSocket.h"
@interface FTPCommond ()<NSStreamDelegate>
@property(nonatomic,strong)FTPCredentials *credentails;
//命令控制连接读写流
@property (nonatomic,retain, strong) NSInputStream   *comondInputStream;
@property (nonatomic, retain,strong) NSOutputStream  *comondOutputStream;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL loggedOn;
@property (nonatomic,assign) BOOL isDataStreamConfigured;
@property (nonatomic,assign) BOOL isDataStreamAvailable;

@property (nonatomic,assign) NSString* lastResponseCode;
@property (nonatomic,assign) NSString* lastCommandSent;
@property (nonatomic,assign) NSString* lastResponseMessage;


@end

@implementation FTPCommond

-(instancetype)initWith:(FTPCredentials*)credentials{
    self = [super init];
    if (self) {
        self.credentails = credentials;
    }
    return self;
}

+ (NSThread *)networkThread {
    static NSThread *networkThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        networkThread =
        [[NSThread alloc] initWithTarget:self
                                selector:@selector(networkThreadMain:)
                                  object:nil];
        [networkThread start];
    });
    
    return networkThread;
}

+ (void)networkThreadMain:(id)unused {
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

- (void)scheduleInCurrentThread:(NSStream*)aStream
{
    [aStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
}

- (void)initNetworkCommunication {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.credentails.host,self.credentails.port , &readStream, &writeStream);
    
    self.comondInputStream = (__bridge_transfer NSInputStream *)readStream;
    
    self.comondOutputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    [self.comondInputStream setDelegate:self];
    
    [self.comondOutputStream setDelegate:self];
    
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread] 
               withObject:self.comondInputStream
            waitUntilDone:YES];
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.comondOutputStream
            waitUntilDone:YES];
    
    [self.comondOutputStream open];
    
    [self.comondInputStream open];
    
//    self.isConnected= YES;
//    self.isDataStreamConfigured=NO;
    
}

-(void)connect{
    [self initNetworkCommunication];
}


#pragma mark-NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
        case NSStreamEventOpenCompleted:
                NSLog(@"NSStreamEventOpenCompleted");
            break;
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buffer[RESPONSE_BUFSIZ];
            NSInteger len;
            while ([self.comondInputStream hasBytesAvailable]) {
                len = [self.comondInputStream read:buffer maxLength:sizeof(buffer)];
                if (len > 0) {
                    NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                    if (output) {
                        [self messageReceived:output];
                    }
                }
            }
        }
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            //数据传输结束、退出
//            if (aStream == self.dataReadStream) {
//                [self logoff];
//                [self.delegate directoryListingFinishedWithSuccess:self.listEntries];
//            }
            break;
        case NSStreamEventErrorOccurred:
            
            break;
            
        default:
            break;
    }
}

//解析出ftp服务器返回的ip和port
-(void)acceptDataStreamConfiguration:(NSString*)serverResponse
{  NSString *pattern=  @"([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:0
                                  error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:serverResponse
                                                    options:0
                                                      range:NSMakeRange(0, [serverResponse length])];
    
     NSString * dataIPAddress = [NSString stringWithFormat:@"%@.%@.%@.%@",
                          [serverResponse substringWithRange:[match rangeAtIndex:1]],
                          [serverResponse substringWithRange:[match rangeAtIndex:2]],
                          [serverResponse substringWithRange:[match rangeAtIndex:3]],
                          [serverResponse substringWithRange:[match rangeAtIndex:4]]];
      NSInteger  dataPort = ([[serverResponse substringWithRange:[match rangeAtIndex:5]] intValue] * 256)+
    [[serverResponse substringWithRange:[match rangeAtIndex:6]] intValue];
    
    
    FTPDataSocket *dataSocket = [[FTPDataSocket alloc]initWithAddress:dataIPAddress port:dataPort];
    
//    self.isDataStreamConfigured=YES;
//    [self openDataStream];
    
    
}

- (void)messageReceived:(NSString *)message {
    NSLog(@"message = %@",message);
    self.lastResponseCode = [message substringToIndex:3];
    self.lastResponseMessage= message;
//    
    int response = [self.lastResponseCode intValue];
    switch (response) {
        case 150:
            //connection accepted
            break;
        case 200:
            [self sendCommand:@"PASV"];
        case 220: //server welcome message so wait for username
            [self sendUsername];
            break;
        case 221://命令控制连接关闭
//            [self closeAll];
            
            break;
        case 226:
            //transfer OK 传输完成
        {
            //            NSLog(@"文件传输完成,关闭数据传输");
            //            [self closeDataStream];
        }
            break;
        case 227://进入被动模式成功
            //找到ip和数据连接的port
            [self acceptDataStreamConfiguration:message];
            
            break;
        case 230: //server logged in
            self.loggedOn=YES;
            
            [self sendCommand:@"PASV"];
            
//            [self.delegate loggedOn];
            
            break;
        case 250:// Requested file action okay, completed.
            //            [self sendListComend];
            break;
        case 257://PATHNAME created
            NSLog(@"PATHNAME created");
            break;
        case 331: //server waiting for password
            [self sendPassword];
            
            break;
        case 421:
            NSLog(@"服务不可用，控制连接关闭");
            break;
        case 425:
            NSLog(@"打开数据连接失败");
            break;
        case 426:
            NSLog(@"连接关闭，传送中止。");
            break;
        case 450:
            NSLog(@"对被请求文件的操作未被执行");
            break;
        case 451:
            NSLog(@"请求的操作中止。处理中发生本地错误。");
            break;
        case 452:
            NSLog(@"请求的操作没有被执行。系统存储空间不足。 文件不可用");
            break;
        case 502:
            NSLog(@"命令未被执行");
            break;
        case 503:
            NSLog(@"命令的次序错误");
            break;
        case 504:
            NSLog(@"由于参数错误，命令未被执行");
            break;
        case 530: //Login or passwod incorrect
//            [self.delegate logginFailed];
            self.loggedOn = NO;
            break;
        default:
            //            [self closeAll];
            break;
    }
    
//    [self.delegate serverResponseReceived:self.lastResponseCode message:self.lastResponseMessage];
    
}



#pragma command helpers
-(void)sendUsername
{
    [self sendCommand:[NSString stringWithFormat:@"USER %@",self.credentails.username]];
}
-(void)sendPassword
{
    [self sendCommand:[NSString stringWithFormat:@"PASS %@",self.credentails.password]];
}

-(void)sendChangeWorkDirectory:(NSString*)directory{
    
    [self sendRAWCommand:[NSString stringWithFormat:@"CWD /%@",directory]];
}

-(void)sendListComend{
    
    [self sendRAWCommand:@"LIST"];
    
}

-(void)sendRAWCommand:(NSString *)command
{
    [self sendCommand:command];
}
//internal method to send command to the stream
-(void)sendCommand:(NSString *)cmd{
    if (self.isConnected){
        if (self.comondOutputStream){
            NSString *cmdToSend = [NSString stringWithFormat:@"%@\r\n",cmd];
//            self.lastCommandSent= cmdToSend;
            NSData *data = [[NSData alloc] initWithData:[cmdToSend dataUsingEncoding:NSASCIIStringEncoding]];
            //            numberOfBytesSent+=[data length];
            [self.comondOutputStream write:[data bytes] maxLength:[data length]];
        }
        else
        {
//            [self.delegate ftpError:@"trying to send command when not connected"];
        }
    }
}










@end
