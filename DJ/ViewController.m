//
//  ViewController.m
//  DJ
//
//  Created by Deepak on 13/01/16.
//  Copyright © 2016 Deepak. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@interface ViewController ()
{
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    AVURLAsset *_asset;
    id<NSObject> _timeObserverToken;
}
//@property AVPlayerItem *playerItem;
//@property (readonly) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

static int ViewControllerKVOContext = 0;

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(tapAndSlide:)];
    longPress.minimumPressDuration = 0;
    [self.slider addGestureRecognizer:longPress];


    //Pan Gesture for Volume
    UIPanGestureRecognizer *panGestureForVolume = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureForVolume:)];
    [self.view addGestureRecognizer:panGestureForVolume];

    //Pan Gesture for Movie
    UIPanGestureRecognizer *panGestureForMovie = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureForMovie:)];
    panGestureForMovie.minimumNumberOfTouches = 2;
    panGestureForMovie.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer:panGestureForMovie];

    //Customize slider
    self.slider.minimumTrackTintColor = [UIColor redColor];
    self.slider.maximumTrackTintColor = [UIColor grayColor];
    UIImage *thumbImage = [UIImage imageNamed:@"thumb"];
    [self.slider setThumbImage:thumbImage forState:UIControlStateNormal];

    //Add Observers.
    [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&ViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew context:&ViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:&ViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:&ViewControllerKVOContext];

    self.playerView.player = self.player;      // Step 5  Attach player to playerlayer.

    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    self.asset = [AVURLAsset assetWithURL:movieURL];    // Step 1 Create asset
    ViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        weakSelf.slider.value = CMTimeGetSeconds(time);
        int currentTimeInt = CMTimeGetSeconds(time);
        int wholeMinutes = (int)trunc(currentTimeInt/60);
        NSString *currentTime = [NSString stringWithFormat:@"%d:%02d",wholeMinutes,(int)(trunc(currentTimeInt)) - (wholeMinutes * 60)];
        self.startTimeLabel.text = currentTime;
    }];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_timeObserverToken) {
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }
    [self.player pause];
    [self removeObserver:self forKeyPath:@"asset" context:&ViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&ViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&ViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&ViewControllerKVOContext];
}

+ (NSArray*)assetKeysRequiredToPlay
{
    return @[@"playable",@"hasProtectedContent"];
}

-(AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

- (CMTime)currentTime
{
    return self.player.currentTime;
}

-(void)setCurrentTime:(CMTime)newCurrentTime
{
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(CMTime)duration
{
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

-(float)rate
{
    return self.player.rate;
}

-(void)setRate:(float)rate
{
    self.player.rate = rate;
}

-(AVPlayerLayer *)playerLayer
{
    return self.playerView.playerLayer;
}

-(AVPlayerItem *)playerItem
{
    return _playerItem;
}

-(void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem != playerItem) {
        _playerItem = playerItem;
        [self.player replaceCurrentItemWithPlayerItem:playerItem];   // Step 4 Attach item to player.
    }
}

- (void)asynchronouslyLoadURLAsset:(AVAsset*)asset
{
    // Step 2: assetKeysRequiredToPlay
    [asset loadValuesAsynchronouslyForKeys:[[self class] assetKeysRequiredToPlay] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (asset != self.asset) {
                // new asset will load so no need to do anything for this one.
                return;
            }

            for (NSString *key in [self.class assetKeysRequiredToPlay]) {
                NSError *error = nil;
                if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    NSString *message = [NSString localizedStringWithFormat:NSLocalizedString(@"error.asset_key_%@_failed.description", @"Can't use this AVAsset because one of it's keys failed to load"),key];
                    [self handleErrorWithMessage:message error:error];
                    return;
                }
            }

            if (!asset.playable || asset.hasProtectedContent) {
                NSString *message = NSLocalizedString(@"error.asset_not_playable.description", @"Can't use this AVAsset because it isn't playable or has protected content");

                [self handleErrorWithMessage:message error:nil];

                return;
            }

            self.playerItem = [AVPlayerItem playerItemWithAsset:asset];         // Step 3 Create player item

        });
    }];
}

- (void)handleErrorWithMessage:(NSString *)message error:(NSError *)error {
    NSLog(@"Error occured with message: %@, error: %@.", message, error);

    NSString *alertTitle = NSLocalizedString(@"alert.error.title", @"Alert title for errors");
    NSString *defaultAlertMesssage = NSLocalizedString(@"error.default.description", @"Default error message when no NSError provided");
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:alertTitle message:message ?: defaultAlertMesssage preferredStyle:UIAlertControllerStyleAlert];

    NSString *alertActionTitle = NSLocalizedString(@"alert.error.actions.OK", @"OK on error alert");
    UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    [controller addAction:action];

    [self presentViewController:controller animated:YES completion:nil];
}
- (IBAction)playPauseButtonPressed:(id)sender {
    if (self.rate != 1.0) {
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            self.currentTime = kCMTimeZero;           // kCMZero returns CMTime 0
        }
        [self.player play];                                     // automatically set rate to 1
    }
    else
    {
        [self.player pause];                                    // automatically set rate to 1
    }
}

