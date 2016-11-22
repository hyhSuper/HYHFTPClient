//
//  YDFTPClient.m
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
#import "YDFTPClient.h"

#define kFTPServer @"192.168.11.140"
#define kFTPPort 21
#define kFTPUsername @"root"
#define kFTPpassword @"123456"

enum {
    kSendBufferSize = 32768
};
@interface YDFTPClient()
{
    UInt64 numberOfBytesSent;
	UInt64 numberOfBytesReceived;
    int uploadbytesreadSoFar;
    NSString *_commond;
}
@property (readwrite, assign) NSString* dataIPAddress;
@property (readwrite, assign) UInt16 dataPort;

@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;

@property (nonatomic,assign) int lastResponseInt;
@property (nonatomic,assign) NSString* lastResponseCode;
@property (nonatomic,assign) NSString* lastCommandSent;
@property (nonatomic,assign) NSString* lastResponseMessage;


@property (nonatomic,retain, strong) NSInputStream *inputStream;
@property (nonatomic, retain,strong) NSOutputStream *outputStream;

@property (nonatomic, retain,strong) NSInputStream *dataInStream;
@property (nonatomic, retain,strong) NSOutputStream *dataOutStream;

@property (nonatomic, retain,strong) NSInputStream *listInStream;
@property (nonatomic, retain,strong) NSOutputStream *listOutStream;
@property (nonatomic, strong, readwrite) NSMutableData *   listData;
@property (nonatomic, strong, readwrite) NSMutableArray *  listEntries;



@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL loggedOn;
@property (nonatomic,assign) BOOL isDataStreamConfigured;
@property (nonatomic,assign) BOOL isDataStreamAvailable;


@end

 
@implementation YDFTPClient
{
    uint8_t                     _buffer[kSendBufferSize];
};


@synthesize bufferOffset  = _bufferOffset;
@synthesize bufferLimit   = _bufferLimit;

+(id)shareClient{
    static YDFTPClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (client == nil) {
            client = [[self alloc] initClient];
        }
    });
    return client;
}

-(id)initClient
{
    if ((self = [super init]))
        {
        self.isConnected=NO;
        self.dataIPAddress=0;
        self.dataPort=0;
        self.isConnected=NO;
        self.isDataStreamAvailable=NO;
        self.lastCommandSent=@"";
        self.lastResponseCode=@"";
        self.lastResponseMessage=@"";
    }
	return self;
}

-(void)connect
{
    if (!self.isConnected)
        [self initNetworkCommunication];
}
-(void)disconnect
{
    if (self.isConnected)
        [self logoff];
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

#pragma internal
//登录ftp服务
- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.ipStr, [self.port intValue], &readStream, &writeStream);
    
  	self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    
 	self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
	[self.inputStream setDelegate:self];
    
	[self.outputStream setDelegate:self];
    
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.inputStream
            waitUntilDone:YES];
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.outputStream
            waitUntilDone:YES];
    
	[self.inputStream open];
    
	[self.outputStream open];
    
    self.isConnected=YES;
    
    self.isDataStreamConfigured=NO;
}

#pragma stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventNone:
            break;
        case NSStreamEventHasBytesAvailable:
            if (theStream == self.inputStream) {
                uint8_t buffer[32768];
                NSInteger len;
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    numberOfBytesReceived+=len;
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (output) {
                            [self messageReceived:output];
                        }
                    }
                }
            }else if (theStream == self.listInStream){//list列表
                NSInteger       bytesRead;
                uint8_t         buffer[32768];
                
                bytesRead = [self.listInStream read:buffer maxLength:sizeof(buffer)];
                if (bytesRead < 0) {
                    [self.delegate ftpError:@"can't read data stream"];
                    [self closeAll];
                } else if (bytesRead == 0) {
                    NSLog(@"文件list为空");
                } else {
                    [self.listData appendBytes:buffer length:(NSUInteger) bytesRead];
                    [self parseListData];
                }
            }
            else if (theStream == self.dataInStream) {
                uint8_t buffer[8192];//8kB block
                NSInteger len;
                while ([self.dataInStream hasBytesAvailable]) {
                    len = [self.dataInStream read:buffer maxLength:sizeof(buffer)];
                    numberOfBytesReceived+=len;
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
            if (theStream == self.dataOutStream) {
                //write your custom code for upload and download
            }
            break;
        case NSStreamEventErrorOccurred:
            [self.delegate ftpError:@"Network stream error occured"];
            [self closeAll];
            break;
        case NSStreamEventEndEncountered:
            
            break;
    }
    
}

-(void)requesList{
    NSString *urlStr = [NSString stringWithFormat:@"ftp://%@:%@@%@/Desktop/",self.userName,self.psw,self.ipStr];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.dataIPAddress, self.dataPort, &readStream, &writeStream);

    
//    self.listInStream = CFBridgingRelease(CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef _Nonnull)(url)));
//    
//    [self.listInStream setProperty:self.userName forKey:(id)kCFStreamPropertyFTPUserName];
//    [self.listInStream setProperty:self.psw forKey:(id)kCFStreamPropertyFTPPassword];
//    self.listInStream.delegate = self;
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.listInStream
            waitUntilDone:YES];
    [self.listInStream open];
