//
//  FTPConnect.h
//  FTPDemo
//
//  Created by Allan on 16/11/17.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTPCredentials.h"
@interface FTPCommond : NSObject

-(instancetype)initWith:(FTPCredentials*)credentials;

-(void)connect;


@end
