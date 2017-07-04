//
// CSNettyManager.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CSNettyManager,CSNettyCallback,CSNettyResult,CSNettyResponseSerialization,CSNettyResult,CSNettyAttachData,CSNettyAspect;

/**
 Encode the paramters related to the HTTP method, and may set the value of
 `Content-Type` in the request header or serializes the query string parameters.
 
 - CSNettyURLEncoding: combines the paramters by the way of url encode
 - CSNettyFormEncoding: the `Content-Type` of the request is set to `application/x-www-form-urlencoded`
 - CSNettyMuiltipartEncoding: the `Content-Type` of the request is set to `multipart/form-data`
 */
typedef NS_ENUM(NSUInteger, CSNettyEncoding) {
    CSNettyURLEncoding            = 0,
    CSNettyFormEncoding           = 1,
    CSNettyMuiltipartEncoding     = 2,
};

/**
 Define The current HTTP request method.
 
 - CSNettyMethodGET: GET Request
 - CSNettyMethodPOST: POST Request
 - CSNettyMethodDownload: POST Request in a specific background
 */
typedef NS_ENUM(NSUInteger, CSNettyMethod) {
    CSNettyMethodGET              = 0,
    CSNettyMethodPOST             = 1,
    CSNettyMethodDownload         = 2
};

/**
 Provides the Network cache function with different function.
 
 - CSNettyCachePolicyNone: do not use cache function
 - CSNettyCachePolicyMemory: store the cache in memory
 - CSNettyCachePolicyDisk: sotre the cache in disk
 */
typedef NS_ENUM(NSUInteger, CSNetwortCachePolicy) {
    CSNettyCachePolicyNone        = 0,
    CSNettyCachePolicyMemory      = 1,
    CSNettyCachePolicyDisk        = 2,
};

/**
 Provide different ways for the callback of concurrent responses, the callback block
 include the  `successBlock` , `failureBlock`, adn `cacheBlock`, then return the `CSNettyResult`
 
 - CSNetwortMultiResponseSync: excute the block  until all the response completion
 - CSNetwortMultiResponseAsyn: excute the block at the time of every reponse completion
 */
typedef NS_ENUM(NSUInteger, CSNetwortMultiResponsePolicy) {
    CSNetwortMultiResponseSync       = 0,
    CSNetwortMultiResponseAsyn       = 1
};

/**
 Sets the priority for every request, and this priority is correspond to the
 `NSURLSessionTaskPriority`.
 
 - CSRequestPriorityLow: correspond to NSURLSessionTaskPriorityLow
 - CSRequestPriorityDefault: correspond toNSURLSessionTaskPriorityDefault
 - CSRequestPriorityHigh: correspond to NSURLSessionTaskPriorityHigh
 */
typedef NS_ENUM(NSInteger, CSRequestPriority) {
    CSNetwrokRequestPriorityLow       = -1,
    CSNetwrokRequestPriorityDefault   = 0,
    CSNetwrokRequestPriorityHigh      = 1,
};

/**
 The final callback for response which take an argumet : `CSNettyResult`.
 */
typedef void (^CSNettyResponse)(CSNettyResult *response);

/**
 Indicate the upload or download process of a request.
 */
typedef void (^CSNettyProgress)(NSProgress *progress);

/**
 CSNetty is a powerful and elegant HTTP client framework for iOS/OSX.
 And the adopting of chaining syntax make it easy to use.
 It has many features:
 
 * Supports chain syntax and bath requests
 * Provides the cache mechenism and has various types of cache policy
 * Customs the different content-type with specific callback method
 * Monitors the progress of uploading and downloading during the time of requesting
 
 */
@interface CSNettyManager : NSObject

/**
 Create and return the instance with request method,
 it only support GET and POST request at present.
 */
+(CSNettyManager *(^)(NSURL *url))GET;
+(CSNettyManager *(^)(NSURL *url))POST;

///----------------
/// @name method
///----------------

/**
 Set `GET` request with the specified base URL.
 and return the `CSNetty` object
 */
-(CSNettyManager *(^)(NSURL *url))get;
/**
 Set `POST` request with the specified base URL.
 and return the `CSNetty` object
 */
