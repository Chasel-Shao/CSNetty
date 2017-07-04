//
// CSNettyCache.m
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

#import "CSNettyCache.h"
#import "CSNettyEncrypt.h"

typedef NS_ENUM(NSUInteger, CSNetwortCachePolicy) {
    CSNettyCachePolicyNone        = 0,
    CSNettyCachePolicyMemory      = 1,
    CSNettyCachePolicyDisk        = 2,
};

@implementation CSNettyCache

static  dispatch_semaphore_t _lock;
static NSMutableDictionary * get_temp_cache_mapping(){
    static NSMutableDictionary *_tempCacheDict = nil;
    if (_tempCacheDict == nil) {
        _lock = dispatch_semaphore_create(1);
        _tempCacheDict =  [NSMutableDictionary dictionary];
    }
    return _tempCacheDict;
}

static void set_temp_cache(NSString *key, id data){
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [get_temp_cache_mapping() setObject:data forKey:key];
    dispatch_semaphore_signal(_lock);
}

+(CSNettyCacheMetadata *)cacheWith:(NSURLRequest *)request policy:(int)policy{
    
    if (policy == CSNettyCachePolicyDisk) {
        NSString *cachePath = [[self cacheDirectory] stringByAppendingPathComponent:[self requestKey:request]];
        CSNettyCacheMetadata *metadata = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
        if ([metadata isKindOfClass:[CSNettyCacheMetadata class]]) {
            if (metadata.isExpired) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:cachePath error:nil];
                return nil;
            }
            return metadata;
        }else{
            return nil;
        }
    }else if(policy == CSNettyCachePolicyMemory){ 
        NSString *cachePath = [self requestKey:request];
        return  [get_temp_cache_mapping() objectForKey:cachePath];
    }
    return nil;
}

+(void)saveCacheWith:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data holdTime:(NSTimeInterval)holdTime policy:(int)policy{
    
    if (policy == CSNettyCachePolicyDisk) {
        NSString *cachePath = [[self cacheDirectory] stringByAppendingPathComponent:[self requestKey:request]];
        CSNettyCacheMetadata *metadata =  [CSNettyCacheMetadata cacheMetadataWithData:data response:response holdTime:holdTime];
        [NSKeyedArchiver archiveRootObject:metadata toFile:cachePath];
    }else if(policy == CSNettyCachePolicyMemory){
        NSString *key = [self requestKey:request];
        CSNettyCacheMetadata *metadata =  [CSNettyCacheMetadata cacheMetadataWithData:data response:response holdTime:holdTime];
        set_temp_cache(key, metadata);
    }
    
}

+(void)clearCache{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self cacheDirectory];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:cachePath error:NULL];
    NSEnumerator *e
    = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        
        [fileManager removeItemAtPath:[cachePath stringByAppendingPathComponent:filename] error:NULL];
        
    }
    
    [get_temp_cache_mapping() removeAllObjects];
}

+(NSString *)cacheDirectory{
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"CSNettyCache"];
    
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir;
        if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                                       attributes:nil error:nil];
            [[NSURL URLWithString:path] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        } else {
            if (!isDir) {
                NSError *error = nil;
                [fileManager removeItemAtPath:path error:&error];
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                                           attributes:nil error:nil];
                [[NSURL URLWithString:path] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
            }
        }
    }
    return path;
}

+(NSString *)requestKey:(NSURLRequest *)request{
    NSMutableData *requestData = [NSMutableData data];
    [requestData appendData:[request.URL.absoluteString dataUsingEncoding:NSUTF8StringEncoding]];
    [requestData appendData:request.HTTPBody];
    return  [CSNettyEncrypt md5StringFromData:requestData];
}

@end
