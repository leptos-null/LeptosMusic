//
//  WaveEqualizerView.m
//  Equalizers
//
//  Created by Michael Liptuga on 09.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPWaveEqualizerView.h"

@implementation DPWaveEqualizerView {
    float _dx;
    float _dy;
    int _setZero;
}

- (void)setupView {
    _dy = 100;
    _dx = self.equalizerSettings.numOfBins;
    _setZero = 2;
    [super setupView];
}

- (int)granularity {
    return MIN(10, 200 - (int)(self.equalizerSettings.numOfBins / 3) * 2);
}

- (NSArray<NSValue *> *)arrayOfPointsForBinRange:(NSRange)range {
    NSMutableArray<NSValue *> *points = [NSMutableArray arrayWithCapacity:range.length];
    
    float viewWidth = CGRectGetWidth(self.frame) + (self.equalizerSettings.plotType == DPPlotTypeRolling ? 60 : 0);
    float viewHeight = CGRectGetHeight(self.frame);
    for (NSInteger i = 0; i < range.length; i++) {
        // start graph x on the right hand side
        float point1x = viewWidth - (viewWidth / range.length) * i;
        // start graph y on the bottom
        float point1y = (viewHeight-(viewHeight/_dy) * [self columnHeightAtIndex:range.length+range.location-i-1])/_setZero;
        
        float point2x = viewWidth - (viewWidth / range.length) * i - (viewWidth / range.length);
        float point2y = point1y;
        
        if (i > 0) {
            point2y = (viewHeight - (viewHeight / _dy) * [self columnHeightAtIndex:range.location + range.length - i]) / _setZero;
        }
        
        CGPoint p = (i == 0) ? CGPointMake(point1x, point1y) : CGPointMake(point2x, point2y);
        [points addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return points;
}

- (CGFloat)columnHeightAtIndex:(NSInteger)index {
    CGFloat columnHeight = self.equalizerSettings.plotType == DPPlotTypeRolling ? [[self.audioService timeHeights][index] doubleValue] : [self.audioService frequencyHeights][index];
    columnHeight = MAX(1, columnHeight);
    columnHeight = MIN(CGRectGetHeight(self.frame), columnHeight / 7);
    return columnHeight;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    [self.backgroundColor set];
    UIRectFill(rect);
    
    CGPoint leftBottom = CGPointMake(0, CGRectGetHeight(rect));
    CGPoint rightBottom = CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect));
    
    NSUInteger halfBins = self.equalizerSettings.numOfBins / 2;
    NSMutableArray *points = [[self arrayOfPointsForBinRange:NSMakeRange(0, halfBins)] mutableCopy];
    NSMutableArray *points2 = [[self arrayOfPointsForBinRange:NSMakeRange(halfBins, halfBins)] mutableCopy];
    
    // Add control points to make the math make sense
    UIBezierPath *lowFrequencyLineGraph = [self addBezierPathBetweenPoints:points];
    UIBezierPath *hightFrequencyLineGraph = [self addBezierPathBetweenPoints:points2];
    
    if (self.equalizerSettings.fillGraph) {
        [self.lowFrequencyColor setFill];
        [self.lowFrequencyColor setStroke];
        
        [lowFrequencyLineGraph addLineToPoint:CGPointMake(leftBottom.x, leftBottom.y)];
        [lowFrequencyLineGraph addLineToPoint:CGPointMake(rightBottom.x, rightBottom.y)];
        [lowFrequencyLineGraph closePath];
        [lowFrequencyLineGraph fill]; // fill color (if closed)
        
        [self.hightFrequencyColor setFill];
        [self.hightFrequencyColor setStroke];
        
        [hightFrequencyLineGraph addLineToPoint:CGPointMake(leftBottom.x, leftBottom.y)];
        [hightFrequencyLineGraph addLineToPoint:CGPointMake(rightBottom.x, rightBottom.y)];
        [hightFrequencyLineGraph closePath];
        [hightFrequencyLineGraph fill]; // fill color (if closed)
    } else {
        [self.lowFrequencyColor setStroke];
        
        lowFrequencyLineGraph.lineCapStyle = kCGLineCapRound;
        lowFrequencyLineGraph.lineJoinStyle = kCGLineJoinRound;
        lowFrequencyLineGraph.lineWidth = 0.5; // line width
        [lowFrequencyLineGraph stroke];
        
        [self.hightFrequencyColor setStroke];
        
        hightFrequencyLineGraph.lineCapStyle = kCGLineCapRound;
        hightFrequencyLineGraph.lineJoinStyle = kCGLineJoinRound;
        hightFrequencyLineGraph.lineWidth = 0.5; // line width
        [hightFrequencyLineGraph stroke];
    }
    CGContextRestoreGState(ctx);
}


- (UIBezierPath *)addBezierPathBetweenPoints:(NSMutableArray<NSValue *> *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [points insertObject:points.firstObject atIndex:0];
    [points addObject:points.lastObject];
    
    [path moveToPoint:points.firstObject.CGPointValue];
    
    for (int index = 1; index < points.count - 2; index++) {
        CGPoint point0 = [points[index - 1] CGPointValue];
        CGPoint point1 = [points[index + 0] CGPointValue];
        CGPoint point2 = [points[index + 1] CGPointValue];
        CGPoint point3 = [points[index + 2] CGPointValue];
        
        for (int i = 1; i < self.granularity; i++) {
            float t = (float)i * (1.0f / (float)self.granularity);
            float tt = t * t;
            float ttt = tt * t;
            CGPoint pi;
            pi.x = 0.5 * (2*point1.x + (point2.x - point0.x)*t + (2*point0.x - 5*point1.x + 4*point2.x - point3.x) * tt + (3*point1.x - point0.x - 3*point2.x + point3.x) * ttt);
            pi.y = 0.5 * (2*point1.y + (point2.y - point0.y)*t + (2*point0.y - 5*point1.y + 4*point2.y - point3.y) * tt + (3*point1.y - point0.y - 3*point2.y + point3.y) * ttt);
            
            if (pi.y > CGRectGetHeight(self.frame)) {
                pi.y = CGRectGetWidth(self.frame);
            } else if (pi.y < 0) {
                pi.y = 0;
            }
            [path addLineToPoint:pi];
        }
        [path addLineToPoint:point2];
    }
    [path addLineToPoint:points.lastObject.CGPointValue];
    return path;
}

@end
