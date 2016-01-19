//
//  ViewController.h
//  DJ
//
//  Created by Deepak on 13/01/16.
//  Copyright © 2016 Deepak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class PlayerView;

@interface ViewController : UIViewController

@property (readonly) AVPlayer *player;
@property AVURLAsset *asset;

@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;

@property (weak) IBOutlet UILabel *startTimeLabel;
@property (weak) IBOutlet UILabel *durationTimeLabel;
@property (weak) IBOutlet UIButton *playButton;
@property (weak) IBOutlet UIButton *rewindButton;
@property (weak) IBOutlet UIButton *fastForwardButton;
@property (weak) IBOutlet UISlider *slider;
@property (weak) IBOutlet PlayerView *playerView;

@end

