//
//  FTPManager.m
//  FTPDemo
//
//  Created by Allan on 16/11/7.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "FTPClient.h"
@interface FTPClient()

@property (readwrite, assign) NSString* dataIPAddress;
@property (readwrite, assign) UInt16 dataPort;

@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;

@property (nonatomic,assign) int lastResponseInt;
@property (nonatomic,assign) NSString* lastResponseCode;
@property (nonatomic,assign) NSString* lastCommandSent;
@property (nonatomic,assign) NSString* lastResponseMessage;


@property (nonatomic, strong, readwrite) NSInputStream *   dataReadStream;
@property (nonatomic,strong)NSOutputStream *dataWriteStream;

//@property (nonatomic, strong, readwrite) NSInputStream *   uploadStream;
//@property (nonatomic, strong, readwrite) NSOutputStream *  downloadfileStream;

@property (nonatomic,retain, strong) NSInputStream   *comondInputStream;

@property (nonatomic, retain,strong) NSOutputStream  *comondOutputStream;



@property (nonatomic, assign, readwrite) NSString*         ftpServer;
@property (nonatomic, assign, readwrite) NSString*         ftpUsername;
@property (nonatomic, assign, readwrite) NSString*         ftpPassword;
@property (nonatomic, assign, readwrite) NSString*         port;

@property (nonatomic, strong, readwrite) NSMutableData *   listData;
@property (nonatomic, strong, readwrite) NSMutableArray *  listEntries;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL loggedOn;
@property (nonatomic,assign) BOOL isDataStreamConfigured;
@property (nonatomic,assign) BOOL isDataStreamAvailable;

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, assign, readonly ) BOOL              isSending;


@end


@implementation FTPClient

- (id)initWithServer:(NSString *)server user:(NSString *)username password:(NSString *)pass port:(NSString*)port{
    if ((self = [super init]))
    {
        self.ftpServer =  server;
        self.ftpUsername= username;
        self.ftpPassword= pass;
        self.port = port;
        self.listData = [[NSMutableData alloc]init];
        self.listEntries = [[NSMutableArray alloc]init];
    }
    return self;
}
#pragma thread management
//创建一个线程
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

//-(void)requestDiretory:(NSString*)directory{
//    [self connect];
//}
-(void)connect
{
    if (!self.isConnected) [self initNetworkCommunication];
}
-(void)disconnect
{
    if (self.isConnected) [self logoff];
}

-(void)logoff
{
    [self sendCommand:@"QUIT"];
    [self closeDataStream];
    self.isConnected=NO;
    self.isDataStreamAvailable=NO;
    self.isDataStreamConfigured=NO;
}
//
- (void)initNetworkCommunication {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.ftpServer,[self.port intValue] , &readStream, &writeStream);
    
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
    
    self.isConnected= YES;
    
    self.isDataStreamConfigured=NO;
    
}
-(void)dealData:(NSInputStream*)aStream byte:(int)byte{
    uint8_t buffer[byte];
    NSInteger len;
    while ([aStream hasBytesAvailable]) {
        len = [aStream read:buffer maxLength:sizeof(buffer)];
        if (len > 0) {
            NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
            if (output) {
                [self messageReceived:output];
            }
            if (aStream == self.dataReadStream ) {
                [self.listData appendBytes:buffer length:(NSUInteger) len];
                [self parseListData];
            }
        }
    }
}

#pragma mark-NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
        case NSStreamEventOpenCompleted:
            if (aStream == self.comondOutputStream) {
                NSLog(@"NSStreamEventOpenCompleted");
            }
            break;
        case NSStreamEventHasBytesAvailable:
        {
            if (aStream == self.comondInputStream) {//命令控制
                [self dealData:self.comondInputStream byte:1024];
            }else{//数据
                [self dealData:self.dataReadStream byte:8192];
            }
        }
            break;
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"NSStreamEventHasSpaceAvailable");
        }
            break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"NSStreamEventEndEncountered");
            //数据传输结束、退出
            if (aStream == self.dataReadStream) {
                [self logoff];
                [self.delegate directoryListingFinishedWithSuccess:self.listEntries];
            }
        }
            break;
        case NSStreamEventErrorOccurred:
        {//TODO 初始化数据连接和命令链接
            [self.delegate ftpError:@"Network stream error occured"];
            [self closeAll];
        }
            break;
        default:
            break;
    }
}

- (void)messageReceived:(NSString *)message {
    NSLog(@"message = %@",message);
    self.lastResponseCode = [message substringToIndex:3];
    self.lastResponseMessage= message;
    
    int response = [self.lastResponseCode intValue];
    self.lastResponseInt= response;
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
            [self closeAll];
            break;
        case 226:
            //transfer OK 传输完成
        {
//            NSLog(@"文件传输完成,关闭数据传输");
//            [self closeDataStream];
        }
            break;
        case 227://进入被动模式成功
            
            [self acceptDataStreamConfiguration:message];
            
            break;
        case 230: //server logged in
            self.loggedOn=YES;
            
            [self sendCommand:@"PASV"];
            
            [self.delegate loggedOn];
            
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
            [self.delegate logginFailed];
            self.loggedOn = NO;
            break;
        default:
//            [self closeAll];
            break;
    }
    
    [self.delegate serverResponseReceived:self.lastResponseCode message:self.lastResponseMessage];

}


- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding
{
    NSDictionary *  result;
    NSString *      name;
    NSData *        nameData;
    NSString *      newName;
    newName = nil;
    // Try to get the name, convert it back to MacRoman, and then reconvert it
    // with the preferred encoding.
    name = [entry objectForKey:(id) kCFFTPResourceName];
    if (name != nil) {
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil) {
            newName = [[NSString alloc] initWithData:nameData encoding:newEncoding];
        }
    }
    if (newName == nil) {
        result = (NSDictionary *) entry;
    } else {
        NSMutableDictionary *   newEntry;
        newEntry = [entry mutableCopy];
        [newEntry setObject:newName forKey:(id) kCFFTPResourceName];
        result = newEntry;
    }
    return result;
}
#pragma mark --处理文件列表
- (void)addListEntries:(NSArray *)newEntries
{
    [self.listEntries addObjectsFromArray:newEntries];
//    [self closeAll];
    //    [self.delegate directoryListingFinishedWithSuccess:self.listEntries];
}

- (void)parseListData
{
    NSMutableArray *    newEntries;
    NSUInteger          offset;
    newEntries = [NSMutableArray array];
    offset = 0;
    do {
        CFIndex         bytesConsumed;
        CFDictionaryRef thisEntry;
        thisEntry = NULL;
        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], (CFIndex) ([self.listData length] - offset), &thisEntry);
        if (bytesConsumed > 0) {
            if (thisEntry != NULL) {
                NSDictionary *  entryToAdd;
                entryToAdd = [self entryByReencodingNameInEntry:(__bridge NSDictionary *) thisEntry encoding:NSUTF8StringEncoding];
                [newEntries addObject:entryToAdd];
            }
            // We consume the bytes regardless of whether we get an entry.
            offset += (NSUInteger) bytesConsumed;
        }
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry.
            //Wait for more data to arrive
            break;
        } else if (bytesConsumed < 0) {
            // We totally failed to parse the listing.  Fail.
            break;
        }
    } while (YES);
    
    if ([newEntries count] != 0) {
        [self addListEntries:newEntries];
    }
    if (offset != 0) {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
    
    NSLog(@"listEntries.cout = %lu",(unsigned long)self.listEntries.count);
}

#pragma command helpers
-(void)sendUsername
{
    [self sendCommand:[NSString stringWithFormat:@"USER %@",self.ftpUsername]];
}
-(void)sendPassword
{
    [self sendCommand:[NSString stringWithFormat:@"PASS %@",self.ftpPassword]];
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
            self.lastCommandSent= cmdToSend;
            NSData *data = [[NSData alloc] initWithData:[cmdToSend dataUsingEncoding:NSASCIIStringEncoding]];
//            numberOfBytesSent+=[data length];
            [self.comondOutputStream write:[data bytes] maxLength:[data length]];
        }
        else
        {
            [self.delegate ftpError:@"trying to send command when not connected"];
        }
    }
}
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
    
    self.dataIPAddress = [NSString stringWithFormat:@"%@.%@.%@.%@",
                          [serverResponse substringWithRange:[match rangeAtIndex:1]],
                          [serverResponse substringWithRange:[match rangeAtIndex:2]],
                          [serverResponse substringWithRange:[match rangeAtIndex:3]],
                          [serverResponse substringWithRange:[match rangeAtIndex:4]]];
    self.dataPort = ([[serverResponse substringWithRange:[match rangeAtIndex:5]] intValue] * 256)+
    [[serverResponse substringWithRange:[match rangeAtIndex:6]] intValue];
    
    self.isDataStreamConfigured= YES;
    
    
    [self openDataStream];
}
-(void)openDataStream
{
    if (self.isDataStreamConfigured && !self.isDataStreamAvailable && !self.dataReadStream ){
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.dataIPAddress,
                                           self.dataPort, &readStream, &writeStream);
        self.dataReadStream = (__bridge_transfer NSInputStream *)readStream;
        self.dataWriteStream = (__bridge_transfer NSOutputStream *)writeStream;
        [self.dataReadStream setDelegate:self];
        [self.dataWriteStream setDelegate:self];
        [self performSelector:@selector(scheduleInCurrentThread:)
                     onThread:[[self class] networkThread]
                   withObject:self.dataReadStream
                waitUntilDone:YES];
        [self performSelector:@selector(scheduleInCurrentThread:)
                     onThread:[[self class] networkThread]
                   withObject:self.dataWriteStream
                waitUntilDone:YES];
        
        [self.dataWriteStream open];
        
        [self.dataReadStream open];
        
        self.isDataStreamAvailable=YES;
        NSLog(@"创建数据链路");

        if (self.delegate && [self.delegate respondsToSelector:@selector(dataStreamBuildSucess:)]) {
            [self.delegate dataStreamBuildSucess:self];
        }
    }
}

-(void)closeDataStream{
    if (self.dataReadStream != nil) {
        [self.dataReadStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.dataReadStream.delegate = nil;
        [self.dataReadStream close];
        self.dataReadStream = nil;
    }
    if (self.dataWriteStream != nil) {
        [self.dataWriteStream close];
        self.dataWriteStream = nil;
    }
    
}
-(void)closeComondStream{
    
    if (self.comondInputStream.streamStatus != NSStreamStatusClosed)
    {
        [self.comondInputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.comondInputStream.delegate = nil;
        self.comondInputStream = nil;
        
        [self.comondInputStream close];
    }
    if (self.comondOutputStream.streamStatus != NSStreamStatusClosed)
    {
        [self.comondOutputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.comondOutputStream.delegate = nil;
        self.comondOutputStream = nil;
        [self.comondOutputStream close];
    }
    
}
-(void)closeAll{
    [self closeComondStream];
    [self closeDataStream];
    self.isConnected=NO;
    self.isDataStreamAvailable=NO;
    self.isDataStreamConfigured=NO;
}
@end
