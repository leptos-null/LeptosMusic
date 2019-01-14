//
//  AudioService.m
//  Equalizers
//
//  Created by Zhixuan Lai on 8/2/14. Modified by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPAudioService.h"

static const UInt32 kMaxFrames = 1 << 12;

static const Float32 kAdjust0DB = 1.5849e-13;

static const NSInteger kFrameInterval = 2; // Alter this to draw more or less often
// #define kFrameInterval 2
// _Static_assert(kFrameInterval >= 1, "Frame update interval may not be less than 1");

@interface DPAudioService ()

@property (strong, nonatomic) CADisplayLink *displaylink;
@property (strong, nonatomic) DPEqualizerSettings *settings;
@property (strong, nonatomic) NSMutableArray<NSNumber *> *heightsByTime;

@end

@implementation DPAudioService {
    FFTSetup _fftSetup;
    
    DSPSplitComplex _complexSplit;
    
    int _log2n, _nOver2;
    
    size_t _bufferCapacity, _index;
    
    // buffers
    float *_speeds, *_times, *_tSqrts, *_vts, *_deltaHeights, *_dataBuffer, *_heightsByFrequency;
}

+ (instancetype)serviceWith:(DPEqualizerSettings *)audioSettings {
    DPAudioService *service = [[super alloc] initUniqueInstanceWith:audioSettings];
    return service;
}

