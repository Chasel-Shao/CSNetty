//
// CSCacheMetadata.m
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

#import "CSNettyCacheMetadata.h"


@implementation CSNettyCacheMetadata

+(instancetype)cacheMetadataWithData:(NSData *)data response:(NSURLResponse *)response holdTime:(NSTimeInterval)holdTime{
    CSNettyCacheMetadata *metadata = [[CSNettyCacheMetadata alloc] init];
    metadata.data = data;
    metadata.response = response;
    metadata.holdTime = holdTime;
    metadata.createTime = [[NSDate date] timeIntervalSince1970];
    return metadata;
}

+ (BOOL)supportsSecureCoding{
    return YES;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeObject:self.response forKey:@"response"];
    [aCoder encodeDouble:self.holdTime forKey:@"holdTime"];
    [aCoder encodeDouble:self.createTime forKey:@"createTime"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.data = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data"];
        self.response = [aDecoder decodeObjectOfClass:[NSURLResponse class] forKey:@"response"];
        self.holdTime =  [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"holdTime"] doubleValue];
        self.createTime =  [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"createTime"] doubleValue];
    }
    return self;
}

-(BOOL)isExpired{
    if (_holdTime < 0 ) {
        return NO;
    }else{
        NSTimeInterval now =  [[NSDate date] timeIntervalSince1970];
        return  _createTime + _holdTime > now;
    }
}
@end
