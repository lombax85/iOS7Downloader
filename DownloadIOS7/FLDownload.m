//
//  FLDownload.m
//  DownloadIOS7
//
//  Created by Lombardo on 10/11/13.
//  Copyright (c) 2013 Lombardo. All rights reserved.
//
//  NOTE: App States:
//  The app can be in one of this states:
//
//  - running
//  - suspended (the download continue in background, then the app is awaken and AppDelegate called. All objects are still living so no need to recreate the download)
//  - killed by the system, (the download continue in background, then the app is awakend and AppDelegate called. Since the objects are no more living, we need to create again them using resumeFromBackground method. This method recreates the session object. The download object doesn't need to be recreated
//  - killed by the user (the download is suspended and sometimes need to be recreated)

#import "FLDownload.h"


/**
 A list of download objects
 */
static NSMutableDictionary *_downloads;

/**
 Constant to archive - unarchive Downloads dictionary
 */
static NSString *kFLDownloadUserDefaultsObject = @"kFLDownloadUserDefaultsObject";

/**
 Constants for NSCoding
 */
static NSString *kFLDownloadEncodedURL = @"kFLDownloadEncodedURL";
static NSString *kFLDownloadEncodedDestinationDirectory = @"kFLDownloadEncodedDestinationDirectory";


@interface FLDownload ()

/**
 Weak reference since NSURLSession retains it's delegate <-- EDIT -> many bad access with weak
*/
@property (strong, nonatomic) NSURLSession *session;

/**
 Is Downloading?
 */
@property (nonatomic, readwrite) BOOL isDownloading;

@end


@implementation FLDownload

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _completionBlock = ^(BOOL success, NSError *error){};
        _url = nil;
        _destinationDirectory = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] absoluteString];
        _isDownloading = NO;
    }
    return self;
}

-(id)initBackgroundDownloadWithURL:(NSURL *)url completion:(void (^)(BOOL success, NSError *error))completion
{
    self = [self init];
    if (self) {
        if (completion)
            _completionBlock = [completion copy];
        _url = url;
    }
    return self;
}

// initWithCoder at the end of the file

#pragma mark - Public methods

/**
 This method lists all the downloads started.
 First, if _downloads is not set, it tries to unarchive a list of downloads from NSUserDefaults (list of download not completed). Then, if the list is empty, initialize a new NSMutableDictionary
 You should save the dictionary to NSUserDefaults with [self saveDownloads] every time an object is added or removed.
 */
+(NSDictionary *)downloads;
{
    if (!_downloads)
    {
        NSData *downloadData = [[NSUserDefaults standardUserDefaults] objectForKey:kFLDownloadUserDefaultsObject];
        NSDictionary *loadedDownload = [NSKeyedUnarchiver unarchiveObjectWithData:downloadData];
        
        if (!loadedDownload || ![loadedDownload isKindOfClass:[NSDictionary class]])
        {
            _downloads = [NSMutableDictionary dictionary];
        } else {
            _downloads = [loadedDownload mutableCopy];
        }
    }
    
    return [[NSDictionary alloc] initWithDictionary:_downloads];
}

/**
 This method must be called only by - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
 */
+(void)resumeDownloadForSession:(NSURL *)session
{
    /* to resume a download operation (that has been completed) from background there are two different workflows:
     1 - The app is in suspended state, then the download is finished:
     - the system calls - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
     - the user must call +(void)resumeDownloadForSession:(NSURL *)session passing the session url
     - we do nothing, because all objects are already created. The system forward the correct delegate calls
     
     2 - The app is in the killed state (killed by the system, not the user), then the download is finished:
     - the system relaunch app and calls - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
     - the user must call +(void)resumeDownloadForSession:(NSURL *)session passing the session url
     - we check that the download does not exist inside the list (the app has just been lauched from killed state, so the objects are not initialized), so we alloc-init a new FLDownload object and call resumeFromBackground (which recreates a NSURLSession object setting the delegate)
     */
    
    // change the current state
    
    if (![[FLDownload downloads] objectForKey:[session absoluteString]])
    {
        // the app was previously killed
        FLDownload *download = [[FLDownload alloc] initBackgroundDownloadWithURL:session completion:nil];
        [download resumeFromBackground];
    }
}

/**
 Start a download
 */
-(void)start
{
    // check that all has been set correctly
    if (!self.url)
    {
        NSException *exception = [NSException exceptionWithName:@"Set all Properties" reason:@"You must give an URL" userInfo:nil];
        [exception raise];
    }
    
    // create a new session configuration. Use the url string as identifier to retrieve the download later
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.url.absoluteString];
    
    // create the download session - must use delegate because completion block are not supported for background downloads
    self.session = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
    
    // add the FLDownload object to the dictionary - if not exists:
    
    if (![_downloads objectForKey:self.url.absoluteString])
    {
        // init downloads (look implementation)
        [FLDownload downloads];
        
        // add the download to the list - dictionary of downloads
        [_downloads setObject:self forKey:self.url.absoluteString];
        
        // save the downloads dictionary to disk
        [self saveDownloads];
        
        // put the download object in the local strong variable
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:self.url];
        
        // start the download
        [downloadTask resume];
        
        self.isDownloading = YES;
        
    } else {
        // you are already downloading this file
        NSError *error = [NSError errorWithDomain:@"FLDownloadAlreadyDownloadingThisURL" code:999 userInfo:nil];
        self.completionBlock(NO, error);
        [self dispose];
    }
}