- (instancetype)initUniqueInstanceWith:(DPEqualizerSettings *)audioSettings {
    if (self = [super init]) {
        self.settings = audioSettings;
        self.numOfBins = audioSettings.numOfBins;
        self.plotType = audioSettings.plotType;

        // Configure Data buffer and setup FFT
        _dataBuffer = (float *)malloc(kMaxFrames * sizeof(float));
        
        _log2n = log2f(kMaxFrames);
        assert((1 << _log2n) == kMaxFrames);
        
        _nOver2 = kMaxFrames / 2;
        _bufferCapacity = kMaxFrames;
        
        _complexSplit.realp = (float *)malloc(_nOver2 * sizeof(float));
        _complexSplit.imagp = (float *)malloc(_nOver2 * sizeof(float));
        
        _fftSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);
        
        // Create and configure audio session
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        _sampleRate = audioSession.sampleRate; /* internal: Could this be more appropriately set? */
        
        // Start timer
        self.displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateHeights)];
        
        self.displaylink.frameInterval = kFrameInterval;
        
        [self.displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (float *)frequencyHeights {
    return _heightsByFrequency;
}

- (NSMutableArray *)timeHeights {
    return self.heightsByTime;
}

- (void)dealloc {
    [self.displaylink invalidate];
    self.displaylink = nil;
    [self freeBuffersIfNeeded];
}

#pragma mark - Properties

- (void)setNumOfBins:(NSUInteger)binsNumber {
    // Set new value for numOfBins property
    _numOfBins = MAX(1, binsNumber);
    self.settings.numOfBins = binsNumber;
    
    [self freeBuffersIfNeeded];
    
    // Create buffers
    _heightsByFrequency = calloc(sizeof(float), _numOfBins);
    _speeds =             calloc(sizeof(float), _numOfBins);
    _times =              calloc(sizeof(float), _numOfBins);
    _tSqrts =             calloc(sizeof(float), _numOfBins);
    _vts =                calloc(sizeof(float), _numOfBins);
    _deltaHeights =       calloc(sizeof(float), _numOfBins);
    
    // Create Heights by time array
    self.heightsByTime = [NSMutableArray arrayWithCapacity:_numOfBins];
    for (int i = 0; i < _numOfBins; i++) {
        self.heightsByTime[i] = @(0.0f);
    }
}

#pragma mark - Timer Callback

- (void)updateHeights {
    // Delay from last frame
    float delay = self.displaylink.duration * self.displaylink.frameInterval;
    
    // increment time
    vDSP_vsadd(_times, 1, &delay, _times, 1, _numOfBins);
    
    // clamp time
    static const float timeMin = 1.5, timeMax = 10;
    vDSP_vclip(_times, 1, &timeMin, &timeMax, _times, 1, _numOfBins);
    
    // increment speed
    float g = self.settings.gravity * delay;
    vDSP_vsma(_times, 1, &g, _speeds, 1, _speeds, 1, _numOfBins);
    
    // increment height
    vDSP_vsq(_times, 1, _tSqrts, 1, _numOfBins);
    vDSP_vmul(_speeds, 1, _times, 1, _vts, 1, _numOfBins);
    float aOver2 = g / 2;
    vDSP_vsma(_tSqrts, 1, &aOver2, _vts, 1, _deltaHeights, 1, _numOfBins);
    vDSP_vneg(_deltaHeights, 1, _deltaHeights, 1, _numOfBins);
    vDSP_vadd(_heightsByFrequency, 1, _deltaHeights, 1, _heightsByFrequency, 1, _numOfBins);
    
    [self p_refreshEqualizerDisplay];
}

#pragma mark - Update Buffers

- (void)setSampleData:(float *)data length:(int)length {
    // fill the buffer with our sampled data. If we fill our buffer, run the FFT
    int inNumberFrames = length;
    int read = (int)(_bufferCapacity - _index);
    
    if (read > inNumberFrames) {
        memcpy((float *)_dataBuffer + _index, data, inNumberFrames * sizeof(float));
        _index += inNumberFrames;
    } else {
        // if we enter this conditional, our buffer will be filled and we should perform the FFT
        memcpy((float *)_dataBuffer + _index, data, read * sizeof(float));
        
        // reset the index.
        _index = 0;
        
        vDSP_ctoz((COMPLEX *)_dataBuffer, 2, &_complexSplit, 1, _nOver2);
        vDSP_fft_zrip(_fftSetup, &_complexSplit, 1, _log2n, FFT_FORWARD);
        vDSP_ztoc(&_complexSplit, 1, (COMPLEX *)_dataBuffer, 2, _nOver2);
        
        // convert to dB
        Float32 one = 1, zero = 0;
        vDSP_vsq(_dataBuffer, 1, _dataBuffer, 1, inNumberFrames);
        vDSP_vsadd(_dataBuffer, 1, &kAdjust0DB, _dataBuffer, 1, inNumberFrames);
        vDSP_vdbcon(_dataBuffer, 1, &one, _dataBuffer, 1, inNumberFrames, 0);
        vDSP_vthr(_dataBuffer, 1, &zero, _dataBuffer, 1, inNumberFrames);
        
        // aux
        float mul = (_sampleRate / _bufferCapacity) / 2;
        int minFrequencyIndex = self.settings.minFrequency / mul;
        int maxFrequencyIndex = self.settings.maxFrequency / mul;
        int numDataPointsPerColumn =
        (maxFrequencyIndex - minFrequencyIndex) / _numOfBins;
        float maxHeight = 0;
        
        for (NSUInteger i = 0; i < _numOfBins; i++) {
            // calculate new column height
            float avg = 0;
            vDSP_meanv(_dataBuffer + minFrequencyIndex + i * numDataPointsPerColumn, 1, &avg, numDataPointsPerColumn);
            
            CGFloat columnHeight = MIN(avg * self.settings.gain, self.settings.maxBinHeight);
            
            maxHeight = MAX(maxHeight, columnHeight);
            // set column height, speed and time if needed
            if (columnHeight > _heightsByFrequency[i]) {
                _heightsByFrequency[i] = columnHeight;
                _speeds[i] = 0;
                _times[i] = 0;
            }
        }
        
        [self.heightsByTime addObject:@(maxHeight)];
        
        if (self.heightsByTime.count > _numOfBins) {
            [self.heightsByTime removeObjectAtIndex:0];
        }
    }
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    [self setSampleData:buffer length:bufferSize];
}


- (void)freeBuffersIfNeeded {
    if (_heightsByFrequency) {
        free(_heightsByFrequency);
    }
    if (_speeds) {
        free(_speeds);
    }
    if (_times) {
        free(_times);
    }
    if (_tSqrts) {
        free(_tSqrts);
    }
    if (_vts) {
        free(_vts);
    }
    if (_deltaHeights) {
        free(_deltaHeights);
    }
}

- (void)p_refreshEqualizerDisplay {
    if ([self.delegate respondsToSelector:@selector(refreshEqualizerDisplay)]) {
        [self.delegate refreshEqualizerDisplay];
    }
}

@end
