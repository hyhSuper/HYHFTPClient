//
//  FTPDataSocket.h
//  FTPDemo
//
//  Created by Allan on 16/11/21.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTPDataSocket : NSObject
-(instancetype)initWithAddress:(NSString*)ipAddress  port:(NSInteger)port;
@end
