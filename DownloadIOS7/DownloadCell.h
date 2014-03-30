//
//  DownloadCell.h
//  FileSafe
//
//  Created by Lombardo on 14/04/13.
//
//

#import <UIKit/UIKit.h>

@interface DownloadCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *fileName;
@property (nonatomic, strong) IBOutlet UIProgressView *fileProgress;

@property (nonatomic, strong) IBOutlet UILabel *totalBytes;
@property (nonatomic, strong) IBOutlet UILabel *expectedBytes;
@property (strong, nonatomic) IBOutlet UILabel *type;

@end
