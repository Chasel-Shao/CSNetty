//
// CSNettyCallback.h
// Copyright (c) 2017年 Chasel. All rights reserved.
// https://github.com/Chasel-Shao/CSNetty.git
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "CSNettyResult.h" 
#import "CSNettyManager.h"

@class CSNettyManager;

typedef void (^CSNettyResponseBlock)(CSNettyResult *response);
typedef void (^CSNettyProgressBlock)(NSProgress *progress);

@interface CSNettyCallback : NSObject

@property(nonatomic,copy)CSNettyResponseBlock successBlock;
@property(nonatomic,copy)CSNettyResponseBlock cacheBlock;
@property(nonatomic,copy)CSNettyResponseBlock failureBlock;
@property(nonatomic,copy)CSNettyProgressBlock uploadProgressBlock;
@property(nonatomic,copy)CSNettyProgressBlock downloadProgressBlock;



+(instancetype)success:(CSNettyResponseBlock)success failure:(CSNettyResponseBlock)failure;

+(instancetype)success:(CSNettyResponseBlock)success cache:(CSNettyResponseBlock)cache failure:(CSNettyResponseBlock)failure;

+(instancetype)success:(CSNettyResponseBlock)success uploadProgress:(CSNettyProgressBlock)uploadProgress downloadProgressprogress:(CSNettyProgressBlock)downloadProgress failure:(CSNettyResponseBlock)failure;

+(instancetype)success:(CSNettyResponseBlock)success cache:(CSNettyResponseBlock)cache uploadProgress:(CSNettyProgressBlock)uploadProgress downloadProgressprogress:(CSNettyProgressBlock)downloadProgress failure:(CSNettyResponseBlock)failure;

@end



