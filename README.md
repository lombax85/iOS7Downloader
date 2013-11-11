TODO:::

1) update the Readme and the TODO :-)
2) add a download view controller to this project
3) add the possibility to see downloaded files


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
    

Note that, by now (consider this a TODO list):

- if the app is killed by the user, the download activity is lost
- if the app is killed by the system, the download continues, but the file is saved in the default dir and not in the directory you choosen to place the file.
- completion block and progress block are not executed if a download progress/finishes in background
- to support background download you must add in your AppDelegate this method:

 - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
 {
    NSURL *url = [NSURL URLWithString:identifier];
    [FLDownload resumeDownloadForSession:url];
    completionHandler();
 }
