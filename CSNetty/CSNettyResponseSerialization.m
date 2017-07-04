//
// CSNettySerialization.m
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


#import "CSNettyResponseSerialization.h"


@interface CSNettyResponseSerialization(){
    NSMutableDictionary<NSString *,HandleBlock> *_handleMapping;
}
@end

@implementation CSNettyResponseSerialization

-(instancetype)init{
    if (self = [super init]) {
        _handleMapping = [NSMutableDictionary dictionary];
    }
    return self;
}

+(instancetype)defaultResponseSerialize{
   CSNettyResponseSerialization *responseSerialization =  [[CSNettyResponseSerialization alloc] init];
    [responseSerialization addContentType:[self imageContentType] withHandleBlock:^id(NSData *data) {
        return data;
    }];
    
    [responseSerialization addContentType:[self jsonContentType] withHandleBlock:^id(NSData *data) {
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        return responseObject;
    }];
    
    [responseSerialization addContentType:[self textContentType] withHandleBlock:^id(NSData *data) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return text;
    }];
    return responseSerialization;
}

-(instancetype)addContentType:(NSSet *)contentTypeSet withHandleBlock:(id (^)(NSData *))block{
    [contentTypeSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_handleMapping setObject:block forKey:obj];
    }];
    return self;
}

-(id)handleContentType:(NSString*)contentType withData:(NSData *)data{
    HandleBlock block = [_handleMapping objectForKey:contentType];
    if (block != nil) {
       return block(data);
    }else{
        return nil;
    }
}


+(NSMutableSet *)imageContentType{
    return [NSMutableSet setWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];
}

+(NSMutableSet *)jsonContentType{
    return  [NSMutableSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

+(NSMutableSet *)textContentType{
    return  [NSMutableSet setWithObjects:@"text/plain", @"text/html", nil];
}

@end
