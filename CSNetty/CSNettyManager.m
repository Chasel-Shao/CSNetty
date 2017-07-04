//
// CSNettyManager.m
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

#import "CSNettyManager.h"
#import "CSNetty.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#define Lock() dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(_lock)

NSString * _createMultipartFormBoundary() {
    return @"Boundary+0x3ed9cd03";
}

static dispatch_queue_t get_cache_writing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("CSNetty", attr);
    });
    return queue;
}

@interface CSNettyManager() <NSURLSessionDownloadDelegate>{
    
    NSURLSession *_session;
    dispatch_semaphore_t _lock;
    NSOperationQueue *_HTTPQueue;
    
    NSInteger _concurrentCount;
    NSInteger _completationCount;
    
    CSNettyRequest *_currentRequest;
    CSNettyResponseSerialization *_responseSerialization;
    CSNetwortMultiResponsePolicy _multiResponsePolicy;
    NSProgress *_uploadProgress;
    NSProgress *_downloadProgress;
    CSNettyCallback *_callback;
    
    NSMutableArray<CSNettyRequest *> *_HTTPReqests;
    NSMutableDictionary<NSString *,CSNettyResult *> *_HTTPCacheResults;
    NSMutableDictionary <NSURLSessionTask*,CSNettyResult *> *_HTTPResults;
}
@end

@implementation CSNettyManager

+(CSNettyManager *(^)(NSURL *url))GET{
    return ^(NSURL *url){
        CSNettyManager *netWorking =  [[CSNettyManager alloc] init];
        return netWorking.get(url);
    };
}

+(CSNettyManager *(^)(NSURL *url))POST{
    return ^(NSURL *url){
        CSNettyManager *netWorking =  [[CSNettyManager alloc] init];
        return netWorking.post(url);
    };
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup{
    _downloadProgress = [[NSProgress alloc] init];
    _uploadProgress = [[NSProgress alloc] init];
    _HTTPReqests = [NSMutableArray array];
    _HTTPResults = [NSMutableDictionary dictionary];
    _HTTPCacheResults = [NSMutableDictionary dictionary];
    _HTTPQueue = [NSOperationQueue currentQueue];
    _HTTPQueue.maxConcurrentOperationCount = 5;
    _lock = dispatch_semaphore_create(1);
    _responseSerialization = [CSNettyResponseSerialization defaultResponseSerialize];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
}

-(CSNettyManager *(^)(NSURL *url))get{
    return ^(NSURL *url){
        _currentRequest = [CSNettyRequest defaultRequest];
        [_HTTPReqests addObject:_currentRequest];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        _currentRequest.urlRequest = request;
        _currentRequest.urlRequest.HTTPMethod = @"GET";
        _currentRequest.requestEncoding = CSNettyURLEncoding;
        _currentRequest.method = CSNettyMethodGET;
        return self;
    };
}

-(CSNettyManager *(^)(NSURL *url))post{
    return ^(NSURL *url){
        _currentRequest = [CSNettyRequest defaultRequest];
        [_HTTPReqests addObject:_currentRequest];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        _currentRequest.urlRequest = request;
        _currentRequest.urlRequest.HTTPMethod = @"POST";
        _currentRequest.method = CSNettyMethodPOST;
        return self;
    };
}
-(CSNettyManager *(^)(NSURL *))upload{
    return ^(NSURL *url){
        _currentRequest = [CSNettyRequest defaultRequest];
        [_HTTPReqests addObject:_currentRequest];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        _currentRequest.urlRequest = request;
        _currentRequest.urlRequest.HTTPMethod = @"POST";
        _currentRequest.method = CSNettyMethodPOST;
        return self;
    };
}

-(CSNettyManager *(^)(NSURL *))download{
    return ^(NSURL *url){
        _currentRequest = [CSNettyRequest defaultRequest];
        [_HTTPReqests addObject:_currentRequest];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        _currentRequest.urlRequest = request;
        _currentRequest.urlRequest.HTTPMethod = @"POST";
        _currentRequest.method = CSNettyMethodDownload;
        return self;
    };
}

-(CSNettyManager *(^)(NSDictionary *params))addParam{
    return ^(NSDictionary *params){
        [_currentRequest.params addEntriesFromDictionary:params];
        return self;
    };
}

-(CSNettyManager *(^)(CSNettyAttachData* attachData))addAttachData{
    return ^(CSNettyAttachData* attachData){
        [_currentRequest.attachedDataArray addObject:attachData];
        return self;
    };
}

-(CSNettyManager *(^)(NSDictionary *header))addHeader{
    return ^(NSDictionary *header){
        [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [_currentRequest.urlRequest setValue:obj forHTTPHeaderField:key];
        }];
        return self;
    };
}

