//
//  DPMainEqualizerView.h
//  Equalizers
//
//  Created by Michael Liptuga on 09.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPEqualizerSettings.h"
#import "DPAudioService.h"

@interface DPMainEqualizerView : UIView <DPAudioServiceDelegate>

@property (strong, nonatomic) DPEqualizerSettings *equalizerSettings;
@property (strong, nonatomic) DPAudioService *audioService;

@property (strong, nonatomic) UIColor *equalizerBackgroundColor;

@property (strong, nonatomic) UIColor *lowFrequencyColor;

@property (strong, nonatomic) UIColor *hightFrequencyColor;

@property (strong, nonatomic) UIColor *equalizerBinColor;


- (instancetype)initWithFrame:(CGRect)frame andSettings:(DPEqualizerSettings *)settings;

- (void)setupView;

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize;
- (void)updateNumberOfBins:(NSUInteger)numberOfBins;

/// Drawing colors are cached. If you change any colors in equalizerSettings, call this method to update the UI
- (void)updateColors;

@end
