This is a simple class to manage background download on iOS 7.0
You can start a download as follow:

    // Using the sharedDownloader singleton instance
    - (IBAction)start:(id)sender {
        NSURL *url = [NSURL URLWithString:self.url.text];
    
        FLDownloadTask *download = [[FLDownloader sharedDownloader] downloadTaskForURL:url];
    
        [download start];
    }

    // creating directly a FLDownloadTask instance
    - (IBAction)startAlternative:(id)sender {
        NSURL *url = [NSURL URLWithString:self.url.text];

        FLDownloadTask *download = [FLDownloadTask downloadTaskForURL:url];
    
        [download start];
    }

Look inside the DownloadViewController to see how to manage the progress, cancellation of a download ecc...
When the download is finished, in this example, it will be copied inside the Documents directory by default


Note for background download support

- if the app is killed by the user, the download activity is killed by the system. At the subsequent startup, the system will pass the resume data and the download will continue from the last saved point.
- if the app is killed by the system (example: to free memory), the download continues in background.
- completion block and progress block are not executed if a download progress/finishes in background
- to support background download (as described above) you must add in your AppDelegate this method:

```
    // add [FLDownloader sharedDownloader]; in AppDelegate
     - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
     {
        [FLDownloader sharedDownloader];
     }
 ```

 Moreover, update your AppDelegate as follow:
 ```
     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        // Override point for customization after application launch.
        // ...
        [FLDownloader sharedDownloader];
        //...
        return YES;
    }
 ```

For uploading files, the http method PUT is used


 ```
    NSURL *url = [NSURL URLWithString:@"http://162.252.243.43/testput.php"];
    NSURL *fileLocalURL = [[NSBundle mainBundle] URLForResource:@"5MB" withExtension:@"zip"];
    FLDownloadTask *upload = [[FLDownloader sharedDownloader] uploadTaskForURL:url fromFile:fileLocalURL];
    
    [upload start];

 ```
 
 a test file and a link to a test server is included in this project. Please don't abuse if. The files are not written on the server but the bandwidth costs :-)
 If you want to test with your own server, here's a php script that you can use:
 
  ```
 <?php
    /* read PUT data */
    $putdata = fopen("php://input", "r");

    /* Open file for writing, change "testput" to your filename */
    $fp = fopen("testput", "w");

    /* read data and write to file */
    while ($data = fread($putdata, 1024))
    {
    fwrite($fp, $data);
    }

    /* close stream */
    fclose($fp);
    fclose($putdata);
?>
 ```
