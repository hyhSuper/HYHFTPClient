//
//  FileModel.m
//  FTPDemo
//
//  Created by Allan on 16/11/11.
//  Copyright © 2016年 Allan. All rights reserved.
//

#import "FileModel.h"

@implementation FileModel
-(instancetype)initWith:(NSDictionary*)dic{
    self = [super init];
    if (self) {
        self.kGroup = [dic objectForKey:@"kCFFTPResourceGroup"];
        self.kLink  = [dic objectForKey:@"kCFFTPResourceLink"];
        self.kModeDate = [dic objectForKey:@"kCFFTPResourceModDate"];
        self.kMode =  [dic objectForKey:@"kCFFTPResourceMode"];
        self.kName =  [dic objectForKey:@"kCFFTPResourceName"];
        self.kOwner = [dic objectForKey:@"kCFFTPResourceOwner"];
        self.kSize =  [[dic objectForKey:@"kCFFTPResourceSize"] integerValue];
        self.kTpye = [[dic objectForKey:@"kCFFTPResourceType"] integerValue];
        
        if (self.kTpye== File) {
            self.isDirectory = NO;
        }else{
            self.isDirectory = YES;
        }
    }
    return self;
}

@end
