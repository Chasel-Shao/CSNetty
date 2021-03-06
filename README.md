CSNetty
==============

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/Chasel-Shao/CSNetty/master/LICENSE)&nbsp;
[![CocoaPods](http://img.shields.io/cocoapods/v/CSNetty.svg?style=flat)](http://cocoapods.org/pods/CSNetty)&nbsp;

:book: English Documentation | [:book: 中文文档](README-CN.md)


Introduce
==============

CSNetty is a powerful and elegant HTTP client framework for iOS/OSX. It besed on NSURLSession, and the adopting of chaining syntax make it easy to use. 

Features
==============

- Support graceful chain syntax
- Asynchronous requests with the block callback
- Define different function to process the specific Content-Type
- Provide intercept methods to callback in the process of lifecycle
- Possess the HTTP cahce mechanism with various policies
- Support batch requests with the asynchronous return or synchronous return
- Monitor the process of uploding and downloading during the period of the request

Getting Started
==============

### A graceful way to use GET and POST
```objc
// 0. Specify the url
NSURL *url = [NSURL URLWithString:@"http://github.com"];

// 1. GET Method
CSNettyManager
.GET(url)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 2. POST Method
CSNettyManager
.POST(url)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 3. Pass parameters
NSDictionary *params = @{@"account":@"Ares",@"passowrd":@"1234567"};
CSNettyManager
.POST(url)
.addParam(params)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 4. Set HTTP Header
NSDictionary *headerDict = @{@"AESTOKEN":@"......",@"Content-Type":@"text/plain;charset=UTF-8"};
CSNettyManager
.POST(url)
.addParam(params)
.addHeader(headerDict)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

```
### Configure the HTTP cache
```objc
// 1. The default is not use the Cache(CSNettyCachePolicyNone）
.setCachePolicy(CSNettyCachePolicyNone)

// 2. Use the disk to store the Cache
.setCachePolicy(CSNettyCachePolicyDisk)

// 3. Use the temporary memory to store the Cache
.setCachePolicy(CSNettyCachePolicyMemory)

// 4. Set the expired time
.setCacheExpiredTime(7 * 24 * 3600)

// 5. Define the callback to read the Cache
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} cache:^(CSNettyResult *response) {
	// cache 
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 6. Or Set the `CSNettyCallback` with the Cache callback separately
CSNettyCallback *callback = [[CSNettyCallback alloc] init];
callback.cacheBlock = ^(CSNettyResult *result){
	// handle code
};
// then invoke the `send` method
.send(callback)

```
### Customize serialization with the specific Content-Type
```objc
// Create the callback method with specific Content-Type
CSNettyResponseSerialization *responseSerialization = [CSNettyResponseSerialization defaultResponseSerialize];
[responseSerialization addContentType:[NSSet setWithObject:@"text/html"] withHandleBlock:^id(NSData *data) {
    // custom serialization code
    return responseData;
}];
// then set this serialization instance
.setResponseSerialzation(responseSerialization)

```
### Set the intercept method during the period of the request
```objc
// Define the intercept method with the block
CSNettyAspect *dispose = [[CSNettyAspect alloc] init];
dispose.beforeResponseWithBlock = ^id(id data) {
   // custom handle code
   return handledData;
};

// then set this instance
.setAspectDispose(dispose)

```
### Monitor the progress
```objc
// 1. Use the CSNettyCallback factory method to create the instance
[CSNettyCallback success:^(CSNettyResult *response) {
	// success
} uploadProgress:^(NSProgress *progress) {
	// upload progress
} downloadProgressprogress:^(NSProgress *progress) {
	// download progress
} failure:^(CSNettyResult *response) {
    // failure 
}];

// 2. Or create the CSNettyCallback instance manually
CSNettyCallback *callback = [[CSNettyCallback alloc] init];
callback.uploadProgressBlock = ^(NSProgress *progress) {
     // upload progress  
};
callback.downloadProgressBlock = ^(NSProgress *progress) {
	// download progress    
};

// then set the instance
.send(callback)

```
### Batch requests
```objc
// The first request
CSNettyManager
.POST(url)
.addHeader(headerDict)
.setResponseSerialzation(responseSerialization)
.setCachePolicy(CSNettyCachePolicyDisk)
.setCacheExpiredTime(7 * 24 * 3600)
// The second request
.get(url)
.addParam(params)
.setCachePolicy(CSNettyCachePolicyMemory)
.setTimeout(30)
// The third request
.get(url)
// Set the way of result callback :
// CSNettyMultiResponseSync : wait for all the requests and return once
// CSNettyMultiResponseAsyn : each request to trigger a return 
.setMultiRequestPolicy(CSNettyMultiResponseSync)
// set callback
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} cache:^(CSNettyResult *response) {
	// cache
} failure:^(CSNettyResult *response) {
	// failure
}]);
```
Installation
==============
### Install with CocoaPods

1. Specify the `pod 'CSNetty'` to Podfile
2. Run `pod install` or `pod update`
3. Import the header file \<CSNetty/CSNetty.h\>

### Install manually 
1. Download the CSNetty source files
2. Intergrate the related source files

Prerequisition
==============

The minimum support version is `iOS 7.0`

Author
==============
- [Chasel-Shao](https://github.com/Chasel-Shao) 753080265@qq.com

License
==============
CSNetty is released under the MIT license. See LICENSE for details.


