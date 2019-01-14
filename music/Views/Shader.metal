//
//  Shader.metal
//  music
//
//  Created by Leptos on 1/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#include <metal_stdlib>
#include "LMProcessedMusicDataStruct.h"

using namespace metal;

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    constant LMProcessedMusicData &music_data [[buffer(1)]],
                    uint2 position [[thread_position_in_grid]])
{
    float width = output.get_width();
    float height = output.get_height();
    
    float2 uv = float2(position) / float2(width, height);
    uv *= 2; // this takes us from a [0, 1] map to a [0, 2]
    uv -= 1; // this tales us from a [0, 2] map to a [-1, 1]
    
    if (width > height) {
        uv.x *= (width/height);
    }
    if (height > width) {
        uv.y *= (height/width);
    }
    uv.y *= powr(1 + music_data.meamg, 2); // mean magnitude is usually less then 0.1
    
    float offset = fast::saturate(music_data.rmesq);
    /*
     * Arthur Guibert (at Deezer) uses this as the last argument:
     *     dot(uv, uv) * 4.0
     * which evalutes to:
     *     (uv.x*uv.x + uv.y*uv.y) * 4
     *
     * Marius Horga (author of Metal By Tutorials) uses this as the last argument:
     *     length(uv)
     * which evalutes to:
     *     sqrt(uv.x*uv.x + uv.y*uv.y)
     */
    float smoothed = smoothstep(offset - (offset * 0.01), offset + (offset * 0.01), length(uv));
    
    float4 backgroundColor = float4(0);
    float4 circleColor = float4(fast::saturate(music_data.measq), fast::saturate(music_data.maxvl), fast::saturate(music_data.maxmg), 1.0f);
    float4 endColor = mix(circleColor, backgroundColor, smoothed);
    output.write(endColor, position);
}
