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
/// Table view populated with valid playlist endpoints.
/// Search results are displayed at the top of this table depending on @c shouldShowSearchResults
@property (strong, nonatomic) IBOutlet UITableView *playlistTableView;
/// Search bar, dynamicly set. Should be in the first cell of @c playlistTableView
@property (weak, nonatomic) UISearchBar *cellSearchBar;

/// Whether search results should be displayed in the @c playlistTableView
/// and determines direction of the search bar arrow indicator
@property (nonatomic) BOOL shouldShowSearchResults;
/// Whether incoming music data should be processed, and visualizing views should be updated
@property (nonatomic) BOOL shouldUpdateVisualizer;

@end
