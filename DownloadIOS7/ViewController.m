//
//  ViewController.m
//  DownloadIOS7
//
//  Created by Lombardo on 10/11/13.
//  Copyright (c) 2013 Lombardo. All rights reserved.
//

#import "ViewController.h"
#import "FLDownload.h"

@interface ViewController ()

@end

@implementation ViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender {
    NSURL *url = [NSURL URLWithString:self.url.text];
    
    FLDownload *download = [[FLDownload alloc] initBackgroundDownloadWithURL:url completion:^(BOOL success, NSError *error) {
        NSLog(@"Success: %i", success);
    }];
    
    [download setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"%qi, %qi, %qi", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
    [download start];
}
@end
