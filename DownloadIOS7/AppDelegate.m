//
//  AppDelegate.m
//  DownloadIOS7
//
//  Created by Lombardo on 10/11/13.
//  Copyright (c) 2013 Lombardo. All rights reserved.
//

#import "AppDelegate.h"
#import "FLDownload.h"

@implementation AppDelegate

void fllog(NSString *aString)
{
    NSString *url = (NSString *)[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
    NSString *document = [url stringByAppendingPathComponent:@"File.txt"];
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:document])
    {
        [[aString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:document options:NSDataWritingAtomic error:&error];
    } else {
        NSData *data = [NSData dataWithContentsOfFile:document];
        NSMutableString *log = nil;
        if (data)
            log = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] mutableCopy];
        else
            log = [NSMutableString string];
        
        [log appendString:@"\n"];
        [log appendString:aString];
        
        NSData *finalData = [log dataUsingEncoding:NSUTF8StringEncoding];
        
        [[NSFileManager defaultManager] removeItemAtPath:document error:nil];
        
        [finalData writeToFile:document options:NSDataWritingAtomic error:&error];
    }
    


}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    fllog(@"application lauched");
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    
    fllog(@"application handle event");
    
    NSURL *url = [NSURL URLWithString:identifier];
    
    
    [FLDownload resumeDownloadForSession:url];
    
    fllog(@"application finished handling event");
    
    completionHandler();
    
    
}




@end
