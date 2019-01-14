//
//  LMProcessedMusicDataStruct.h
//  music
//
//  Created by Leptos on 1/7/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#ifndef LMProcessedMusicDataStruct_h
#define LMProcessedMusicDataStruct_h

struct LMProcessedMusicData {
    float rmesq; // root-mean-square
    
    float meamg; // mean magnitude
    float measq; // mean square
    
    float maxvl; // maximum value
    float maxmg; // maximum magnitude
    
    float minvl; // minimum value
    float minmg; // minimum magnitude
};

#endif /* LMProcessedMusicDataStruct_h */
