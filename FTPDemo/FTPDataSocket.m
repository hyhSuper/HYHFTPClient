    //
//  FTPDataSocket.m
//  FTPDemo
//
//  Created by Allan on 16/11/21.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "FTPDataSocket.h"
@interface FTPDataSocket()<NSStreamDelegate>

@property (nonatomic,retain, strong) NSInputStream   *readStream;

@property (nonatomic, retain,strong) NSOutputStream  *writeStream;

@end


@implementation FTPDataSocket
-(instancetype)initWithAddress:(NSString*)ipAddress  port:(NSInteger)port{
    self = [super init];
    if(self){
        [self creatDataSocket:ipAddress port:port];
    }
    return self;
}

-(void)creatDataSocket:(NSString*)ipAddress port:(UInt32)port{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ipAddress,
                                       port, &readStream, &writeStream);
    self.readStream= (__bridge_transfer NSInputStream *)readStream;
    self.writeStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.readStream setDelegate:self];
    [self.writeStream setDelegate:self];
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.readStream
            waitUntilDone:YES];
    [self performSelector:@selector(scheduleInCurrentThread:)
                 onThread:[[self class] networkThread]
               withObject:self.writeStream
            waitUntilDone:YES];
    [self.readStream open];
    [self.writeStream open];
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
            uint8_t buffer[8192];
            NSInteger len;
            while ([self.readStream hasBytesAvailable]) {
                len = [self.readStream read:buffer maxLength:sizeof(buffer)];
                if (len > 0) {
                    NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                    if (output) {
//                        [self messageReceived:output];
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
            break;
        case NSStreamEventErrorOccurred:
            
            break;
            
        default:
            break;
    }
}



@end
