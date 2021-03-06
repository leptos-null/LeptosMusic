//
//  HistogramEqualizerView.m
//  Equalizers
//
//  Created by Michael Liptuga on 09.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPHistogramEqualizerView.h"

@implementation DPHistogramEqualizerView

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGRect frame = self.bounds;
    
    [self.backgroundColor set];
    UIRectFill(frame);
    
    CGFloat columnWidth = CGRectGetWidth(rect) / self.equalizerSettings.numOfBins;
    
    CGFloat actualWidth = MAX(1, columnWidth * (1 - 2 * self.equalizerSettings.padding));
    CGFloat actualPadding = MAX(0, (columnWidth - actualWidth) / 2);
    
    for (NSUInteger i = 0; i < self.equalizerSettings.numOfBins; i++) {
        CGFloat columnHeight = self.audioService.frequencyHeights[i];
        
        columnHeight = MAX(1, columnHeight);
        if (columnHeight <= 0) {
            continue;
        }
        CGFloat columnX = i * columnWidth;
        CGRect pathRect = CGRectMake(columnX + actualPadding,
                                     CGRectGetHeight(frame) - columnHeight,
                                     actualWidth, columnHeight);
        UIBezierPath *histogramPath = [UIBezierPath bezierPathWithRoundedRect:pathRect cornerRadius:actualWidth];
        [self.equalizerBinColor setFill];
        [histogramPath fill];
    }
    
    CGContextRestoreGState(ctx);
}

@end
