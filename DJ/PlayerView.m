//
//  PlayerView.m
//  DJ
//
//  Created by Deepak on 13/01/16.
//  Copyright © 2016 Deepak. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

+(Class)layerClass
{
    return [AVPlayerLayer class];
}

-(AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer*)self.layer;
}

-(AVPlayer *)player
{
    return self.playerLayer.player;
}

-(void)setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
}



@end