- (IBAction)forwardButtonPressed:(id)sender {
    self.rate = MIN(self.rate + 2, 2);
}

- (IBAction)rewindButtonPressed:(id)sender {
    self.rate = MAX(self.rate - 2, -2);
}

- (IBAction)timeSliderChanged:(UISlider*)sender {
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 1000);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != &ViewControllerKVOContext ) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    else if ([keyPath isEqualToString:@"asset"])
    {
        if (self.asset) {
            [self asynchronouslyLoadURLAsset:self.asset];
        }
    }
    else if ([keyPath isEqualToString:@"player.currentItem.duration"])
    {
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
//        NSLog(@"slider maximum value: %f",self.slider.maximumValue);
        self.slider.maximumValue = newDurationSeconds;
        self.slider.value = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        self.slider.enabled = hasValidDuration;
        self.rewindButton.enabled = hasValidDuration;
        self.playButton.enabled = hasValidDuration;
        self.fastForwardButton.enabled = hasValidDuration;
        self.startTimeLabel.enabled = hasValidDuration;
        self.durationTimeLabel.enabled = hasValidDuration;
        int wholeMinutes = (int)trunc(newDurationSeconds/60);
        NSString *duration = [NSString stringWithFormat:@"%d:%02d",wholeMinutes,(int)(trunc(newDurationSeconds)) - (wholeMinutes * 60)];
        self.durationTimeLabel.text = duration;
//        [self.durationTimeLabel setText:duration];
    }
    else if ([keyPath isEqualToString:@"player.rate"])
    {
        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
        UIImage *buttonImage = (newRate == 1.0) ? [UIImage imageNamed:@"pause.jpg"] : [UIImage imageNamed:@"play.jpg"];
        [self.playButton setImage:buttonImage forState:UIControlStateNormal];
    }
    else if ([keyPath isEqualToString:@"player.currentItem.status"])
    {
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;

        if (newStatus == AVPlayerStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error:self.player.currentItem.error];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+(NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.duration" ]];
    } else if ([key isEqualToString:@"currentTime"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.currentTime" ]];
    } else if ([key isEqualToString:@"rate"]) {
        return [NSSet setWithArray:@[ @"player.rate" ]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

-(void)handlePanGestureForVolume:(UIPanGestureRecognizer*)sender
{
    if ([sender velocityInView:self.view].y < 0 && self.player.volume<1) {
        self.player.volume += 0.02;
        NSLog(@"Current Volume%f",self.player.volume);
    }
    else if([sender velocityInView:self.view].y > 0 && self.player.volume>0)
    {
        self.player.volume -= 0.02;
        NSLog(@"Current Volume%f",self.player.volume);
    }
}

-(void)handlePanGestureForMovie:(UIPanGestureRecognizer*)sender
{
    self.player.pause;
    if ([sender velocityInView:self.view].x < 0 && CMTimeCompare(self.currentTime, CMTimeMake(0, 1000)) == 1) {
        self.currentTime = CMTimeSubtract(self.currentTime, CMTimeMake(CMTimeGetSeconds(self.player.currentItem.duration)*2, 1000));
        NSLog(@"current time: %@",[NSValue valueWithCMTime:self.currentTime]);
    }
    else if ([sender velocityInView:self.view].x > 0 && CMTimeCompare(self.currentTime, self.player.currentItem.duration) == -1) {
        self.currentTime = CMTimeAdd(self.currentTime, CMTimeMake(CMTimeGetSeconds(self.player.currentItem.duration)*2, 1000));
    }
    self.player.play;
}

-(void)tapAndSlide:(UILongPressGestureRecognizer*)gesture
{
    UISlider *slider = (UISlider *)gesture.view;
    CGPoint pt = [gesture locationInView: slider];
    CGFloat value;


        CGFloat percentage = (pt.x)/(slider.bounds.size.width);
        CGFloat delta = percentage * (slider.maximumValue - slider.minimumValue);
        value = slider.minimumValue + delta;


    if(gesture.state == UIGestureRecognizerStateBegan){
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [slider setValue:value animated:YES];
            [slider sendActionsForControlEvents:UIControlEventValueChanged];
        } completion:nil];
    }
    else [slider setValue:value];

    if(gesture.state == UIGestureRecognizerStateChanged)
        [slider sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