-(CSNettyManager *(^)(NSURL *url))post;
/**
 Set `POST` request with the specified base URL to upload file.
 and return the `CSNetty` object
 */
-(CSNettyManager *(^)(NSURL *url))upload;
/**
 Download with the specified base URL. This method will use `NSURLSessionDownloadTask`
 to download file and return the `CSNetty` object
 */
-(CSNettyManager *(^)(NSURL *url))download;
/**
 Send requests with the `CSNettyCallback` instance which contains specified block,
 in which you can define some custom method to process different callback, such as `successBlock`,
 `failureBlock`, `cacheBlock` etc.
 */
-(CSNettyManager *(^)(CSNettyCallback *callback))send;

///-----------------------------
/// @name Request configuration
///-----------------------------

/**
 Sets the value to HTTP header with a dictionary.
 */
-(CSNettyManager *(^)(NSDictionary *header))addHeader;

/**
 Appends the parameters for the HTTP request with a dictionary.
 */
-(CSNettyManager *(^)(NSDictionary *params))addParam;

/**
 Sets the timeout of a HTTP request, This request will be hold on
 until the server response or request timeout.
 */
-(CSNettyManager *(^)(NSTimeInterval timeout))setTimeout;

/**
 Sets the request key for a specific request, and the request key must be unique.
 The default value of request key is the absolute string of url.
 */
-(CSNettyManager *(^)(NSString *key))setRequestKey;

/**
 Set the model class for the transformation of the response json to a object, so
 response serialization may need to be configured to make the formation of the json adapt
 to the properties of the model class.
 */
-(CSNettyManager *(^)(__unsafe_unretained Class cls))setDataModelClass;

/**
 If a couple of request be send simultaneously, those responses can be synchronization and
 asynchronization.
 The default value is `CSNettyMultiResponseSync` which means the callback
 only can be excute until the HTTP client receives all the response.
 */
-(CSNettyManager *(^)(CSNetwortMultiResponsePolicy policy))setMultiRequestPolicy;

/**
 Sets the max number of concurrent request, if the number of request is beyond the limit,
 those exceeding requests will be put into waiting queue.
 */
-(CSNettyManager *(^)(NSInteger count))setConcurrenceCount;

/**
 Sets the priority of the current request, which corresspond to the different `NSURLSessionTaskPriority`
 with the specific `CSRequestPriority`.
 */
-(CSNettyManager *(^)(CSRequestPriority priority))setRequestPriority;

/**
 Set the way of request parameter encoding, and the request header of `Content-Type` may be set.
 */
-(CSNettyManager *(^)(CSNettyEncoding encoding))setRequestSerialization;

/**
 Provides different mime-types with specific block to process this kind of raw `NSData *`.
 */
-(CSNettyManager *(^)(CSNettyResponseSerialization *serialization))setResponseSerialzation;

/**
 Provides various opportunities to callback in a process of the request, for example,
 define the `beforeRequestBlock` block to process the raw data before the finial callback with
 the `CSNettyDispose` object.
 */
-(CSNettyManager *(^)(CSNettyAspect *dispose))setAspectDispose;

///---------------------
/// @name attached data
///---------------------

/**
 Creates the `CSNettyAttachData` to upload, which will lead to the `Content-Type` filed of the request header
 be set to `multipart/form-data`.
 */
-(CSNettyManager *(^)(CSNettyAttachData *attachData))addAttachData;


///------------------
/// @name cache data
///------------------

/**
 Determine use the network cache with a policy, the default is not use cache mechanism,
 - The `CSNettyCachePolicyMemory` option means the cache only be stored in memory, when the
 application is terminated, the cache will be clear up.
 - The `CSNettyCachePolicyDisk` option means that the cache be stored in disk, which can be
 persistent for a long time until the cache data is expired.
 */
-(CSNettyManager *(^)(CSNetwortCachePolicy cachePolicy))setCachePolicy;

/**
 Set the expiration time of cache data, and the cache mechanism should be allowed, otherwise
 there is no effect.
 */
-(CSNettyManager *(^)(NSTimeInterval expiredTime))setCacheExpiredTime;

/**
 Cleans up all the cache data, no matter in memory or in the disk.
 */
-(CSNettyManager *(^)())clearCache;

@end

NS_ASSUME_NONNULL_END

