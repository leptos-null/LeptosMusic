//
//  CircleWaveEqualizer.m
//  Equalizers
//
//  Created by Michael Liptuga on 10.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPCircleWaveEqualizer.h"

@implementation DPCircleWaveEqualizer

- (int)granularity {
    return MIN(10, 200 - (int)(self.equalizerSettings.numOfBins / 3) * 2);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    [self.backgroundColor set];
    UIRectFill(rect);
    
    UIBezierPath *lineGraph = [UIBezierPath bezierPath];
    
    CGPoint startPoint = CGPointMake(CGRectGetHeight(rect) / 2 - CGRectGetWidth(rect) / 4, CGRectGetWidth(rect) / 2);
    
    [lineGraph moveToPoint:startPoint];
    
    NSMutableArray<NSValue *> *points = [NSMutableArray array];
    
    [points addObject:[NSValue valueWithCGPoint:startPoint]];
    
    for (NSUInteger index2 = 0; index2 < self.equalizerSettings.numOfBins; index2++) {
        CGFloat columnHeight = self.equalizerSettings.plotType == DPPlotTypeRolling ? [[self.audioService timeHeights][index2] floatValue] : [self.audioService frequencyHeights][index2];
        columnHeight = MAX(1, columnHeight / 7);
        CGPoint pi; // intermediate point
        float R = CGRectGetWidth(rect) / 4;
        float a = columnHeight;
        float n = self.equalizerSettings.numOfBins * 0.4;
        
        float θ = ((2 * M_PI) / self.equalizerSettings.numOfBins) * index2;
        pi.x = -(R + a * sin(n * θ)) * cos(θ) + CGRectGetWidth(rect) / 2;
        pi.y = -(R + a * sin(n * θ)) * sin(θ) + CGRectGetHeight(rect) / 2;
        
        [points addObject:[NSValue valueWithCGPoint:pi]];
    }
    
    [points addObject:[NSValue valueWithCGPoint:startPoint]];
    [points addObject:[NSValue valueWithCGPoint:startPoint]];
    
    lineGraph = [self addBezierPathBetweenPoints:points];
    
    if (self.equalizerSettings.fillGraph) {
        [self.equalizerBinColor setFill];
        [self.equalizerBinColor setStroke];
        [lineGraph closePath];
        [lineGraph fill]; // fill color (if closed)
    }
    
    lineGraph.lineCapStyle = kCGLineCapRound;
    lineGraph.lineJoinStyle = kCGLineJoinRound;
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect) / 2); // get the circle centre
    
    CGContextSetRGBFillColor(ctx, 255, 255, 255, 1);
    CGContextFillEllipseInRect(ctx, CGRectMake(center.x - (CGRectGetWidth(rect) / 5) / 2, center.y - (CGRectGetHeight(rect) / 5) / 2, CGRectGetWidth(rect) / 5, CGRectGetHeight(rect) / 5));
    
    [self.equalizerBinColor setStroke];
    
    CGContextStrokePath(ctx);
    
    CGContextRestoreGState(ctx);
}

- (UIBezierPath *)addBezierPathBetweenPoints:(NSArray<NSValue *> *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
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
            pi.x = 0.5 * (2 * point1.x + (point2.x - point0.x) * t + (2 * point0.x - 5 * point1.x + 4 * point2.x - point3.x) * tt + (3 * point1.x - point0.x - 3 * point2.x + point3.x) * ttt);
            pi.y = 0.5 * (2 * point1.y + (point2.y - point0.y) * t + (2 * point0.y - 5 * point1.y + 4 * point2.y - point3.y) * tt + (3 * point1.y - point0.y - 3 * point2.y + point3.y) * ttt);
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