/**
 Stop a download
 */
-(void)stop
{
    // recreate the session if not exists
    if (!self.session)
    {
        NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.url.absoluteString];
        
        self.session = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
    }
    
    [self dispose];
}


/**
 Call this method only to resume a download that is in the saved to disk "list" and is not running
 This could happen when the user kills the app: the download are stopped, and they need to be restarted manually.
 Moreover, even if the app is killed by the system (and not by the user) we need to re-connect the FLDownload instance with the relative NSURLSession. Then, the tasks should be restarted automatically (we check it using 'getTasksWithCompletionHandler' and starting it if it's needed)
 */
-(void)resumeFromKilledState
{
    // check that all has been set correctly
    if (!self.url)
    {
        NSException *exception = [NSException exceptionWithName:@"Set all Properties" reason:@"You must give an URL" userInfo:nil];
        [exception raise];
    }
    // create a new session configuration. Use the url string as identifier to retrieve the download later
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.url.absoluteString];
    
    // create the download session - must use delegate because completion block are not supported for background downloads
    self.session = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
    
    // When resuming a session after the app was killed, you MUST NOT RECREATE the download task. The task is recreated automatically by the session and then finished (calling the delegate methods)
    
    
    // get the download tasks. If the app was in the state "killed by the system" with download in progress, I will find it inside the downloadTasks array. Otherwise, I start it again from the beginning
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        // since I make only one download task per session, it's safe to call lastObject
        NSURLSessionDownloadTask *task = [downloadTasks lastObject];
        
        if (task)
        {
            if (task.state != NSURLSessionTaskStateRunning)
                // start the download
                [task resume];
            

            self.isDownloading = YES;
            
        } else {
            // recreate the task
            NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:self.url];
            if (downloadTask.state != NSURLSessionTaskStateRunning)
                // start the download
                [downloadTask resume];
            

            self.isDownloading = YES;
        }
    }];
}

#pragma mark - Private Methods

/**
 Clear the download and free the object
 */
-(void)dispose
{
    // remove the object from the dictionary
    [_downloads removeObjectForKey:self.url.absoluteString];
    
    [self.session invalidateAndCancel];
    [self.session flushWithCompletionHandler:^{
        
        self.isDownloading = NO;
        [self saveDownloads];
        
        // break the retain cycle and release FLDownload, last thing to be called
        self.session = nil;
    }];
}

/**
 Save the download list to the disk
 */
-(void)saveDownloads
{

    if ([_downloads count] > 0)
    {
        NSData *notFinishedDownloads = [NSKeyedArchiver archivedDataWithRootObject:_downloads];
        [[NSUserDefaults standardUserDefaults] setObject:notFinishedDownloads forKey:kFLDownloadUserDefaultsObject];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFLDownloadUserDefaultsObject];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


/**
 This method is called only if the app was previously in killed state (killed by the system, not by the user). If the app was suspended, no need to recreate the NSURLSession
 */
-(void)resumeFromBackground
{
    self.isDownloading = YES;
    
    // check that all has been set correctly
    if (!self.url)
    {
        NSException *exception = [NSException exceptionWithName:@"Set all Properties" reason:@"You must give an URL" userInfo:nil];
        [exception raise];
    }
    // create a new session configuration. Use the url string as identifier to retrieve the download later
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.url.absoluteString];
    
    // create the download session - must use delegate because completion block are not supported for background downloads
    self.session = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
    
}

#pragma mark - Setters and Getters

- (NSString *)fileName
{
    return [NSString stringWithString:[self.url.absoluteString lastPathComponent]];
}

#pragma mark - NSURLSessionDownloadDelegate

/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{

    NSError *error = nil;
    
    // the file name and final location
    NSURL *finalLocation = [NSURL URLWithString:[NSString stringWithFormat:@"file:///%@/%@", self.destinationDirectory, self.fileName]];
    
    // move the file
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:location toURL:finalLocation error:&error];
    
    // clean
    [self dispose];
    
    // NOTE: the completion handler MUST BE CALLED AT THE END otherwise the "delegate" is alerted when the 'isDownloading' var is still YES and the FLDownload instance is still in the static dictionary
    if (!success)
    {
        NSLog(@"Error moving file: %@ to destination %@. Error: %@", [location absoluteString], [finalLocation absoluteString], error.description);
        self.completionBlock(NO, error);
    } else {
        self.completionBlock(YES, nil);
        NSLog(@"File moved to: %@", finalLocation);
    }
    
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (self.progressBlock)
        self.progressBlock([NSURL URLWithString:session.configuration.identifier], bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"Download resumed");
}


#pragma mark - NSURLSessionDelegate

/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case it will receive an
 * { NSURLErrorDomain, NSURLUserCanceled } error.
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    [self dispose];
}

/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"Finish");
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:kFLDownloadEncodedURL];
    [aCoder encodeObject:self.destinationDirectory forKey:kFLDownloadEncodedDestinationDirectory];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        _url = [aDecoder decodeObjectForKey:kFLDownloadEncodedURL];
        _destinationDirectory = [aDecoder decodeObjectForKey:kFLDownloadEncodedDestinationDirectory];
        
        // start
        
    }
    return self;
}



@end
