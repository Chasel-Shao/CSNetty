//
// CSNettyResult.m
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

#import "CSNettyResult.h"
#if __has_include(<CSModel/CSModel.h>)
#import <CSModel/CSModel.h>
#else
#import "CSModel.h"
#endif


@implementation CSNettyResult


-(id)dataToModel{
    if (_dataModelClass) {
        if ([_dataModelClass resolveClassMethod:@selector(cs_modelWithJSONObject:)]) {
            return [_dataModelClass cs_modelWithJSONObject:_data];
        }
    }
    return nil;
}

-(NSArray *)dataToModelArray{
    if (_dataModelClass) {
        if ([_dataModelClass resolveClassMethod:@selector(cs_modelArrayWithJSONObject:)]) {
            return [_dataModelClass cs_modelArrayWithJSONObject:_data];
        }
    }
    return nil;
}


-(CSNettyResult *) objectForKeyedSubscript:(id)key {
    if ([_requestKey isEqualToString:key]) {
        return self;
    }else{
        if (_data != nil && [_data isKindOfClass:[NSDictionary class]]) {
            __block CSNettyResult *result = nil;
            [((NSDictionary *)_data) enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull requestKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([requestKey isEqualToString:key]) {
                    result = obj;
                    *stop = YES;
                }
            }];
            return result;
        }
    }
    return nil;
}

-(NSInteger)countOfData{
    if (_data != nil && [_data isKindOfClass:[NSDictionary class]]) {
        return ((NSDictionary *)_data).count;
    }else if(_data != nil){
        return 1;
    }else{
        return 0;
    }
}


@end
