//
//  FLDownload.m
//  DownloadIOS7
//
//  Created by Lombardo on 10/11/13.
//  Copyright (c) 2013 Lombardo. All rights reserved.
//

#import "FLDownload.h"


/**
 A list of download objects
 */
static NSMutableDictionary *_downloads;

@interface FLDownload ()

@property (copy, nonatomic) NSString *fileName;

// Weak reference since NSURLSession retains it's delegate
@property (weak, nonatomic) NSURLSession *session;

@end

@implementation FLDownload

- (id)init
{
    self = [super init];
    if (self) {
        _completionBlock = ^(BOOL success, NSError *error){};
        _url = nil;
        _fileName = nil;
        _destinationDirectory = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] absoluteString];
        if (!_downloads)
            _downloads = [NSMutableDictionary dictionary];
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

-(void)dispose
{
    [self.session invalidateAndCancel];
    self.session = nil;
    [_downloads removeObjectForKey:self.url.absoluteString];
}

+(NSDictionary *)downloads;
{
    return [[NSDictionary alloc] initWithDictionary:_downloads];
}


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
        // take the filename from the last path component
        self.fileName = [NSString stringWithString:[self.url.absoluteString lastPathComponent]];
        
        // add the download to the list - dictionary of downloads
        [_downloads setObject:self forKey:self.url.absoluteString];
        
        // put the download object in the local strong variable
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:self.url];
        
        // start the download
        [downloadTask resume];
    } else {
        // you are already downloading this file
        NSError *error = [NSError errorWithDomain:@"FLDownloadAlreadyDownloadingThisURL" code:999 userInfo:nil];
        self.completionBlock(NO, error);
        [self dispose];
    }
}

+(void)resumeDownloadForSession:(NSURL *)session
{
    /* to resume a download there are two different workflows:
    1 - The app is in suspended state, then the download is finished:
        - the system calls - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
        - the user must call +(void)resumeDownloadForSession:(NSURL *)session passing the session url
        - we do nothing, because all objects are already created. The system forward the correct delegate calls
     
    2 - The app is in the killed state, then the download is finished:
       - the system relaunch app and calls - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
       - the user must call +(void)resumeDownloadForSession:(NSURL *)session passing the session url
       - we check that the download does not exist inside the list (the app has just been lauched from killed state, so the objects are not initialized), so we alloc-init a new FLDownload object and call resumeFromBackground (which recreates a NSURLSession object setting the delegate)
    */
    
    if (![[FLDownload downloads] objectForKey:[session absoluteString]])
    {
        // the app was previously killed
        FLDownload *download = [[FLDownload alloc] initBackgroundDownloadWithURL:session completion:nil];
        [download resumeFromBackground];
    }
}

-(void)resumeFromBackground
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
    
    // take the filename from the last path component
    self.fileName = [NSString stringWithString:[self.url.absoluteString lastPathComponent]];
    
    
    // When resuming a session after the app was killed, you MUST NOT RECREATE the download task. The task is recreated automatically by the session and then finished (calling the delegate methods)
    
    /*
    // put the download object in the local strong variable
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:self.url];
    
    // start the download
    [downloadTask resume];
    
     */
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
    NSURL *finalLocation = [NSURL URLWithString:[self.destinationDirectory stringByAppendingPathComponent:self.fileName]];
    
    // move the file
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:location toURL:finalLocation error:&error];
    
    if (!success)
    {
        NSLog(@"Error moving file: %@ to destination %@. Error: %@", [location absoluteString], [finalLocation absoluteString], error.description);
        self.completionBlock(NO, error);
    } else {
        self.completionBlock(YES, nil);
        NSLog(@"File moved to: %@", finalLocation);
    }
    
    // clean
    [self dispose];
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (self.progressBlock)
        self.progressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
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


@end
