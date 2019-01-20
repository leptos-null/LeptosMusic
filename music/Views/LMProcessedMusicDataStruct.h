//
//  LMProcessedMusicDataStruct.h
//  music
//
//  Created by Leptos on 1/7/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#ifndef LMProcessedMusicDataStruct_h
#define LMProcessedMusicDataStruct_h

/// Calculated values from an audio frame buffer
struct LMProcessedMusicData {
    /// root-mean-square
    float rmesq;
    
    /// mean magnitude
    float meamg;
    /// mean square
    float measq;
    
    /// maximum value
    float maxvl;
    /// maximum magnitude
    float maxmg;
    
    /// minimum value
    float minvl;
    /// minimum magnitude
    float minmg;
};

#endif /* LMProcessedMusicDataStruct_h */
