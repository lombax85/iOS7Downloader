//
//  DownloadCell.m
//  FileSafe
//
//  Created by Lombardo on 14/04/13.
//
//

#import "DownloadCell.h"

@implementation DownloadCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state


}

/*
-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    NSArray *objectsToMove = @[self.expectedBytes, self.totalBytes];
    float pixelToMove = 50.0f;
    float animationDuration = 0.3f;
    
    float delta = (editing) ? -pixelToMove : pixelToMove;
    
    void (^moveBlock)() = ^{
        for (UIView *view in objectsToMove) {
            view.center = CGPointMake(view.center.x + delta, view.center.y);
        }
    };
    
    if (editing != self.isEditing)
    {
        if (animated)
            [UIView animateWithDuration:animationDuration animations:moveBlock];
        else
            moveBlock();
    }
    
    [super setEditing:editing animated:animated];
}
*/


@end
