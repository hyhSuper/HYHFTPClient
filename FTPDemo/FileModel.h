//
//  FileModel.h
//  FTPDemo
//
//  Created by Allan on 16/11/11.
//  Copyright © 2016年 Allan. All rights reserved.
//
#define  File   8
#define  Directory  4

#import <Foundation/Foundation.h>

@interface FileModel : NSObject

@property(nonatomic,strong)NSString *kGroup;

@property(nonatomic,strong)NSString *kLink;

@property(nonatomic,strong)NSString *kModeDate;

@property(nonatomic,strong)NSString *kMode;

@property(nonatomic,strong)NSString *kName;

@property(nonatomic,strong)NSString *kOwner;

@property(nonatomic,assign)NSInteger kSize;

@property(nonatomic,assign)NSInteger kTpye;

@property(nonatomic,assign)BOOL isDirectory;


-(instancetype)initWith:(NSDictionary*)dic;
@end
