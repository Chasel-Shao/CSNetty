//
//  ViewController.m
//  CSNettyExample
//
//  Created by sweet on 2017/7/4.
//  Copyright © 2017年 chasel. All rights reserved.
//

#import "ViewController.h"
#import "CSNetty.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    CSNettyManager
    .GET([NSURL URLWithString:@"http://www.github.com"])
    .send([CSNettyCallback success:^(CSNettyResult *response) {
        NSLog(@"%@",response.data);
    } failure:^(CSNettyResult *response) {
        NSLog(@"%@",@"failure");
    }]);
    
    
}


@end
