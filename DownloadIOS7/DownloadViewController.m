//
//  DownloadViewController.m
//  FileSafe
//
//  Created by Lombardo on 14/04/13.
//
//

#import "DownloadViewController.h"
#import "DownloadCell.h"
#import "FLDownloader.h"


@interface DownloadViewController ()

@property (strong, nonatomic) NSMutableArray *downloads;
@property (strong, nonatomic) NSMutableDictionary *cells;

@end

@implementation DownloadViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        // iOS 7.0 download
        self.downloads = [[[[FLDownloader sharedDownloader] tasks] allValues] mutableCopy];
        self.cells = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // iOS 7.0 download
    self.downloads = [[[[FLDownloader sharedDownloader] tasks] allValues] mutableCopy];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        FLDownloadTask *download =  [self.downloads objectAtIndex:indexPath.row];
        [download cancel];
        
        [self.downloads removeObjectAtIndex:indexPath.row];
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    FLDownloadTask *download =  [self.downloads objectAtIndex:indexPath.row];
    
    [download resumeOrPause];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(void)configureCell:(DownloadCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    
    FLDownloadTask *download =  [self.downloads objectAtIndex:indexPath.row];
    cell.fileName.text = [download fileName];
    cell.fileProgress.progress = 0.0f;
    cell.totalBytes.text = @"";
    cell.expectedBytes.text = @"";
    
    [self.cells setObject:cell forKey:[download url]];
    
    [download setProgressBlock:^(NSURL *url, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        
        float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        NSLog(@"Progress: %.2f", progress);
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.fileProgress.progress = progress;
            float downloadedkb = totalBytesWritten / 1024;
            float totalkb = totalBytesExpectedToWrite / 1024;
            cell.totalBytes.text = [NSString stringWithFormat:@"%.0f KB", downloadedkb];
            cell.expectedBytes.text = [NSString stringWithFormat:@"/ %.0f KB", totalkb];
        });
        
    }];
    
    
    
    // cleaning self.download free the download and let it dealloc
    [download setCompletionBlock:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloads = [[[[FLDownloader sharedDownloader] tasks] allValues] mutableCopy];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