-(CSNettyManager *(^)(NSTimeInterval timeout))setTimeout{
    return ^(NSTimeInterval timeout){
        _currentRequest.urlRequest.timeoutInterval = timeout;
        return self;
    };
}

-(CSNettyManager *(^)(CSNettyEncoding encoding))setRequestSerialization{
    return ^(CSNettyEncoding encoding){
        _currentRequest.requestEncoding = encoding;
        return self;
    };
}

-(CSNettyManager *(^)(CSNettyResponseSerialization *responseSerialization))setResponseSerialzation{
    return ^(CSNettyResponseSerialization *responseSerialization){
        _responseSerialization = responseSerialization;
        return self;
    };
}

-(CSNettyManager *(^)(CSNetwortCachePolicy cachePolicy))setCachePolicy{
    return ^(CSNetwortCachePolicy cachePolicy){
        _currentRequest.cachePolicy = cachePolicy;
        _currentRequest.cacheExpiredTime = -1;
        return self;
    };
}
-(CSNettyManager *(^)(NSTimeInterval cacheExpiredTime))setCacheExpiredTime{
    return ^(NSTimeInterval cacheExpiredTime){
        _currentRequest.cacheExpiredTime = cacheExpiredTime;
        return self;
    };
}
-(CSNettyManager *(^)())clearCache{
    return ^(){
        [CSNettyCache clearCache];
        return self;
    };
}
-(CSNettyManager *(^)(NSString *key))setRequestKey{
    return ^(NSString *key){
        _currentRequest.requestKey = key;
        return self;
    };
}

-(CSNettyManager *(^)(CSNettyAspect *dispose))setAspectDispose{
    return ^(CSNettyAspect *dispose){
        _currentRequest.dispose = dispose;
        return self;
    };
}

-(CSNettyManager *(^)(CSNetwortMultiResponsePolicy policy))setMultiRequestPolicy{
    return ^(CSNetwortMultiResponsePolicy policy){
        _multiResponsePolicy = policy;
        return self;
    };
}
-(CSNettyManager *(^)(__unsafe_unretained Class cls))setDataModelClass{
    return ^(__unsafe_unretained Class cls){
        _currentRequest.dataModelClass = cls;
        return self;
    };
}
-(CSNettyManager *(^)(NSInteger count))setConcurrenceCount{
    return ^(NSInteger count){
        _concurrentCount = count;
        return self;
    };
}
-(CSNettyManager *(^)(CSRequestPriority priority))setRequestPriority{
    return ^(CSRequestPriority priority){
        _currentRequest.priority = priority;
        return self;
    };
}