//    _commond = @"list";
//    [self sendCommand:@"LIST"];
    
}
-(void)closeAll
{
    if (self.inputStream != nil) {
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.inputStream.delegate = nil;
        [self.inputStream close];
        self.inputStream = nil;
    }
    if (self.dataInStream != nil) {
        [self.dataInStream close];
        self.dataInStream = nil;
    }
    if (self.listInStream != nil) {
        [self.listInStream close];
        self.listInStream = nil;
    }
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
- (void)addListEntries:(NSArray *)newEntries
{
    [self.listEntries addObjectsFromArray:newEntries];
    [self closeAll];
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
    
    NSLog(@"listEntries.cout = %@",self.listEntries.count);
}


#pragma command helpers
-(void)sendUsername
{
    [self sendCommand:[NSString stringWithFormat:@"USER %@",self.userName]];
}
-(void)sendPassword
{
    [self sendCommand:[NSString stringWithFormat:@"PASS %@",self.psw]];
}
-(void)sendRAWCommand:(NSString *)command
{
//    _commond = @"list";

    [self sendCommand:command];
}
    //internal method to send command to the stream
-(void)sendCommand:(NSString *)cmd{
	if (self.isConnected){
        if (self.outputStream){
            NSString *cmdToSend = [NSString stringWithFormat:@"%@\r\n",cmd];
            self.lastCommandSent=cmdToSend;
            NSData *data = [[NSData alloc] initWithData:[cmdToSend dataUsingEncoding:NSASCIIStringEncoding]];
            numberOfBytesSent+= [data length];
            [self.outputStream write:[data bytes] maxLength:[data length]];
        }
        else
        {
            [self.delegate ftpError:@"trying to send command when not connected"];
        }
    }
}

- (void) messageReceived:(NSString *)message {
	self.lastResponseCode   =   [message substringToIndex:3];
    self.lastResponseMessage=   message;
   
    int response = [self.lastResponseCode intValue];
    self.lastResponseInt=response;
    [self.delegate serverResponseReceived:self.lastResponseCode message:self.lastResponseMessage];
    switch (response) {
        case 150:
                //connection accepted
            NSLog(@"");
            
            
            
            break;
        case 200:
            [self sendCommand:@"PORT"];
        case 220: //server welcome message so wait for username
            
            [self sendUsername];
            break;
        case 226:
                //transfer OK
//            [self parseListData];

            break;
        case 227:
            [self acceptDataStreamConfiguration:message];
            break;
        case 230: //server logged in
            self.loggedOn=YES;
            [self sendCommand:@"PORT"];
            [self.delegate loggedOn];
            break;
            
        case 331: //server waiting for password
            [self sendPassword];
            
            break;
        case 530: //Login or passwod incorrect
            [self.delegate logginFailed];
            self.loggedOn=NO;
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
    
    self.dataIPAddress = [NSString stringWithFormat:@"%@.%@.%@.%@",
                     [serverResponse substringWithRange:[match rangeAtIndex:1]],
                     [serverResponse substringWithRange:[match rangeAtIndex:2]],
                     [serverResponse substringWithRange:[match rangeAtIndex:3]],
                     [serverResponse substringWithRange:[match rangeAtIndex:4]]];
    self.dataPort = ([[serverResponse substringWithRange:[match rangeAtIndex:5]] intValue] * 256)+
    [[serverResponse substringWithRange:[match rangeAtIndex:6]] intValue];
    self.isDataStreamConfigured=YES;
    [self openDataStream];
    
    
}
-(void)openDataStream
{
    if (self.isDataStreamConfigured && !self.isDataStreamAvailable){
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.dataIPAddress,
                                           self.dataPort, &readStream, &writeStream);
        self.dataInStream = (__bridge_transfer NSInputStream *)readStream;
        self.dataOutStream = (__bridge_transfer NSOutputStream *)writeStream;
        [self.dataInStream setDelegate:self];
        [self.dataOutStream setDelegate:self];
        [self performSelector:@selector(scheduleInCurrentThread:)
                     onThread:[[self class] networkThread]
                   withObject:self.dataInStream
                waitUntilDone:YES];
        [self performSelector:@selector(scheduleInCurrentThread:)
                     onThread:[[self class] networkThread]
                   withObject:self.dataOutStream
                waitUntilDone:YES];
        [self.dataInStream open];
        [self.dataOutStream open];
        self.isDataStreamAvailable=YES;
    }
    
}
-(void)closeDataStream
{
    if (self.dataInStream.streamStatus != NSStreamStatusClosed)
        {
        [self.dataInStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.dataInStream.delegate = nil;
        [self.dataInStream close];
        }
    if (self.dataOutStream.streamStatus != NSStreamStatusClosed)
        {
        [self.dataOutStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.dataOutStream.delegate = nil;
        [self.dataOutStream close];
    }
}
-(void)logoff
{
    [self sendCommand:@"QUIT"];
    [self closeDataStream];
    if (self.inputStream.streamStatus != NSStreamStatusClosed)
        {
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.inputStream.delegate = nil;
        [self.inputStream close];
        }
    if (self.outputStream.streamStatus != NSStreamStatusClosed)
        {
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.outputStream.delegate = nil;
        [self.outputStream close];
        }
    self.isConnected=NO;
    self.isDataStreamAvailable=NO;
    self.isDataStreamConfigured=NO;
}

#pragma readonly properties
- (uint8_t *)buffer
{
    return  self.buffer;
}
- (UInt64)numberOfBytesSent
{
    return numberOfBytesSent;
}
- (UInt64)numberOfBytesReceived
{
    return numberOfBytesReceived;
}
@end
