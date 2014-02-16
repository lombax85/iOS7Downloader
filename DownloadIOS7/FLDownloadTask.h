//
//  FLDownloadTask.h
//  FileSafe
//
//  Created by Lombardo on 17/11/13.
//
//

#import <Foundation/Foundation.h>
#import "FLDownloader.h"

@interface FLDownloadTask : NSObject <NSCoding>

/**
 Initialize and return a new download task for a given url
 */
+(FLDownloadTask *)downloadTaskForURL:(NSURL *)url NS_AVAILABLE_IOS(7_0);

/**
 Set the progress update block - optional
 */
@property (copy, nonatomic) void (^progressBlock)(NSURL *url, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
-(void)setProgressBlock:(void (^)(NSURL *url, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock;

/**
 Set the completion block
 */
@property (copy, nonatomic) void (^completionBlock)(BOOL success, NSError *error);
-(void)setCompletionBlock:(void (^)(BOOL success, NSError *error))completionBlock;

/**
 Start the download. The FLDownload object is retained by the system until the download ends or fail (then the completion block is called and the object disposed)
 */
-(void)start NS_AVAILABLE_IOS(7_0);

/**
 Cancel the download task
 */
-(void)cancel NS_AVAILABLE_IOS(7_0);

/**
 Sends a resume or pause message to the download operation basing on the current state
 */
-(void)resumeOrPause NS_AVAILABLE_IOS(7_0);

/**
 The download url
 */
@property (strong, nonatomic, readonly) NSURL *url;


/**
 Set the destination directory for the file. Defaults: documents directory
 */
@property (copy, nonatomic) NSString *destinationDirectory;

/**
 The name of the file that it's being downloaded. You can change it
 */
@property (copy, nonatomic) NSString *fileName;

/**
 This is the underlying download task associated with the object
 */
@property (weak, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;




@end