-(CSNettyManager *(^)(CSNettyCallback *callback))send{
    [self __setUserAgent];
    return ^(CSNettyCallback *callback){
        _callback = callback;
        
        [_HTTPReqests enumerateObjectsUsingBlock:^(CSNettyRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
            [self __beforeRequest:request];
            [self __setupRequestEncodingWith:request];
            switch (request.method) {
                case CSNettyMethodDownload:{
                    CSNettyResult *result = [[CSNettyResult alloc] init];
                    result.requestKey = request.requestKey;
                    result.dataModelClass = request.dataModelClass;
                    NSURLSessionDownloadTask *downloadTask =  [_session downloadTaskWithURL:request.urlRequest.URL];
                    request.dataTask = downloadTask;
                    [self _setDelegateWithTask:downloadTask request:request];
                    [_HTTPResults setObject:result forKey:downloadTask];
                    [downloadTask resume];
                }
                    break;
                case CSNettyMethodGET:
                case CSNettyMethodPOST:
                {
                    /// whether use cache
                    if (request.cachePolicy > 0) {
                        CSNettyCacheMetadata *metadata =  [CSNettyCache cacheWith:request.urlRequest policy:request.cachePolicy];
                        if (metadata.isExpired == NO) {
                            id responseObject =  [_responseSerialization handleContentType:metadata.response.MIMEType withData:metadata.data];
                            if (responseObject != nil) {
                                CSNettyResult *result = [[CSNettyResult alloc] init];
                                result.requestKey = request.requestKey;
                                result.dataModelClass = request.dataModelClass;
                                result.state = CSNettyResultCache;
                                result.data = responseObject;
                                [_HTTPCacheResults setObject:result forKey:request.requestKey];
                            }
                        }
                    }
                    
                    CSNettyResult *result = [[CSNettyResult alloc] init];
                    result.requestKey = request.requestKey;
                    result.dataModelClass = request.dataModelClass;
                    /// start request
                    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request.urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        
                        if (error == nil) {
                            
                            result.data = [_responseSerialization handleContentType:response.MIMEType withData:data];
                            if (request.dispose && request.dispose.beforeResponseWithBlock) {
                                result.data = request.dispose.beforeResponseWithBlock(result.data);
                            }
                            
                            if (result.data != nil) {
                                result.state = CSNettyResultSuccess;
                            }else{
                                result.state = CSNettyResultFailure;
                            }
                            
                            if (request.cachePolicy > 0 && result.state == CSNettyResultSuccess) {
                                dispatch_async(get_cache_writing_queue(), ^{
                                    [CSNettyCache saveCacheWith:request.urlRequest response:response data:data holdTime:-1 policy:request.cachePolicy];
                                });
                            }
                            
                        }else{
                            result.data = error;
                            result.state = CSNettyResultFailure;
                        }
                        
                        [self __beforeFinishedWithRequest:request];
                        [self __vertifyDataTaskGroupWithResult:result];
                        [self __afterFinishedWithRequest:request];
                    }];
                    request.dataTask = dataTask;
                    [self _setDelegateWithTask:dataTask request:request];
                    [_HTTPResults setObject:result forKey:dataTask];
                    [self __setPriority:request.priority withTask:dataTask];
                    
                    [dataTask resume];
                    [self __afterRequestWithRequset:request];
                }
                    break;
                default:
                    // default
                    break;
            }
        }];
        
        [self __handleCacheMultRequstTask];
        return self;
    };
}

-(void)__setPriority:(CSRequestPriority)priority withTask:(NSURLSessionTask *)dataTask{
    switch (priority) {
        case CSNetwrokRequestPriorityLow:
            dataTask.priority = NSURLSessionTaskPriorityLow;
            break;
        case CSNetwrokRequestPriorityDefault:
            dataTask.priority = NSURLSessionTaskPriorityDefault;
            break;
        case CSNetwrokRequestPriorityHigh:
            dataTask.priority = NSURLSessionTaskPriorityHigh;
            break;
        default:
            dataTask.priority = NSURLSessionTaskPriorityDefault;
            break;
    }
}


-(void)__vertifyDataTaskGroupWithResult:(CSNettyResult *)result{
    Lock();
    _completationCount++;
    [self __uploadProgressWithCompletedCount:0 totalCount:0];
    [self __downloadProgressWithCompletedCount:0 totalCount:0];
    
    switch (_multiResponsePolicy) {
        case CSNetwortMultiResponseSync:{ // sync
            [self __handleSyncMultiRequestTask];
            break;
        }case CSNetwortMultiResponseAsyn:{ // aync
            [self __handleAsyncMultiRequestTask:(CSNettyResult *)result];
            break;
        }default:{
            [self __handleSyncMultiRequestTask];
            break;
        }
    }
    if (_completationCount == _HTTPReqests.count) {
        [self __fininedAllTasks];
    }
    Unlock();
}

-(void)__handleCacheMultRequstTask{
    if (_HTTPCacheResults.count > 0) {
        if (_callback.cacheBlock) {
            if (_HTTPResults.count == 1) {
                return _callback.cacheBlock(_HTTPResults.allValues.firstObject);
            }else{
                CSNettyResult *result = [[CSNettyResult alloc] init];
                result.data = _HTTPReqests;
                result.state = CSNettyResultCache;
                result.duration  = 0.0;
                _callback.cacheBlock(result);
            }
        }
    }
}

