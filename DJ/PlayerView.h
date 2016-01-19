//
//  PlayerView.h
//  DJ
//
//  Created by Deepak on 13/01/16.
//  Copyright © 2016 Deepak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;

@interface PlayerView : UIView

@property AVPlayer *player;
@property (readonly)AVPlayerLayer *playerLayer;
@end
