//
// CSNettyMultipart.m
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

#import "CSNettyAttachData.h"
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

@interface CSNettyAttachData()
@property(readwrite,nonatomic,copy)NSString *name;
@property(readwrite,nonatomic,copy)NSString *fileName;
@property(readwrite,nonatomic,strong) NSData *formData;
@property(readwrite,nonatomic,copy)NSString *mimeType;
@end

@implementation CSNettyAttachData
-(instancetype)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    
    _name = name;
    _fileName = [fileURL lastPathComponent];
    _mimeType = AFContentTypeForPathExtension([fileURL pathExtension]);
    NSMutableData *formData = [NSMutableData data];
    [formData appendData: [NSData dataWithContentsOfURL:fileURL]];
    _formData = formData;
    return self;
}

-(instancetype)appendPartWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    _name = name;
    _fileName = fileName;
    _mimeType = mimeType;
    _formData = data;
    return self;
}
@end