-(void)__handleSyncMultiRequestTask{
    BOOL result = NO;
    if (_completationCount == _HTTPReqests.count) {
        result = YES;
    }
    if (result) {
        __block NSTimeInterval totalSuccessDuration = 0.0;
        __block NSTimeInterval totalFailureDuration = 0.0;
        NSMutableDictionary *successDict = [NSMutableDictionary dictionary];
        NSMutableDictionary *failureDict = [NSMutableDictionary dictionary];
        [_HTTPResults enumerateKeysAndObjectsUsingBlock:^(NSURLSessionTask * _Nonnull key, CSNettyResult * _Nonnull result, BOOL * _Nonnull stop) {
            switch (result.state) {
                case CSNettyResultSuccess:
                    totalSuccessDuration += result.duration;
                    [successDict setObject:result forKey:result.requestKey];
                    break;
                case CSNettyResultFailure:
                    totalFailureDuration += result.duration;
                    [failureDict setObject:result forKey:result.requestKey];
                    break;
                default:
                    break;
            }
        }];
        
        if (_callback.successBlock && successDict.count > 0) {
            if (successDict.count == 1) {
                _callback.successBlock(successDict.allValues.firstObject);
            }else{
                CSNettyResult *result = [[CSNettyResult alloc] init];
                result.data = successDict;
                result.state = CSNettyResultSuccess;
                result.duration = totalSuccessDuration;
                _callback.successBlock(result);
            }
        }
        if (_callback.failureBlock && failureDict.count > 0) {
            if (failureDict.count == 1) {
                _callback.failureBlock(failureDict.allValues.firstObject);
            }else{
                CSNettyResult *result = [[CSNettyResult alloc] init];
                result.data = failureDict;
                result.state = CSNettyResultFailure;
                result.duration = totalFailureDuration;
                _callback.failureBlock(result);
            }
        }
    }
}

-(void)__handleAsyncMultiRequestTask:(CSNettyResult *)result{
    
    [_HTTPReqests enumerateObjectsUsingBlock:^(CSNettyRequest*  _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([request.requestKey isEqualToString:result.requestKey]) {
            switch (result.state) {
                case CSNettyResultSuccess:
                    if(_callback.successBlock) _callback.successBlock(result);
                    break;
                case CSNettyResultFailure:
                    if(_callback.failureBlock) _callback.failureBlock(result);
                    break;
                default:
                    break;
            }
        }
    }];
    
}

-(void)__fininedAllTasks{
    [self _cleanupTaskKVO];
    
    [_HTTPReqests removeAllObjects];
    [_HTTPResults removeAllObjects];
    _completationCount = 0;
    _currentRequest = nil;
}

