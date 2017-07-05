CSNetty
==============

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/Chasel-Shao/CSNetty/master/LICENSE)&nbsp;
[![CocoaPods](http://img.shields.io/cocoapods/v/CSNetty.svg?style=flat)](http://cocoapods.org/pods/CSNetty)&nbsp;

[:book: English Documentation](README.md) | :book: 中文文档

CSNetty 是一个优雅强大的网络框架，基于NSURLSession实现，并使用链式语法提供了简洁的调用方式。



特性
==============

- 简洁的链式语法
- 异步的HTTP请求，使用block回调
- 支持不同Content-Type设置不同的的序列化方法
- 提供面向切面的方法，能在不同的生命周期过程中回调方法
- 具有HTTP缓存机制，并设置不同的缓存方式和缓存时间
- 直接发起多个请求，可以异步回调结果或者同步一次返回
- 支持监听上传和下载的进度，也包括监听多个请求的上传下载总进度


使用方法
==============

### 简单的GET和POST使用方法
```objc
// 0. 设置URL路径
NSURL *url = [NSURL URLWithString:@"http://github.com"];

// 1. 使用GET方法
CSNettyManager
.GET(url)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 2. 使用POST方法
CSNettyManager
.POST(url)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 3. 参数的传递
NSDictionary *params = @{@"account":@"Ares",@"passowrd":@"1234567"};
CSNettyManager
.POST(url)
.addParam(params)
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 4. 设置HTTP头部信息
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
### 设置缓存机制
```objc
// 1. 默认不使用缓存（CSNettyCachePolicyNone）
.setCachePolicy(CSNettyCachePolicyNone)

// 2. 使用硬盘持久存储缓存
.setCachePolicy(CSNettyCachePolicyDisk)

// 3. 使用内存临时存储缓存
.setCachePolicy(CSNettyCachePolicyMemory)

// 4. 设置缓存有效时间
.setCacheExpiredTime(7 * 24 * 3600)

// 5. 读取缓存后的回调
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} cache:^(CSNettyResult *response) {
	// cache 
} failure:^(CSNettyResult *response) {
	// failure
}]);

// 6. 或者手动初始化CSNettyCallback
CSNettyCallback *callback = [[CSNettyCallback alloc] init];
callback.cacheBlock = ^(CSNettyResult *result){
	// handle code
};
// 然后使用send方法
.send(callback)

```
### 设置自定义序列化方法
```objc
// 先设置Content-Type对应的回调方法
CSNettyResponseSerialization *responseSerialization = [CSNettyResponseSerialization defaultResponseSerialize];
[responseSerialization addContentType:[NSSet setWithObject:@"text/html"] withHandleBlock:^id(NSData *data) {
    // custom serialization code
    return responseData;
}];
// 再设置回调对象
.setResponseSerialzation(responseSerialization)

```
### 设置请求过程中的拦截方法
```objc
// 设置拦截对象和方法
CSNettyAspect *dispose = [[CSNettyAspect alloc] init];
dispose.beforeResponseWithBlock = ^id(id data) {
   // custom handle code
   return handledData;
};

// 再设置拦截对象
.setAspectDispose(dispose)

```
### 监听上传下载的进度
```objc
// 1. 使用CSNettyCallback的工厂方法，直接构建回调对象
[CSNettyCallback success:^(CSNettyResult *response) {
	// success
} uploadProgress:^(NSProgress *progress) {
	// upload progress
} downloadProgressprogress:^(NSProgress *progress) {
	// download progress
} failure:^(CSNettyResult *response) {
    // failure 
}];

// 2. 或者手动设置回调的函数
CSNettyCallback *callback = [[CSNettyCallback alloc] init];
callback.uploadProgressBlock = ^(NSProgress *progress) {
     // upload progress  
};
callback.downloadProgressBlock = ^(NSProgress *progress) {
	// download progress    
};

// 最后使用send方法
.send(callback)

```
### 设置多个请求
```objc
// 第一个请求
CSNettyManager
.POST(url)
.addHeader(headerDict)
.setResponseSerialzation(responseSerialization)
.setCachePolicy(CSNettyCachePolicyDisk)
.setCacheExpiredTime(7 * 24 * 3600)
// 第二个请求
.get(url)
.addParam(params)
.setCachePolicy(CSNettyCachePolicyMemory)
.setTimeout(30)
// 第三个请求
.get(url)
// 设置结果回调的形式，设置为 CSNettyMultiResponseSync 所有请求最后回调一次
// 若设置为CSNettyMultiResponseAsyn，每个请求都产生一次回调
.setMultiRequestPolicy(CSNettyMultiResponseSync)
// 结果回调
.send([CSNettyCallback success:^(CSNettyResult *response) {
	// success
} cache:^(CSNettyResult *response) {
	// cache
} failure:^(CSNettyResult *response) {
	// failure
}]);
```
安装
==============
### CocoaPods

1. 在 Podfile 中添加 `pod 'CSNetty'`
2. 执行 `pod install` 或 `pod update`
3. 导入 \<CSNetty/CSNetty.h\>

### 手动集成
1. 下载 CSNetty 源文件
2. 然后导入到项目文件中，并引用 CSNetty.h 头文件

系统要求
==============
该项目最低支持 `iOS 7.0`


作者
==============
- [Chasel-Shao](https://github.com/Chasel-Shao) 753080265@qq.com


许可证
==============
CSNetty 使用 MIT 许可证，详情见 LICENSE 文件。


