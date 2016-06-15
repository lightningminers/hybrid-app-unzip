//
//  ViewController.m
//  unzip
//
//  Created by xiangwenwen on 15/10/9.
//  Copyright © 2015年 xiangwenwen. All rights reserved.


#import "ViewController.h"
#import "unzip-Swift.h"

@interface ViewController () 

@end
//
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1 ---> %@",[NSThread currentThread]);
    }];
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2 ---> %@",[NSThread currentThread]);
    }];
    [operation1 addDependency:operation2];
    [queue addOperation:operation1];
    [operation1 cancel];
    [queue addOperation:operation2];

    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        
    }];
    [queue addOperation:operation3];
    
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
    [[Date alloc] init];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