#pragma mark download delegate
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    CSNettyResult *result = [_HTTPResults objectForKey:task];
    if (error == nil) {
        result.state = CSNettyResultSuccess;
    }else{
        result.state = CSNettyResultFailure;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    [_HTTPReqests enumerateObjectsUsingBlock:^(CSNettyRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([request.dataTask isEqual:downloadTask]) {
            CSNettyResult *result = [_HTTPResults objectForKey:downloadTask];
            NSData *data =  [NSData dataWithContentsOfURL:location];
            result.data = [_responseSerialization handleContentType:downloadTask.response.MIMEType withData:data];
            result.state = CSNettyResultSuccess;
            if (request.cachePolicy > 0) {
                dispatch_async(get_cache_writing_queue(), ^{
                    [CSNettyCache saveCacheWith:request.urlRequest response:downloadTask.response data:data holdTime:-1 policy:request.cachePolicy];
                });
            }
            [self __vertifyDataTaskGroupWithResult:result];
        }
    }];
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics{
    CSNettyResult *result = [_HTTPResults objectForKey:task];
    if (result != nil) {
        result.duration = metrics.taskInterval.duration;
    }
}

-(void)dealloc{
    [self __fininedAllTasks];
    [self _cleanupTaskKVO];
}

#pragma mark private method
-(void)_setDelegateWithTask:(NSURLSessionTask *)dataTask request:(CSNettyRequest *)request{
    [dataTask addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    [dataTask addObserver:self forKeyPath:@"countOfBytesExpectedToReceive" options:NSKeyValueObservingOptionNew context:nil];
    [dataTask addObserver:self forKeyPath:@"countOfBytesSent" options:NSKeyValueObservingOptionNew context:nil];
    [dataTask addObserver:self forKeyPath:@"countOfBytesExpectedToSend" options:NSKeyValueObservingOptionNew context:nil];
    
    [request.downloadProgress addObserver:self
                               forKeyPath:@"fractionCompleted"
                                  options:NSKeyValueObservingOptionNew
                                  context:NULL];
    [request.uploadProgress addObserver:self
                             forKeyPath:@"fractionCompleted"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([object isKindOfClass:[NSURLSessionDataTask class]] || [object isKindOfClass:[NSURLSessionDownloadTask class]] || [object isKindOfClass:[NSProgress class]]) {
        
        __block int64_t downloadCompletedUnitCount = 0;
        __block int64_t downloadTotalUnitCount = 0;
        __block int64_t uploadCompletedUnitCount = 0;
        __block int64_t uploadTotalUnitCount = 0;
        
        [_HTTPReqests enumerateObjectsUsingBlock:^(CSNettyRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([object isEqual:request.dataTask]) {
                if ([keyPath isEqualToString:@"countOfBytesReceived"]) {
                    request.downloadProgress.completedUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                    _downloadProgress.completedUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                } else if ([keyPath isEqualToString:@"countOfBytesExpectedToReceive"]) {
                    if ([change[NSKeyValueChangeNewKey] longLongValue] > request.downloadProgress.totalUnitCount) {
                        request.downloadProgress.totalUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                        _downloadProgress.totalUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                    }
                } else if ([keyPath isEqualToString:@"countOfBytesSent"]) {
                    request.uploadProgress.completedUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                    _uploadProgress.completedUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                } else if ([keyPath isEqualToString:@"countOfBytesExpectedToSend"]) {
                    if ([change[NSKeyValueChangeNewKey] longLongValue] > request.uploadProgress.totalUnitCount) {
                        request.uploadProgress.totalUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                        _uploadProgress.totalUnitCount = [change[NSKeyValueChangeNewKey] longLongValue];
                    }
                }
            }
            downloadCompletedUnitCount += request.downloadProgress.completedUnitCount;
            downloadTotalUnitCount += request.downloadProgress.totalUnitCount;
            uploadCompletedUnitCount += request.uploadProgress.completedUnitCount;
            uploadTotalUnitCount += request.uploadProgress.totalUnitCount;
        }];
        
        
        if ([object isKindOfClass:[NSProgress class]]) {
            if (_callback.uploadProgressBlock) {
                if(uploadCompletedUnitCount >= _uploadProgress.completedUnitCount && uploadTotalUnitCount >= _uploadProgress.totalUnitCount) {
                    [self __uploadProgressWithCompletedCount:uploadCompletedUnitCount totalCount:uploadTotalUnitCount];
                }
            }
            if (_callback.downloadProgressBlock) {
                if(downloadCompletedUnitCount >= _downloadProgress.completedUnitCount && downloadTotalUnitCount >= _downloadProgress.totalUnitCount){
                    [self __downloadProgressWithCompletedCount:downloadCompletedUnitCount totalCount:downloadTotalUnitCount];
                    
                }else{
                    if (_downloadProgress.completedUnitCount > downloadCompletedUnitCount ) {
                        [self __downloadProgressWithCompletedCount:_downloadProgress.completedUnitCount totalCount:downloadTotalUnitCount];
                        
                    }else if(_downloadProgress.totalUnitCount > downloadTotalUnitCount){
                        [self __downloadProgressWithCompletedCount:downloadCompletedUnitCount totalCount:_downloadProgress.totalUnitCount];
                    }
                }
            }
        }
    }
}

-(void)__uploadProgressWithCompletedCount:(int64_t)completedCount totalCount:(int64_t)totalCount{
    
    if (completedCount == 0 && totalCount == 0) {
        CGFloat leftRate =  _completationCount * 1.0 / _HTTPResults.count;
        _uploadProgress.completedUnitCount = leftRate * _uploadProgress.totalUnitCount;
        if(_callback.uploadProgressBlock) _callback.uploadProgressBlock(_uploadProgress);
    }else{
        CGFloat leftRate =  _completationCount * 1.0 / _HTTPResults.count;
        CGFloat step = (completedCount * 1.0 / totalCount ) / _HTTPResults.count;
        completedCount =  (leftRate + step) * totalCount;
        _uploadProgress.completedUnitCount = completedCount;
        _uploadProgress.totalUnitCount = totalCount;
        if(_callback.uploadProgressBlock) _callback.uploadProgressBlock(_uploadProgress);
    }
    
}

-(void)__downloadProgressWithCompletedCount:(int64_t)completedCount totalCount:(int64_t)totalCount{
    
    CGFloat leftRate =  _completationCount * 1.0 / _HTTPResults.count;
    if (completedCount == 0 && totalCount == 0) {
        _downloadProgress.completedUnitCount = leftRate * _downloadProgress.totalUnitCount;
        if(_callback.downloadProgressBlock) _callback.downloadProgressBlock(_downloadProgress);
    }else{
        if (totalCount < _downloadProgress.totalUnitCount) {
            totalCount = _downloadProgress.totalUnitCount;
        }
        
        CGFloat step = 0.0;
        if (completedCount < totalCount) {
            step = (completedCount * 1.0 / totalCount ) / _HTTPResults.count;
        }
        
        if (_downloadProgress.fractionCompleted < (leftRate + step)) {
            completedCount =  (leftRate + step) * totalCount;
            _downloadProgress.completedUnitCount = completedCount;
            _downloadProgress.totalUnitCount = totalCount;
            if(_callback.downloadProgressBlock) _callback.downloadProgressBlock(_downloadProgress);
        }
    }
}

-(void)_cleanupTaskKVO{
    
    [_HTTPReqests enumerateObjectsUsingBlock:^(CSNettyRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
        [request.dataTask removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [request.dataTask removeObserver:self forKeyPath:@"countOfBytesExpectedToReceive"];
        [request.dataTask removeObserver:self forKeyPath:@"countOfBytesSent"];
        [request.dataTask removeObserver:self forKeyPath:@"countOfBytesExpectedToSend"];
        
        [request.downloadProgress removeObserver:self forKeyPath:@"fractionCompleted"];
        [request.uploadProgress removeObserver:self forKeyPath:@"fractionCompleted"];
    }];
}

-(void)__beforeRequest:(CSNettyRequest *)request{
    
}

-(void)__afterRequestWithRequset:(CSNettyRequest *)request{
    
}

-(void)__beforeFinishedWithRequest:(CSNettyRequest *)request{
    
}

-(void)__afterFinishedWithRequest:(CSNettyRequest *)request{
    
}

-(void)__setUserAgent{
    NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if TARGET_OS_IOS
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_WATCH
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
#pragma clang diagnostic pop
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [_currentRequest.urlRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
}

-(void)__setupRequestEncodingWith:(CSNettyRequest *)request{
    
    if (request.attachedDataArray.count > 0) {
        request.requestEncoding = CSNettyMuiltipartEncoding;
    }
    
    switch (request.requestEncoding) {
        case CSNettyFormEncoding:{
            request.urlRequest.HTTPBody = [[CSNettyEncrypt urlEncodedKeyValueStringWithDictionary:_currentRequest.params] dataUsingEncoding:NSUTF8StringEncoding];
            [request.urlRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded"]forHTTPHeaderField:@"Content-Type"];
            [request.urlRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [_currentRequest.urlRequest.HTTPBody length]]
                      forHTTPHeaderField:@"Content-Length"];
        }
            break;
        case CSNettyMuiltipartEncoding:{
            NSString *boundary = _createMultipartFormBoundary();
            [request.urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary] forHTTPHeaderField:@"Content-Type"];
            NSMutableData *formData = [NSMutableData data];
            // parameters
            [request.params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *thisFieldString = [NSString stringWithFormat:
                                             @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                             boundary, key, obj];
                [formData appendData:[thisFieldString dataUsingEncoding:NSUTF8StringEncoding]];
                [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            }];
            
            // files
            [request.attachedDataArray enumerateObjectsUsingBlock:^(CSNettyAttachData *attachData, NSUInteger idx, BOOL *stop) {
                NSString *boundaryString = [NSString stringWithFormat:
                                            @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                            boundary,
                                            attachData.name,
                                            attachData.fileName,
                                            attachData.mimeType];
                [formData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
                [formData appendData:attachData.formData];
                [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            }];
            
            [formData appendData: [[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            request.urlRequest.HTTPBody = formData;
            [request.urlRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [_currentRequest.urlRequest.HTTPBody length]]
                      forHTTPHeaderField:@"Content-Length"];
        }
            break;
        case CSNettyURLEncoding:{
            [request.urlRequest setValue:nil forHTTPHeaderField:@"Content-Type"];
            [request.urlRequest setValue:nil forHTTPHeaderField:@"Content-Length"];
            NSString *url = [NSString stringWithFormat:@"%@?%@",_currentRequest.urlRequest.URL.absoluteString,[CSNettyEncrypt urlEncodedKeyValueStringWithDictionary:_currentRequest.params]];
            request.urlRequest.URL = [NSURL URLWithString:url];
            request.urlRequest.HTTPBody = nil;
            break;
        }
        default:
            break;
    }
}

@end
