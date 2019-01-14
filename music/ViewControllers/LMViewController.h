//
//  LMViewController.h
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import UIKit;
@import MediaPlayer;
@import Metal;
@import MetalKit;

#import "../../DisPlayers-Audio-Visualizers/DisPlayersAudioVisualizers.h"
#import "../Views/LMVideoPlayerView.h"

@interface LMViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MTKViewDelegate>
/// A volume view being in the view hierarchy will prevent the system volume HUD from appearing
@property (strong, nonatomic) IBOutlet MPVolumeView *volumeView;
/// View which holds each of the audio visualizing views
@property (strong, nonatomic) IBOutlet UIView *visualizeHoldingView;
/// View used for @c LMPreferencesVisualizerTypeVideo
@property (strong, nonatomic) IBOutlet LMVideoPlayerView *playerView;
/// View used for @c LMPreferencesVisualizerTypeHistogram
@property (strong, nonatomic) IBOutlet DPMainEqualizerView *equalizerView;
/// View used for @c LMPreferencesVisualizerTypeMetal
@property (strong, nonatomic) IBOutlet MTKView *metalView;

@property (strong, nonatomic) IBOutlet UITableView *playlistTableView;

@property (weak, nonatomic) UISearchBar *cellSearchBar;

@property (nonatomic) BOOL shouldShowSearchResults;
@property (nonatomic) BOOL shouldUpdateVisualizer;

@end
