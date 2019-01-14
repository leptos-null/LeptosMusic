//
//  AudioSettings.m
//  Equalizers
//
//  Created by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPEqualizerSettings.h"

@implementation DPEqualizerSettings

+ (instancetype)create {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings new];
    
    audioSettings.maxFrequency = 7000; //
    audioSettings.minFrequency = 400;  //
    audioSettings.numOfBins = 40;      //
    audioSettings.padding = 2 / 10.0;  //
    audioSettings.gain = 10;           //
    audioSettings.gravity = 10;        //
    
    audioSettings.maxBinHeight = UIScreen.mainScreen.bounds.size.height;
    audioSettings.plotType = DPPlotTypeBuffer;
    audioSettings.equalizerType = DPHistogram;
    
    audioSettings.equalizerBinColors = [NSMutableArray arrayWithObject:[UIColor blueColor]];
    audioSettings.lowFrequencyColors = [NSMutableArray arrayWithObject:[UIColor greenColor]];
    audioSettings.hightFrequencyColors = [NSMutableArray arrayWithObject:[UIColor purpleColor]];
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];
    
    return audioSettings;
}

+ (instancetype)createByType:(DPEqualizerType)type {
    switch (type) {
        case DPHistogram:
            return [self createHistogramAudioSettings];
        case DPRolling:
            return [self createRollingAudioSettings];
        case DPRollingWave:
            return [self createRollingWaveAudioSettings];
        case DPFillWave:
            return [self createFillWaveAudioSettings];
        case DPWave:
            return [self createWaveAudioSettings];
        case DPCircleWave:
            return [self createCircleWaveAudioSettings];
        default:
            return nil;
    }
}


+ (instancetype)createHistogramAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];
    
    audioSettings.equalizerType = DPHistogram;
    audioSettings.numOfBins = 30;
    audioSettings.gravity = 3;
    audioSettings.plotType = DPPlotTypeBuffer;
    audioSettings.padding = 0.3;
    
    audioSettings.equalizerBinColors = [NSMutableArray arrayWithArray:@[
        [UIColor colorWithRed:87/255.0 green:109/255.0 blue:255/255.0 alpha:1],
        [UIColor colorWithRed:245/255.0 green:240/255.0 blue:255/255.0 alpha:1]
    ]];
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];

    return audioSettings;
}

+ (instancetype)createRollingAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];
    
    audioSettings.equalizerType = DPRolling;
    audioSettings.numOfBins = 50;
    audioSettings.plotType = DPPlotTypeRolling;
    audioSettings.padding = 0.3;
    
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:36/255.0 green:41/255.0 blue:50/255.0 alpha:1]];
    audioSettings.equalizerBinColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:255/255.0 green:219/255.0 blue:114/255.0 alpha:1]];
    
    return audioSettings;
}

+ (instancetype)createRollingWaveAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];

    audioSettings.equalizerType = DPRollingWave;
    audioSettings.numOfBins = 50;
    audioSettings.plotType = DPPlotTypeRolling;
    audioSettings.fillGraph = YES;
    
    audioSettings.lowFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:194/255.0 green:207/255.0 blue:255/255.0 alpha:1]];
    audioSettings.hightFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:255/255.0 green:160/255.0 blue:143/255.0 alpha:1]];
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];

    return audioSettings;
}

+ (instancetype)createFillWaveAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];

    audioSettings.equalizerType = DPFillWave;
    audioSettings.numOfBins = 50;
    audioSettings.gravity = 3;
    audioSettings.plotType = DPPlotTypeBuffer;
    audioSettings.fillGraph = YES;
    
    audioSettings.lowFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:194/255.0 green:207/255.0 blue:255/255.0 alpha:1]];
    audioSettings.hightFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:255/255.0 green:160/255.0 blue:143/255.0 alpha:1]];
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];

    return audioSettings;
}

+ (instancetype)createWaveAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];
    
    audioSettings.equalizerType = DPWave;
    audioSettings.numOfBins = 50;
    audioSettings.gravity = 3;
    audioSettings.plotType = DPPlotTypeBuffer;
    audioSettings.fillGraph = NO;
    
    audioSettings.lowFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:255/255.0 green:134/255.0 blue:134/255.0 alpha:1]];
    audioSettings.hightFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:255/255.0 green:134/255.0 blue:134/255.0 alpha:1]];
    
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];
    
    return audioSettings;
}

+ (instancetype)createCircleWaveAudioSettings {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings create];
    
    audioSettings.equalizerType = DPCircleWave;
    audioSettings.numOfBins = 180;
    audioSettings.padding = 0.5;
    audioSettings.maxFrequency = 4400;
    audioSettings.gravity = 2;
    audioSettings.plotType = DPPlotTypeBuffer;
    audioSettings.fillGraph = YES;
    
    UIColor *firstColor = [UIColor colorWithRed:87/255.0 green:109/255.0 blue:255/255.0 alpha:1];
    UIColor *secondColor = [UIColor colorWithRed:255 / 255.0 green:160 / 255.0 blue:143 / 255.0 alpha:1.0];
    
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:[UIColor whiteColor]];
    audioSettings.equalizerBinColors = [NSMutableArray arrayWithArray:@[
        firstColor,
        secondColor,
        firstColor
    ]];
    
    return audioSettings;
}

@end
