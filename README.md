This class is BETA.
Read the comments in FLDownload.h and FLDownload.m files

You can use it as follow:

    NSURL *url = [NSURL URLWithString:@"http://url.to.download"];
    
    FLDownload *download = [[FLDownload alloc] initBackgroundDownloadWithURL:url completion:^(BOOL success, NSError *error) {
        // code to execute when download finishes
    }];
    
    [download setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        // update progress
    }];
    
    [download start];
    

Note that:

- completion block and progress block are not executed if a download progress/finishes in background
- to support background download you must add in your AppDelegate this method:

 - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
 {
    NSURL *url = [NSURL URLWithString:identifier];
    [FLDownload resumeDownloadForSession:url];
    completionHandler();
 }
