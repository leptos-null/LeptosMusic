//
//  DPMainEqualizerView.m
//  Equalizers
//
//  Created by Michael Liptuga on 09.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPMainEqualizerView.h"

@implementation DPMainEqualizerView

- (instancetype)initWithFrame:(CGRect)frame andSettings:(DPEqualizerSettings *)settings {
    if (self = [super initWithFrame:frame]) {
        self.equalizerSettings = settings;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = self.equalizerBackgroundColor;
}

- (void)updateNumberOfBins:(NSUInteger)numberOfBins {
    self.audioService.numOfBins = numberOfBins;
}

- (void)updateColors {
    self.equalizerBackgroundColor = nil;
    self.equalizerBinColor = nil;
    self.lowFrequencyColor = nil;
    self.hightFrequencyColor = nil;
    [self setupView];
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    [self.audioService updateBuffer:buffer withBufferSize:bufferSize];
}

- (DPAudioService *)audioService {
    if (!_audioService) {
        _audioService = [DPAudioService serviceWith:self.equalizerSettings];
        _audioService.delegate = self;
    }
    return _audioService;
}

- (DPEqualizerSettings *)equalizerSettings {
    if (!_equalizerSettings) {
        _equalizerSettings = [DPEqualizerSettings create];
    }
    return _equalizerSettings;
}

- (UIColor *)_gradientColorForColors:(NSArray<UIColor *> *)colors {
    if (colors.count <= 1) {
        return colors.firstObject;
    }
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = self.bounds;
    
    NSMutableArray *colorsRef = [NSMutableArray arrayWithCapacity:colors.count];
    NSMutableArray *locations = [NSMutableArray arrayWithCapacity:colors.count];
    
    for (NSUInteger colorIndex = 0; colorIndex < colors.count; colorIndex++) {
        UIColor *color = colors[colorIndex];
        CGFloat location = (CGFloat)colorIndex/(colors.count - 1);
        
        [colorsRef addObject:(id)color.CGColor];
        [locations addObject:@(location)];
    }
    
    layer.colors = colorsRef;
    layer.locations = locations;
    
    UIGraphicsBeginImageContext(layer.bounds.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // return the gradient image
    return [UIColor colorWithPatternImage:gradientImage];
}

- (UIColor *)equalizerBackgroundColor {
    if (!_equalizerBackgroundColor) {
        _equalizerBackgroundColor = [self _gradientColorForColors:self.equalizerSettings.equalizerBackgroundColors];
    }
    return _equalizerBackgroundColor;
}

- (UIColor *)lowFrequencyColor {
    if (!_lowFrequencyColor) {
        _lowFrequencyColor = [self _gradientColorForColors:self.equalizerSettings.lowFrequencyColors];
    }
    return _lowFrequencyColor;
}

- (UIColor *)hightFrequencyColor {
    if (!_hightFrequencyColor) {
        _hightFrequencyColor = [self _gradientColorForColors:self.equalizerSettings.hightFrequencyColors];
    }
    return _hightFrequencyColor;
}

- (UIColor *)equalizerBinColor {
    if (!_equalizerBinColor) {
        _equalizerBinColor = [self _gradientColorForColors:self.equalizerSettings.equalizerBinColors];
    }
    return _equalizerBinColor;
}

- (void)_refreshDisplay {
#if TARGET_OS_IPHONE
    [self setNeedsDisplay];
#elif TARGET_OS_MAC
    [self setNeedsDisplay:YES];
#endif
}

#pragma mark - DPAudioServiceDelegate

- (void)refreshEqualizerDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _refreshDisplay];
    });
}

@end
