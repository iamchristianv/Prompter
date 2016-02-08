//
//  SpeechTableViewCell.h
//  Prompter
//
//  Created by Christian Villa on 8/25/15.
//  Copyright (c) 2015 Christian Villa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpeechTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *notePreviewLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateUpdatedLabel;

@end
