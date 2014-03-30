//
//  ViewController.h
//  DownloadIOS7
//
//  Created by Lombardo on 10/11/13.
//  Copyright (c) 2013 Lombardo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *url;
- (IBAction)start:(id)sender;
- (IBAction)startAlternative:(id)sender;

// upload
@property (strong, nonatomic) IBOutlet UITextField *uploadText;
- (IBAction)startUpload:(id)sender;

@end
